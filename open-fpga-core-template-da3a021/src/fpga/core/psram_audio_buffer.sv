// psram_audio_buffer.sv
//
// PSRAM (cram0)-backed audio buffer for PocketPlayer's "Module 2b" one-shot
// longer clip. Replaces audio_ram.sv's on-chip BRAM array with the cellular
// PSRAM (8MB = 2^22 sixteen-bit words = 2^21 stereo frames @ 48kHz/16-bit
// ~= 43.69s), while keeping the SAME external read/write interface as
// audio_ram.sv (wr_clk/bridge_wr/bridge_addr/bridge_wr_data for the one-shot
// SD-card load, rd_clk/rd_addr/rd_data for I2S playback) plus clk_psram_133
// and two status outputs, psram_test_done/psram_test_pass.
//
// PSRAM WORD ADDRESSING: each stereo frame occupies 2 sixteen-bit PSRAM
// words - the left sample at word address 2*frame_idx, the right sample at
// 2*frame_idx+1. This is a clean fit: 2^21 frames * 2 words/frame = 2^22
// words = all of cram0, no remainder.
//
// BYTE ORDER (same convention as audio_ram.sv, confirmed on hardware):
// tools/convert_audio.py writes raw interleaved PCM s16le stereo bytes
// [L_lo, L_hi, R_lo, R_hi] per frame. The host's bridge_wr_data arrives with
// the opposite byte order, so the write side byte-reverses it before
// storing - after which rd_data[15:0] = left sample, rd_data[31:16] = right
// sample.
//
// THREE PHASES, temporally disjoint by construction (so a single psram
// instance can be time-shared with no real arbiter):
//
//   Phase A - self-test (clk_psram_133, runs once at boot before anything
//   else touches PSRAM): write+read-back 4 address/data vectors spanning
//   the 22-bit address range. Sets psram_test_done=1 and psram_test_pass
//   (1 if all vectors matched). Takes ~10 PSRAM transactions (~1us@133MHz),
//   long before the SD-card dataslot load begins.
//
//   Phase B - load (write side, clk_74a/bridge domain -> clk_psram_133):
//   bridge writes for [BASE_ADDR, BASE_ADDR+NUM_SAMPLES*4) are
//   byte-reversed exactly as audio_ram.sv does, latched, and handed to the
//   clk_psram_133-domain FSM via a toggle-based request pulse (synch_3).
//   Each request triggers 2 sequential 16-bit psram writes. No FIFO: PSRAM
//   write throughput (~12 cycles/16-bit word @133MHz) is orders of
//   magnitude faster than dataslot loads arrive via the SPI bridge, so the
//   single-buffer latch is never overrun in practice.
//
//   Phase C - playback (read side, audgen_sclk <-> clk_psram_133, active
//   once audio_addr starts advancing, i.e. after audio_loaded): rd_addr
//   changes are detected and turned into a toggle-based request pulse
//   (synch_3) into clk_psram_133, which issues 2 sequential 16-bit reads
//   and returns the assembled 32-bit frame via a toggle-based ack pulse
//   back into rd_clk. Budget: rd_addr only changes once per 32 rd_clk
//   cycles (~10us), vs. ~200ns for the round trip - large margin.
//
// Phase A is gated on `reset`; Phase B/C are gated on psram_test_done so
// they never contend with Phase A for the shared psram bus. Phase B and C
// are arbitrated: Phase B waits for Phase C to reach PC_IDLE before starting
// each write (wr_req_pending latches any pulse that arrives while C is busy);
// Phase C waits for !loadB_active before issuing each PSRAM read command.
// Together these ensure atomic, non-interleaved PSRAM transactions.
// (In Module 2b, Phase B was one-shot and finished before audio_loaded; in
// Module 2c ring-buffer mode Phase B runs continuously during playback, so
// the arbitration is required to prevent Phase C from stalling forever.)

