// audio_loader.sv
//
// One-shot data-slot loader for the "audio hello world" module (2a). After
// reset, requests the test-audio data slot (id AUDIO_SLOT_ID, see data.json
// "Test Audio" / test_audio.bin) to be streamed into audio_ram via the
// bridge, then asserts `loaded` once and stays done forever.
//
// Mirrors image_controller.sv's confirmed "request slot" pattern:
// - target_dataslot_read is rising-edge triggered: pulse for one clk cycle.
// - target_dataslot_done is a level signal that core_bridge_cmd.v clears to
//   0 a few cycles after accepting the request, then sets back to 1 once
//   the host finishes streaming the file. WAIT_CLEAR -> WAIT_DONE ensures a
//   stale "done" from before reset can't be mistaken for completion.

module audio_loader #(
    parameter logic [15:0] AUDIO_SLOT_ID     = 16'd16,
    parameter logic [31:0] AUDIO_BRIDGE_ADDR = 32'h2000_0000,
    parameter logic [31:0] AUDIO_BYTES       = 32'd192000
) (
    input  logic clk,
    input  logic reset,

    output logic        target_dataslot_read,
    output logic [15:0] target_dataslot_id,
    output logic [31:0] target_dataslot_slotoffset,
    output logic [31:0] target_dataslot_bridgeaddr,
    output logic [31:0] target_dataslot_length,
    input  logic        target_dataslot_done,

    output logic loaded
);

  typedef enum logic [1:0] {
    REQ,
    WAIT_CLEAR,
    WAIT_DONE,
    DONE
  } state_t;
  state_t state;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state                      <= REQ;
      target_dataslot_read       <= 1'b0;
      target_dataslot_id         <= AUDIO_SLOT_ID;
      target_dataslot_slotoffset <= 32'h0;
      target_dataslot_bridgeaddr <= AUDIO_BRIDGE_ADDR;
      target_dataslot_length     <= AUDIO_BYTES;
      loaded                     <= 1'b0;
    end else begin
      target_dataslot_read <= 1'b0; // single-cycle pulse

      case (state)
        REQ: begin
          target_dataslot_read <= 1'b1;
          state                <= WAIT_CLEAR;
        end

        WAIT_CLEAR: begin
          if (!target_dataslot_done)
            state <= WAIT_DONE;
        end

        WAIT_DONE: begin
          if (target_dataslot_done) begin
            loaded <= 1'b1;
            state  <= DONE;
          end
        end

        DONE: begin
          // one-shot: stay here forever
        end

        default: state <= DONE;
      endcase
    end
  end

endmodule