module psram_audio_buffer #(
    parameter int          NUM_SAMPLES = 2097152,  // 2^21 stereo frames (8MB / 4 bytes)
    parameter logic [31:0] BASE_ADDR   = 32'h2000_0000
) (
    input  logic clk_psram_133,
    input  logic reset,

    // ---------------- write side (clk_74a / bridge) ----------------
    input  logic        wr_clk,
    input  logic        bridge_wr,
    input  logic [31:0] bridge_addr,
    input  logic [31:0] bridge_wr_data,

    // ---------------- read side ----------------
    input  logic                           rd_clk,
    input  logic [$clog2(NUM_SAMPLES)-1:0] rd_addr,
    output logic [31:0]                    rd_data,

    // ---------------- status ----------------
    output logic psram_test_done,
    output logic psram_test_pass,

    // ---------------- PSRAM (cram0) pins ----------------
    output logic [21:16] cram0_a,
    inout  wire  [15:0]  cram0_dq,
    input  logic         cram0_wait,
    output logic         cram0_clk,
    output logic         cram0_adv_n,
    output logic         cram0_cre,
    output logic         cram0_ce0_n,
    output logic         cram0_ce1_n,
    output logic         cram0_oe_n,
    output logic         cram0_we_n,
    output logic         cram0_ub_n,
    output logic         cram0_lb_n
);

  localparam int          AW        = $clog2(NUM_SAMPLES);  // 21
  localparam logic [31:0] NUM_BYTES = NUM_SAMPLES * 4;       // 0x800000

  // ================================================================
  // Shared PSRAM instance (cram0), time-shared by phases A/B/C below
  // ================================================================
  wire        psram_busy;
  wire        psram_read_avail;
  wire [15:0] psram_data_out;
  wire        psram_write_en;
  wire        psram_read_en;
  wire [21:0] psram_addr;
  wire [15:0] psram_data_in;

  psram psram0 (
      .clk             ( clk_psram_133 ),
      .bank_sel        ( 1'b0 ),
      .addr            ( psram_addr ),
      .write_en        ( psram_write_en ),
      .data_in         ( psram_data_in ),
      .write_high_byte ( 1'b1 ),
      .write_low_byte  ( 1'b1 ),
      .read_en         ( psram_read_en ),
      .read_avail      ( psram_read_avail ),
      .data_out        ( psram_data_out ),
      .busy            ( psram_busy ),
      .cram_a          ( cram0_a ),
      .cram_dq         ( cram0_dq ),
      .cram_wait       ( cram0_wait ),
      .cram_clk        ( cram0_clk ),
      .cram_adv_n      ( cram0_adv_n ),
      .cram_cre        ( cram0_cre ),
      .cram_ce0_n      ( cram0_ce0_n ),
      .cram_ce1_n      ( cram0_ce1_n ),
      .cram_oe_n       ( cram0_oe_n ),
      .cram_we_n       ( cram0_we_n ),
      .cram_ub_n       ( cram0_ub_n ),
      .cram_lb_n       ( cram0_lb_n )
  );

  // ================================================================
  // Phase A: PSRAM self-test (runs once at boot)
  // ================================================================
  function automatic [21:0] psram_test_addr(input [1:0] i);
    case (i)
      2'd0: psram_test_addr = 22'h000000;
      2'd1: psram_test_addr = 22'h00000F;
      2'd2: psram_test_addr = 22'h3FFFFF;
      default: psram_test_addr = 22'h155555;
    endcase
  endfunction

  function automatic [15:0] psram_test_data(input [1:0] i);
    case (i)
      2'd0: psram_test_data = 16'hAAAA;
      2'd1: psram_test_data = 16'h5555;
      2'd2: psram_test_data = 16'hF0F0;
      default: psram_test_data = 16'h0F0F;
    endcase
  endfunction

  localparam [2:0] PT_WRITE_ISSUE  = 3'd0;
  localparam [2:0] PT_WRITE_LAUNCH = 3'd1;
  localparam [2:0] PT_WRITE_POLL   = 3'd2;
  localparam [2:0] PT_READ_ISSUE   = 3'd3;
  localparam [2:0] PT_READ_LAUNCH  = 3'd4;
  localparam [2:0] PT_READ_POLL    = 3'd5;
  localparam [2:0] PT_DONE         = 3'd6;

  reg [2:0]  testA_state;
  reg [1:0]  testA_idx;
  reg        testA_write_en;
  reg        testA_read_en;
  reg [21:0] testA_addr;
  reg [15:0] testA_data_in;

  wire testA_active = !psram_test_done;

  always @(posedge clk_psram_133 or posedge reset) begin
    if (reset) begin
      testA_state     <= PT_WRITE_ISSUE;
      testA_idx       <= 2'd0;
      psram_test_pass <= 1'b1;
      psram_test_done <= 1'b0;
      testA_write_en  <= 1'b0;
      testA_read_en   <= 1'b0;
    end else begin
      testA_write_en <= 1'b0;
      testA_read_en  <= 1'b0;

      case (testA_state)
        PT_WRITE_ISSUE: begin
          testA_addr     <= psram_test_addr(testA_idx);
          testA_data_in  <= psram_test_data(testA_idx);
          testA_write_en <= 1'b1;
          testA_state    <= PT_WRITE_LAUNCH;
        end
        PT_WRITE_LAUNCH: testA_state <= PT_WRITE_POLL;
        PT_WRITE_POLL: begin
          if (!psram_busy) begin
            if (testA_idx == 2'd3) begin
              testA_idx   <= 2'd0;
              testA_state <= PT_READ_ISSUE;
            end else begin
              testA_idx   <= testA_idx + 2'd1;
              testA_state <= PT_WRITE_ISSUE;
            end
          end
        end
        PT_READ_ISSUE: begin
          testA_addr    <= psram_test_addr(testA_idx);
          testA_read_en <= 1'b1;
          testA_state   <= PT_READ_LAUNCH;
        end
        PT_READ_LAUNCH: testA_state <= PT_READ_POLL;
        PT_READ_POLL: begin
          if (psram_read_avail) begin
            if (psram_data_out != psram_test_data(testA_idx))
              psram_test_pass <= 1'b0;
            if (testA_idx == 2'd3) begin
              testA_state <= PT_DONE;
            end else begin
              testA_idx   <= testA_idx + 2'd1;
              testA_state <= PT_READ_ISSUE;
            end
          end
        end
        PT_DONE: psram_test_done <= 1'b1;
        default: testA_state <= PT_WRITE_ISSUE;
      endcase
    end
  end

  // ================================================================
  // Phase B: one-shot load (write side)
  // ================================================================

  // -- clk_74a / bridge domain: latch in-range writes, toggle a request --
  wire bridge_in_range = (bridge_addr >= BASE_ADDR) &&
                         (bridge_addr < BASE_ADDR + NUM_BYTES);
  wire [AW-1:0] bridge_frame_idx = (bridge_addr - BASE_ADDR) >> 2;

  reg          wr_req_tog;
  reg          wr_req_pending; // latches a pulse that arrived when Phase B couldn't start yet
  reg [31:0]   wr_data_latched;
  reg [AW-1:0] wr_addr_latched;

  always @(posedge wr_clk) begin
    if (bridge_wr && bridge_in_range) begin
      wr_data_latched <= {bridge_wr_data[7:0], bridge_wr_data[15:8],
                           bridge_wr_data[23:16], bridge_wr_data[31:24]};
      wr_addr_latched <= bridge_frame_idx;
      wr_req_tog      <= ~wr_req_tog;
    end
  end

  // -- clk_psram_133 domain: synchronize request toggle --
  wire wr_req_tog_s, wr_req_rise, wr_req_fall;
  synch_3 sync_wr_req (wr_req_tog, wr_req_tog_s, clk_psram_133, wr_req_rise, wr_req_fall);
  wire wr_req_pulse = wr_req_rise | wr_req_fall;

  localparam [2:0] LB_IDLE      = 3'd0;
  localparam [2:0] LB_W0_ISSUE  = 3'd1;
  localparam [2:0] LB_W0_LAUNCH = 3'd2;
  localparam [2:0] LB_W0_POLL   = 3'd3;
  localparam [2:0] LB_W1_ISSUE  = 3'd4;
  localparam [2:0] LB_W1_LAUNCH = 3'd5;
  localparam [2:0] LB_W1_POLL   = 3'd6;
  localparam [2:0] LB_ACK       = 3'd7;

  reg [2:0]    loadB_state;
  reg [31:0]   loadB_data_q;
  reg [AW-1:0] loadB_addr_q;
  reg          loadB_write_en;
  reg [21:0]   loadB_addr;
  reg [15:0]   loadB_data_in;

  wire loadB_active = (loadB_state != LB_IDLE);

  always @(posedge clk_psram_133 or posedge reset) begin
    if (reset) begin
      loadB_state    <= LB_IDLE;
      loadB_write_en <= 1'b0;
      wr_req_pending <= 1'b0;
    end else begin
      loadB_write_en <= 1'b0;
      // Latch any pulse that arrives while Phase B cannot start yet.
      // The inner wr_req_pending <= 1'b0 in LB_IDLE wins when Phase B
      // actually starts (last NB assignment in code order takes effect).
      if (wr_req_pulse) wr_req_pending <= 1'b1;

      case (loadB_state)
        LB_IDLE: begin
          // Wait for Phase C to be in PC_IDLE before starting a write,
          // so Phase B never takes the PSRAM bus mid-read (which would
          // stall Phase C's psram_read_avail wait forever).
          if (psram_test_done && (wr_req_pulse || wr_req_pending) && (playC_state == PC_IDLE)) begin
            loadB_data_q   <= wr_data_latched;
            loadB_addr_q   <= wr_addr_latched;
            loadB_state    <= LB_W0_ISSUE;
            wr_req_pending <= 1'b0; // clear; wins over the set above (later NB)
          end
        end
        LB_W0_ISSUE: begin
          // left sample -> word address 2*frame_idx
          loadB_addr     <= {loadB_addr_q, 1'b0};
          loadB_data_in  <= loadB_data_q[15:0];
          loadB_write_en <= 1'b1;
          loadB_state    <= LB_W0_LAUNCH;
        end
        LB_W0_LAUNCH: loadB_state <= LB_W0_POLL;
        LB_W0_POLL: if (!psram_busy) loadB_state <= LB_W1_ISSUE;
        LB_W1_ISSUE: begin
          // right sample -> word address 2*frame_idx + 1
          loadB_addr     <= {loadB_addr_q, 1'b1};
          loadB_data_in  <= loadB_data_q[31:16];
          loadB_write_en <= 1'b1;
          loadB_state    <= LB_W1_LAUNCH;
        end
        LB_W1_LAUNCH: loadB_state <= LB_W1_POLL;
        LB_W1_POLL: if (!psram_busy) loadB_state <= LB_ACK;
        LB_ACK: loadB_state <= LB_IDLE;
        default: loadB_state <= LB_IDLE;
      endcase
    end
  end

  // ================================================================
  // Phase C: playback (read side)
  // ================================================================

  // -- rd_clk (audgen_sclk) domain: detect rd_addr changes, toggle a request --
  reg [AW-1:0] rd_addr_prev;
  reg          rd_req_tog;
  reg [31:0]   rd_data_q;

  always @(posedge rd_clk) begin
    if (rd_addr != rd_addr_prev) begin
      rd_addr_prev <= rd_addr;
      rd_req_tog   <= ~rd_req_tog;
    end
  end

  // -- clk_psram_133 domain: synchronize request toggle + rd_addr bus --
  wire rd_req_tog_s, rd_req_rise, rd_req_fall;
  synch_3 sync_rd_req (rd_req_tog, rd_req_tog_s, clk_psram_133, rd_req_rise, rd_req_fall);
  wire rd_req_pulse = rd_req_rise | rd_req_fall;

  reg [AW-1:0] rd_addr_q1, rd_addr_q2;
  always @(posedge clk_psram_133) begin
    rd_addr_q1 <= rd_addr;
    rd_addr_q2 <= rd_addr_q1;
  end

  localparam [2:0] PC_IDLE      = 3'd0;
  localparam [2:0] PC_R0_ISSUE  = 3'd1;
  localparam [2:0] PC_R0_LAUNCH = 3'd2;
  localparam [2:0] PC_R0_POLL   = 3'd3;
  localparam [2:0] PC_R1_ISSUE  = 3'd4;
  localparam [2:0] PC_R1_LAUNCH = 3'd5;
  localparam [2:0] PC_R1_POLL   = 3'd6;
  localparam [2:0] PC_ACK       = 3'd7;

  reg [2:0]    playC_state;
  reg          playC_read_en;
  reg [21:0]   playC_addr;
  reg [AW-1:0] playC_addr_q;
  reg [15:0]   playC_left;
  reg [31:0]   rd_data_result;
  reg          rd_ack_tog;

  always @(posedge clk_psram_133 or posedge reset) begin
    if (reset) begin
      playC_state   <= PC_IDLE;
      playC_read_en <= 1'b0;
      rd_ack_tog    <= 1'b0;
    end else begin
      playC_read_en <= 1'b0;

      case (playC_state)
        PC_IDLE: begin
          if (psram_test_done && rd_req_pulse) begin
            playC_addr_q <= rd_addr_q2;
            playC_state  <= PC_R0_ISSUE;
          end
        end
        PC_R0_ISSUE: begin
          // Wait for Phase B to be idle before issuing, so Phase B can
          // never win the mux and silently drop our psram_read_en pulse.
          if (!loadB_active) begin
            // left sample <- word address 2*frame_idx
            playC_addr    <= {playC_addr_q, 1'b0};
            playC_read_en <= 1'b1;
            playC_state   <= PC_R0_LAUNCH;
          end
        end
        PC_R0_LAUNCH: playC_state <= PC_R0_POLL;
        PC_R0_POLL: begin
          if (psram_read_avail) begin
            playC_left  <= psram_data_out;
            playC_state <= PC_R1_ISSUE;
          end
        end
        PC_R1_ISSUE: begin
          if (!loadB_active) begin
            // right sample <- word address 2*frame_idx + 1
            playC_addr    <= {playC_addr_q, 1'b1};
            playC_read_en <= 1'b1;
            playC_state   <= PC_R1_LAUNCH;
          end
        end
        PC_R1_LAUNCH: playC_state <= PC_R1_POLL;
        PC_R1_POLL: begin
          if (psram_read_avail) begin
            rd_data_result <= {psram_data_out, playC_left};
            playC_state    <= PC_ACK;
          end
        end
        PC_ACK: begin
          rd_ack_tog  <= ~rd_ack_tog;
          playC_state <= PC_IDLE;
        end
        default: playC_state <= PC_IDLE;
      endcase
    end
  end

  // -- rd_clk domain: synchronize ack toggle, latch assembled frame --
  wire rd_ack_tog_s, rd_ack_rise, rd_ack_fall;
  synch_3 sync_rd_ack (rd_ack_tog, rd_ack_tog_s, rd_clk, rd_ack_rise, rd_ack_fall);
  wire rd_ack_pulse = rd_ack_rise | rd_ack_fall;

  always @(posedge rd_clk) begin
    if (rd_ack_pulse) rd_data_q <= rd_data_result;
  end

  assign rd_data = rd_data_q;

  // ================================================================
  // PSRAM bus mux - phases A/B/C are temporally disjoint (see header)
  // ================================================================
  assign psram_write_en = testA_active ? testA_write_en :
                           (loadB_active ? loadB_write_en : 1'b0);
  assign psram_read_en  = testA_active ? testA_read_en :
                           (loadB_active ? 1'b0 : playC_read_en);
  assign psram_addr     = testA_active ? testA_addr :
                           (loadB_active ? loadB_addr : playC_addr);
  assign psram_data_in  = testA_active ? testA_data_in : loadB_data_in;

endmodule
