//
// User core top-level
//
// Instantiated by the real top-level: apf_top
//

`default_nettype none

module core_top (

//
// physical connections
//

///////////////////////////////////////////////////
// clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

input   wire            clk_74a, // mainclk1
input   wire            clk_74b, // mainclk1 

///////////////////////////////////////////////////
// cartridge interface
// switches between 3.3v and 5v mechanically
// output enable for multibit translators controlled by pic32

// GBA AD[15:8]
inout   wire    [7:0]   cart_tran_bank2,
output  wire            cart_tran_bank2_dir,

// GBA AD[7:0]
inout   wire    [7:0]   cart_tran_bank3,
output  wire            cart_tran_bank3_dir,

// GBA A[23:16]
inout   wire    [7:0]   cart_tran_bank1,
output  wire            cart_tran_bank1_dir,

// GBA [7] PHI#
// GBA [6] WR#
// GBA [5] RD#
// GBA [4] CS1#/CS#
//     [3:0] unwired
inout   wire    [7:4]   cart_tran_bank0,
output  wire            cart_tran_bank0_dir,

// GBA CS2#/RES#
inout   wire            cart_tran_pin30,
output  wire            cart_tran_pin30_dir,
// when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
// the goal is that when unconfigured, the FPGA weak pullups won't interfere.
// thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
// and general IO drive this pin.
output  wire            cart_pin30_pwroff_reset,

// GBA IRQ/DRQ
inout   wire            cart_tran_pin31,
output  wire            cart_tran_pin31_dir,

// infrared
input   wire            port_ir_rx,
output  wire            port_ir_tx,
output  wire            port_ir_rx_disable, 

// GBA link port
inout   wire            port_tran_si,
output  wire            port_tran_si_dir,
inout   wire            port_tran_so,
output  wire            port_tran_so_dir,
inout   wire            port_tran_sck,
output  wire            port_tran_sck_dir,
inout   wire            port_tran_sd,
output  wire            port_tran_sd_dir,
 
///////////////////////////////////////////////////
// cellular psram 0 and 1, two chips (64mbit x2 dual die per chip)

output  wire    [21:16] cram0_a,
inout   wire    [15:0]  cram0_dq,
input   wire            cram0_wait,
output  wire            cram0_clk,
output  wire            cram0_adv_n,
output  wire            cram0_cre,
output  wire            cram0_ce0_n,
output  wire            cram0_ce1_n,
output  wire            cram0_oe_n,
output  wire            cram0_we_n,
output  wire            cram0_ub_n,
output  wire            cram0_lb_n,

output  wire    [21:16] cram1_a,
inout   wire    [15:0]  cram1_dq,
input   wire            cram1_wait,
output  wire            cram1_clk,
output  wire            cram1_adv_n,
output  wire            cram1_cre,
output  wire            cram1_ce0_n,
output  wire            cram1_ce1_n,
output  wire            cram1_oe_n,
output  wire            cram1_we_n,
output  wire            cram1_ub_n,
output  wire            cram1_lb_n,

///////////////////////////////////////////////////
// sdram, 512mbit 16bit

output  wire    [12:0]  dram_a,
output  wire    [1:0]   dram_ba,
inout   wire    [15:0]  dram_dq,
output  wire    [1:0]   dram_dqm,
output  wire            dram_clk,
output  wire            dram_cke,
output  wire            dram_ras_n,
output  wire            dram_cas_n,
output  wire            dram_we_n,

///////////////////////////////////////////////////
// sram, 1mbit 16bit

output  wire    [16:0]  sram_a,
inout   wire    [15:0]  sram_dq,
output  wire            sram_oe_n,
output  wire            sram_we_n,
output  wire            sram_ub_n,
output  wire            sram_lb_n,

///////////////////////////////////////////////////
// vblank driven by dock for sync in a certain mode

input   wire            vblank,

///////////////////////////////////////////////////
// i/o to 6515D breakout usb uart

output  wire            dbg_tx,
input   wire            dbg_rx,

///////////////////////////////////////////////////
// i/o pads near jtag connector user can solder to

output  wire            user1,
input   wire            user2,

///////////////////////////////////////////////////
// RFU internal i2c bus 

inout   wire            aux_sda,
output  wire            aux_scl,

///////////////////////////////////////////////////
// RFU, do not use
output  wire            vpll_feed,


//
// logical connections
//

///////////////////////////////////////////////////
// video, audio output to scaler
output  wire    [23:0]  video_rgb,
output  wire            video_rgb_clock,
output  wire            video_rgb_clock_90,
output  wire            video_de,
output  wire            video_skip,
output  wire            video_vs,
output  wire            video_hs,
    
output  wire            audio_mclk,
input   wire            audio_adc,
output  wire            audio_dac,
output  wire            audio_lrck,

///////////////////////////////////////////////////
// bridge bus connection
// synchronous to clk_74a
output  wire            bridge_endian_little,
input   wire    [31:0]  bridge_addr,
input   wire            bridge_rd,
output  reg     [31:0]  bridge_rd_data,
input   wire            bridge_wr,
input   wire    [31:0]  bridge_wr_data,

///////////////////////////////////////////////////
// controller data
// 
// key bitmap:
//   [0]    dpad_up
//   [1]    dpad_down
//   [2]    dpad_left
//   [3]    dpad_right
//   [4]    face_a
//   [5]    face_b
//   [6]    face_x
//   [7]    face_y
//   [8]    trig_l1
//   [9]    trig_r1
//   [10]   trig_l2
//   [11]   trig_r2
//   [12]   trig_l3
//   [13]   trig_r3
//   [14]   face_select
//   [15]   face_start
//   [31:28] type
// joy values - unsigned
//   [ 7: 0] lstick_x
//   [15: 8] lstick_y
//   [23:16] rstick_x
//   [31:24] rstick_y
// trigger values - unsigned
//   [ 7: 0] ltrig
//   [15: 8] rtrig
//
input   wire    [31:0]  cont1_key,
input   wire    [31:0]  cont2_key,
input   wire    [31:0]  cont3_key,
input   wire    [31:0]  cont4_key,
input   wire    [31:0]  cont1_joy,
input   wire    [31:0]  cont2_joy,
input   wire    [31:0]  cont3_joy,
input   wire    [31:0]  cont4_joy,
input   wire    [15:0]  cont1_trig,
input   wire    [15:0]  cont2_trig,
input   wire    [15:0]  cont3_trig,
input   wire    [15:0]  cont4_trig
    
);

// not using the IR port, so turn off both the LED, and
// disable the receive circuit to save power
assign port_ir_tx = 0;
assign port_ir_rx_disable = 1;

// bridge endianness
assign bridge_endian_little = 0;

// cart is unused, so set all level translators accordingly
// directions are 0:IN, 1:OUT
assign cart_tran_bank3 = 8'hzz;
assign cart_tran_bank3_dir = 1'b0;
assign cart_tran_bank2 = 8'hzz;
assign cart_tran_bank2_dir = 1'b0;
assign cart_tran_bank1 = 8'hzz;
assign cart_tran_bank1_dir = 1'b0;
assign cart_tran_bank0 = 4'hf;
assign cart_tran_bank0_dir = 1'b1;
assign cart_tran_pin30 = 1'b0;      // reset or cs2, we let the hw control it by itself
assign cart_tran_pin30_dir = 1'bz;
assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
assign cart_tran_pin31 = 1'bz;      // input
assign cart_tran_pin31_dir = 1'b0;  // input

// link port is unused, set to input only to be safe
// each bit may be bidirectional in some applications
assign port_tran_so = 1'bz;
assign port_tran_so_dir = 1'b0;     // SO is output only
assign port_tran_si = 1'bz;
assign port_tran_si_dir = 1'b0;     // SI is input only
assign port_tran_sck = 1'bz;
assign port_tran_sck_dir = 1'b0;    // clock direction can change
assign port_tran_sd = 1'bz;
assign port_tran_sd_dir = 1'b0;     // SD is input and not used

// tie off the rest of the pins we are not using
// cram0_* driven by psram_audio_buffer (Module 2b audio buffer)

assign cram1_a = 'h0;
assign cram1_dq = {16{1'bZ}};
assign cram1_clk = 0;
assign cram1_adv_n = 1;
assign cram1_cre = 0;
assign cram1_ce0_n = 1;
assign cram1_ce1_n = 1;
assign cram1_oe_n = 1;
assign cram1_we_n = 1;
assign cram1_ub_n = 1;
assign cram1_lb_n = 1;

assign dram_a = 'h0;
assign dram_ba = 'h0;
assign dram_dq = {16{1'bZ}};
assign dram_dqm = 'h0;
assign dram_clk = 'h0;
assign dram_cke = 'h0;
assign dram_ras_n = 'h1;
assign dram_cas_n = 'h1;
assign dram_we_n = 'h1;

assign sram_a = 'h0;
assign sram_dq = {16{1'bZ}};
assign sram_oe_n  = 1;
assign sram_we_n  = 1;
assign sram_ub_n  = 1;
assign sram_lb_n  = 1;

assign dbg_tx = 1'bZ;
assign user1 = 1'bZ;
assign aux_scl = 1'bZ;
assign vpll_feed = 1'bZ;


// for bridge write data, we just broadcast it to all bus devices
// for bridge read data, we have to mux it
// add your own devices here
always @(*) begin
    casex(bridge_addr)
    default: begin
        bridge_rd_data <= 0;
    end
    32'h10xxxxxx: begin
        // example
        // bridge_rd_data <= example_device_data;
        bridge_rd_data <= 0;
    end
    32'hF8xxxxxx: begin
        bridge_rd_data <= cmd_bridge_rd_data;
    end
    endcase
end


//
// host/target command handler
//
    wire            reset_n;                // driven by host commands, can be used as core-wide reset
    wire            reset = ~reset_n;
    wire    [31:0]  cmd_bridge_rd_data;
    
// bridge host commands
// synchronous to clk_74a
    wire            status_boot_done = pll_core_locked_s; 
    wire            status_setup_done = pll_core_locked_s; // rising edge triggers a target command
    wire            status_running = reset_n; // we are running as soon as reset_n goes high

    wire            dataslot_requestread;
    wire    [15:0]  dataslot_requestread_id;
    wire            dataslot_requestread_ack = 1;
    wire            dataslot_requestread_ok = 1;

    wire            dataslot_requestwrite;
    wire    [15:0]  dataslot_requestwrite_id;
    wire    [31:0]  dataslot_requestwrite_size;
    wire            dataslot_requestwrite_ack = 1;
    wire            dataslot_requestwrite_ok = 1;

    wire            dataslot_update;
    wire    [15:0]  dataslot_update_id;
    wire    [31:0]  dataslot_update_size;
    
    wire            dataslot_allcomplete;

    wire     [31:0] rtc_epoch_seconds;
    wire     [31:0] rtc_date_bcd;
    wire     [31:0] rtc_time_bcd;
    wire            rtc_valid;

    wire            savestate_supported;
    wire    [31:0]  savestate_addr;
    wire    [31:0]  savestate_size;
    wire    [31:0]  savestate_maxloadsize;

    wire            savestate_start;
    wire            savestate_start_ack;
    wire            savestate_start_busy;
    wire            savestate_start_ok;
    wire            savestate_start_err;

    wire            savestate_load;
    wire            savestate_load_ack;
    wire            savestate_load_busy;
    wire            savestate_load_ok;
    wire            savestate_load_err;
    
    wire            osnotify_inmenu;

// bridge target commands
// synchronous to clk_74a

    wire            target_dataslot_read;
    wire            target_dataslot_write    = 0;
    wire            target_dataslot_getfile  = 0; // require additional param/resp structs to be mapped
    wire            target_dataslot_openfile = 0; // require additional param/resp structs to be mapped

    wire            target_dataslot_ack;
    wire            target_dataslot_done;
    wire    [2:0]   target_dataslot_err;

    wire    [15:0]  target_dataslot_id;
    wire    [31:0]  target_dataslot_slotoffset;
    wire    [31:0]  target_dataslot_bridgeaddr;
    wire    [31:0]  target_dataslot_length;
    
    wire    [31:0]  target_buffer_param_struct; // to be mapped/implemented when using some Target commands
    wire    [31:0]  target_buffer_resp_struct;  // to be mapped/implemented when using some Target commands
    
// bridge data slot access
// synchronous to clk_74a

    wire    [9:0]   datatable_addr;
    wire            datatable_wren;
    wire    [31:0]  datatable_data;
    wire    [31:0]  datatable_q;

core_bridge_cmd icb (

    .clk                ( clk_74a ),
    .reset_n            ( reset_n ),

    .bridge_endian_little   ( bridge_endian_little ),
    .bridge_addr            ( bridge_addr ),
    .bridge_rd              ( bridge_rd ),
    .bridge_rd_data         ( cmd_bridge_rd_data ),
    .bridge_wr              ( bridge_wr ),
    .bridge_wr_data         ( bridge_wr_data ),
    
    .status_boot_done       ( status_boot_done ),
    .status_setup_done      ( status_setup_done ),
    .status_running         ( status_running ),

    .dataslot_requestread       ( dataslot_requestread ),
    .dataslot_requestread_id    ( dataslot_requestread_id ),
    .dataslot_requestread_ack   ( dataslot_requestread_ack ),
    .dataslot_requestread_ok    ( dataslot_requestread_ok ),

    .dataslot_requestwrite      ( dataslot_requestwrite ),
    .dataslot_requestwrite_id   ( dataslot_requestwrite_id ),
    .dataslot_requestwrite_size ( dataslot_requestwrite_size ),
    .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack ),
    .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok ),

    .dataslot_update            ( dataslot_update ),
    .dataslot_update_id         ( dataslot_update_id ),
    .dataslot_update_size       ( dataslot_update_size ),
    
    .dataslot_allcomplete   ( dataslot_allcomplete ),

    .rtc_epoch_seconds      ( rtc_epoch_seconds ),
    .rtc_date_bcd           ( rtc_date_bcd ),
    .rtc_time_bcd           ( rtc_time_bcd ),
    .rtc_valid              ( rtc_valid ),
    
    .savestate_supported    ( savestate_supported ),
    .savestate_addr         ( savestate_addr ),
    .savestate_size         ( savestate_size ),
    .savestate_maxloadsize  ( savestate_maxloadsize ),

    .savestate_start        ( savestate_start ),
    .savestate_start_ack    ( savestate_start_ack ),
    .savestate_start_busy   ( savestate_start_busy ),
    .savestate_start_ok     ( savestate_start_ok ),
    .savestate_start_err    ( savestate_start_err ),

    .savestate_load         ( savestate_load ),
    .savestate_load_ack     ( savestate_load_ack ),
    .savestate_load_busy    ( savestate_load_busy ),
    .savestate_load_ok      ( savestate_load_ok ),
    .savestate_load_err     ( savestate_load_err ),

    .osnotify_inmenu        ( osnotify_inmenu ),
    
    .target_dataslot_read       ( target_dataslot_read ),
    .target_dataslot_write      ( target_dataslot_write ),
    .target_dataslot_getfile    ( target_dataslot_getfile ),
    .target_dataslot_openfile   ( target_dataslot_openfile ),
    
    .target_dataslot_ack        ( target_dataslot_ack ),
    .target_dataslot_done       ( target_dataslot_done ),
    .target_dataslot_err        ( target_dataslot_err ),

    .target_dataslot_id         ( target_dataslot_id ),
    .target_dataslot_slotoffset ( target_dataslot_slotoffset ),
    .target_dataslot_bridgeaddr ( target_dataslot_bridgeaddr ),
    .target_dataslot_length     ( target_dataslot_length ),

    .target_buffer_param_struct ( target_buffer_param_struct ),
    .target_buffer_resp_struct  ( target_buffer_resp_struct ),
    
    .datatable_addr         ( datatable_addr ),
    .datatable_wren         ( datatable_wren ),
    .datatable_data         ( datatable_data ),
    .datatable_q            ( datatable_q )

);



////////////////////////////////////////////////////////////////////////////////////////



// video generation
// ~12,288,000 hz pixel clock
//
// 400x360 active @ 60hz (10:9 aspect = Pocket native 1600x1440, no black bars).
// Total budget: 512 x 400 = 204,800 clocks/frame -> 12,288,000/204,800 = 60fps exact.
// No PLL change needed vs the stock 320x240 mode (same total clock count).


assign video_rgb_clock = clk_core_12288;
assign video_rgb_clock_90 = clk_core_12288_90deg;
assign video_rgb = vidout_rgb;
assign video_de = vidout_de;
assign video_skip = vidout_skip;
assign video_vs = vidout_vs;
assign video_hs = vidout_hs;

    localparam  VID_V_BPORCH = 'd10;
    localparam  VID_V_ACTIVE = 'd360;
    localparam  VID_V_TOTAL = 'd400;
    localparam  VID_H_BPORCH = 'd10;
    localparam  VID_H_ACTIVE = 'd400;
    localparam  VID_H_TOTAL = 'd512;

    reg [15:0]  frame_count;
    
    reg [9:0]   x_count;
    reg [9:0]   y_count;
    
    wire [9:0]  visible_x = x_count - VID_H_BPORCH;
    wire [9:0]  visible_y = y_count - VID_V_BPORCH;

    reg [23:0]  vidout_rgb;
    reg         vidout_de, vidout_de_1;
    reg         vidout_skip;
    reg         vidout_vs;
    reg         vidout_hs, vidout_hs_1;
    
    // progress bar: compute fill width in clk_74a (both chunks_played and
    // cur_track_chunks live there), then 2-FF sync into clk_core_12288.
    // Bar now spans x=19..380 (matches oscilloscope box margins, Section 29).
    // bar_fill_x = 19 + floor(chunks_played * 360 / (cur_track_chunks - 1)); reaches 379 at last chunk.
    // chunks_played/cur_track_chunks are 16 bits (see their declarations) to
    // match playlist_ram's real track_chunks field width - a 7-bit version
    // silently truncated any track over ~5.5 minutes (127 chunks); widened
    // while investigating the wraparound bug (see POCKETPLAYER_NOTES.txt).
    wire [31:0] bar_numer      = {16'b0, chunks_played} * 32'd360;
    wire [31:0] bar_denom      = (cur_track_chunks > 16'd1) ? ({16'b0, cur_track_chunks} - 32'd1) : 32'd1;
    wire [31:0] bar_div_full   = (cur_track_chunks != 16'd0) ? (bar_numer / bar_denom) : 32'd0;
    wire  [9:0] bar_fill_x_74a = 10'd19 + bar_div_full[9:0];
    reg   [9:0] bar_fill_x_s1;
    reg  [9:0]  bar_fill_x;
    // pause/resume: A-button toggle in clk_74a; synced into audgen_sclk and clk_core_12288.
    reg         paused;
    reg         btn_a_r;
    wire        paused_s;     // synced to audgen_sclk domain (audio gate)
    wire        paused_vid_s; // synced to clk_core_12288 domain (icon glyph, vinyl rotation gate)

    // d-pad prev/next track
    wire [8:0] prev_track_sel = (track_sel == 9'd0) ? last_track_idx : track_sel - 9'd1;
    reg         btn_right_r, btn_left_r;
    wire        dpad_next = cont1_key[3] && !btn_right_r && !input_locked;
    wire        dpad_prev = cont1_key[2] && !btn_left_r && !input_locked;
    reg         dpad_advance_r;

    // Section 39: one-shot pulse, fires exactly once on the first clk_74a
    // cycle after reset exit, to refresh title_ram/artist_ram from
    // track_sel's real data instead of leaving the hardcoded reset
    // placeholder text on screen until the next actual track-change event
    // (which could be much later - see boot_refresh_r's use below).
    reg         boot_refresh_done;
    wire        boot_refresh_r = ~boot_refresh_done;

    // track_sel synced to clk_core_12288: used to detect track changes so
    // the title ticker restarts at offset 0 on a new track.
    reg [8:0] track_sel_s1, track_sel_vid;

    // ------------------------------------------------------------------
    // Section 29: tab system. Shoulder L/R cycles cur_tab in clk_74a;
    // cur_tab_vid is a 2-FF synced copy for the clk_core_12288 renderer.
    // 0=NowPlaying 1=Album 2=Library 3=Playlists.
    // ------------------------------------------------------------------
    reg  [1:0] cur_tab;
    reg  [1:0] cur_tab_s1, cur_tab_vid;
    reg  [1:0] cur_tab_vid_prev;   // previous-frame snapshot, for ticker reset
    reg  [8:0] track_sel_vid_prev; // previous-frame snapshot, for ticker reset
    reg  [8:0] list_cursor_vid_prev; // Section 40: previous-frame snapshot, for Library ticker reset
    reg        btn_shl_r, btn_shr_r;
    wire       lib_mode = (cur_tab_vid == 2'd2);

    // ------------------------------------------------------------------
    // Now Playing effect select (Section 30, extended Section 32, reduced to
    // 2 effects in the Section 35 follow-up: the Oscilloscope was removed
    // entirely by user request - not great-looking, and its continuous
    // ~48kHz zero-crossing capture + waveform rendering was also the prime
    // suspect for a reported FPGA temperature rise, since it was BOTH the
    // default boot mode and the only one of the three effects with genuinely
    // continuous high-frequency switching activity (Still Thumbnail/Spinning
    // Vinyl are comparatively static). See POCKETPLAYER_NOTES.txt for the full
    // writeup - the removed oscilloscope source (scope_ram/osc_* capture FSM)
    // is preserved there for reference, not in this file. D-pad Up/Down is
    // unused in the NowPlaying tab (Up/Down only does something in Library),
    // so it doubles as an effect cycle there: 0=Still Thumbnail (static album
    // art + large play/pause icon), 1=Spinning Vinyl (album art + partially-
    // hidden rotating disc), 2=Full Art (Section 43: full-screen album art,
    // no icon/text overlay - see thumb_x_start_eff etc. below). Cycles
    // 0->1->2->0. effect_mode lives in clk_74a (advanced alongside the other
    // button handling); effect_mode_vid is a 2-FF synced copy for the
    // renderer, same pattern as paused_vid_s. Widened 1->2 bits for the
    // third mode.
    // ------------------------------------------------------------------
    reg  [1:0] effect_mode;
    wire [1:0] effect_mode_vid;
    localparam EFFECT_STILL_THUMB    = 2'd0;
    localparam EFFECT_SPINNING_VINYL = 2'd1;
    localparam EFFECT_FULL_ART       = 2'd2;

    // Library tab cursor/scroll: up/down d-pad browses tracks; A plays
    // selected (see button handler near the bottom of the file). list_cursor
    // marks the highlighted track (0..MAX_TRACKS-1, up to 512); list_scroll
    // is the track index shown in the TOP visible row - only 8 rows are ever
    // shown at once (Section 32 adds scrolling: list_scroll tracks the
    // cursor, adjusting by the minimum amount needed to keep it on-screen).
    // playlist_ram's secondary read port (lib_idx) is driven by
    // list_scroll + list_row (list_row = which of the 8 visible rows).
    reg  [8:0] list_cursor;
    reg  [8:0] list_scroll;
    // Section 36 follow-up: video-domain synced copies. list_track_idx/
    // row_selected below used to read list_scroll/list_cursor RAW - the only
    // two clk_74a registers touching the renderer with NO synchronizer at
    // all (every other cross-domain signal in this file - track_sel_vid,
    // cur_tab_vid, effect_mode_vid, paused_vid_s - gets at least a 2/3-FF
    // sync first). Prime suspect for the reported "Library thumbnail shows
    // at the top/bottom of the page" bug: list_scroll changes on every
    // scroll button press (much more often than track_sel), and an
    // unsynchronized multi-bit read can transiently glitch to a WRONG value
    // for a cycle or two right at the moment it changes - if that transient
    // value momentarily makes list_track_idx equal track_sel_vid for the
    // WRONG row (e.g. row 0 or 7), the per-row icon would flash at that
    // wrong position. Note this only reduces metastability risk per bit
    // (same residual multi-bit-tear risk as track_sel_vid/cur_tab_vid
    // already accept elsewhere in this file) - not a formal guarantee, but
    // strictly better than the previous zero synchronization.
    wire [8:0] list_scroll_vid, list_cursor_vid;
    localparam LIST_VISIBLE_ROWS = 9'd8;
    reg        btn_up_r, btn_dn_r;
    // Section 43: long-press Up/Down auto-repeat in the Library tab (~5
    // steps/sec once held) - see the Up/Down handler below for the full
    // mechanism. Counts clk_74a cycles (74.25MHz, this whole block's clock).
    localparam [25:0] UPDN_INITIAL_DELAY   = 26'd37_125_000; // ~500ms: hold-before-repeat
    localparam [25:0] UPDN_REPEAT_INTERVAL = 26'd14_850_000; // ~200ms = 5 steps/sec
    reg  [25:0] updn_hold_ctr;
    reg         updn_repeating;
    // updn_thresh_hit fires once the hold counter crosses whichever delay
    // currently applies (the longer initial delay before repeating starts,
    // then the faster steady repeat interval); do_step_up/down are true
    // either on the ORIGINAL press edge (single step, unchanged from
    // before) or on a repeat tick while still held.
    wire       updn_held       = cont1_key[0] || cont1_key[1];
    wire       updn_thresh_hit = updn_held &&
                                  (updn_hold_ctr == (updn_repeating ? UPDN_REPEAT_INTERVAL : UPDN_INITIAL_DELAY));
    wire       do_step_up      = !input_locked && ((cont1_key[0] && !btn_up_r) || (cont1_key[0] && updn_thresh_hit));
    wire       do_step_down    = !input_locked && ((cont1_key[1] && !btn_dn_r) || (cont1_key[1] && updn_thresh_hit));
    reg        lib_select_r;  // 1-cycle pulse: A pressed while in Library tab
    reg        lib_select_r2; // 1-cycle pulse, delayed one cycle after lib_select_r:
                               // by now track_sel has updated to list_cursor, and
                               // pram_read_idx_next's pre-fetch (issued the cycle
                               // lib_select_r fired) has landed in playlist_ram's
                               // registered read, so pram_title/pram_artist
                               // reflect the NEW track - same two-stage pattern as
                               // auto_advance/auto_advance_r below.

    // ------------------------------------------------------------------
    // Track title (64 chars) / artist (32 chars): bridge-writable RAM,
    // refreshed from playlist_ram's track_title/track_artist (big-endian)
    // on every track-select/advance event. Replaces the old 16-char
    // text_ram (Section 29).
    // ------------------------------------------------------------------
    reg  [7:0] title_ram  [0:63];
    reg  [7:0] artist_ram [0:31];
    reg  [8:0] track_sel;
    wire [9:0] pram_track_count; // live non-zero-chunk track count from playlist_ram (0..512)
    // Section 35: subtract at full width THEN truncate, not the other way
    // around. The old `pram_track_count[4:0] - 5'd1` truncated to 5 bits
    // BEFORE subtracting, which is a no-op for any count < 32 (bit 5 is 0
    // anyway) but silently gives last_track_idx=0 at exactly MAX_TRACKS=32
    // (6'd32[4:0]=0, 0-1 wraps to 31 one way or 0 the other depending on
    // where the truncation happens - either way, wrong). Fixed then by
    // subtracting at full 6-bit width before truncating to 5 bits; Section
    // 41's MAX_TRACKS=512 jump keeps the same shape at the new widths
    // (10-bit subtract, truncate to 9-bit last_track_idx) for the same
    // reason.
    wire [9:0] last_track_idx10 = pram_track_count - 10'd1; // wraps high pre-boot (benign, count=0)
    wire [8:0] last_track_idx   = last_track_idx10[8:0];
    wire [8:0] next_track_seq   = (track_sel == last_track_idx) ? 9'd0 : track_sel + 9'd1;

    // ------------------------------------------------------------------
    // Section 35 follow-up: repeat-all/stop-at-end + shuffle toggles, per
    // plans/UI_SPEC.md's Now Playing button table (X=shuffle, Y=repeat) -
    // reduced from the spec's 3-state repeat cycle (all/single/off) to a
    // simple 2-state toggle (all/stop-at-end) since that's specifically
    // what was requested; "repeat single" is not implemented (deferred).
    // repeat_all defaults ON (matches the always-wraps behavior this project
    // already had, so the new feature doesn't change default behavior).
    // shuffle_on defaults OFF.
    // ------------------------------------------------------------------
    reg  repeat_all;
    reg  shuffle_on;
    reg  btn_x_r, btn_y_r;
    // Section 43: screensaver (Select button, full black blank - see
    // screensaver_vid's use in the render block below).
    reg  btn_select_r;
    reg  screensaver_on;
    wire screensaver_vid;
    // Section 44: button lock (Start button) - "prevent accidentally
    // pressing" per user request. Mutually exclusive with the screensaver
    // by construction: Select's own toggle is guarded by !lock_on (can't
    // enter/exit the screensaver while locked) and Start's toggle is
    // guarded by !screensaver_on (can't lock/unlock while the screensaver
    // is active) - so at most one of lock_on/screensaver_on is ever true,
    // and each has exactly one working "escape" button while active
    // (Start for lock_on, Select for screensaver_on). input_locked gates
    // every OTHER button (D-pad, A, X, Y, L, R) globally, regardless of tab.
    reg  btn_start_r;
    reg  lock_on;
    wire input_locked = lock_on || screensaver_on;

    // Free-running 16-bit Galois LFSR (taps 16,14,13,11 - maximal length),
    // advances every clk_74a cycle regardless of anything else so its value
    // at the exact moment a shuffle pick is needed is effectively random
    // relative to user/playback timing. Not cryptographic quality, doesn't
    // need to be for a "shuffle" feature.
    reg  [15:0] lfsr;
    // Section 36 follow-up: shuffle_pick is now a REGISTERED value (computed
    // once per cycle in the same always block that advances lfsr, further
    // below), not a bare combinational wire off the raw lfsr. Root cause of
    // a real hardware bug (title/artist sometimes blank or wrong, "shifted
    // left", only when shuffle was on): `lfsr % pram_track_count` is a
    // variable-divisor modulo - a comparatively deep combinational divider,
    // unlike next_track_seq's simple compare-and-add-1. Since lfsr changes
    // on EVERY clk_74a cycle, that divider was being asked to fully settle
    // within a single ~13.4ns clk_74a period every cycle - a real timing
    // closure risk that iverilog's zero-delay simulation cannot catch (it
    // doesn't model gate delay at all), but Quartus/real silicon can and
    // apparently did fail to meet. Worse, the divider's single output
    // (next_track_eff below) fans out to TWO separate destination registers
    // in two different modules (track_sel here, and playlist_ram's
    // registered track_row read) - if the combinational path was marginal,
    // each destination could latch a DIFFERENT resolved value due to
    // differing routing delay, so track_sel and the title/artist actually
    // fetched could disagree - exactly the reported symptom. Registering
    // shuffle_pick gives the divider a full clock period to settle at a
    // single point (its own register), so by the time anything reads it,
    // it's a clean, already-stable value - both destinations then sample
    // the SAME settled register, eliminating the divergence risk. The extra
    // cycle of "staleness" on the random value itself is irrelevant for a
    // shuffle feature.
    reg  [8:0] shuffle_pick;
    // next_track_eff: what "next" (auto-advance or manual D-pad Right) should
    // actually select - a random pick when shuffle is on, else the ordinary
    // sequential/wraparound choice. D-pad Left (prev) is deliberately NOT
    // shuffle-aware (always steps sequentially backward) - a shuffled
    // "previous" would need a history stack, out of scope for now.
    wire [8:0] next_track_eff = shuffle_on ? shuffle_pick : next_track_seq;
    // auto_advance_would_stop: "stop after all tracks played" only applies to
    // the natural sequential end-of-library case (shuffle keeps looping
    // continuously regardless of repeat_all - combining shuffle with "stop at
    // end" isn't implemented, documented simplification, see notes).
    wire       auto_advance_would_stop = !shuffle_on && !repeat_all && (track_sel == last_track_idx);

    // Library secondary read port outputs (from playlist_ram, little-endian)
    wire [511:0] lib_title_le;
    wire [255:0] lib_artist_le;

    // ------------------------------------------------------------------
    // Now Playing / Library layout constants (400x360 active).
    // ------------------------------------------------------------------
    localparam [9:0]  OSC_X_START    = 10'd20;
    // Section 35: top gap widened 8->24 (screen edge to box/thumbnail/vinyl
    // was flush and looked cramped, especially for the borderless Still
    // Thumbnail/Spinning Vinyl effects). The extra 16px is taken from the
    // formerly-oversized dead space below the box (shared with the icon's
    // new position and the title/artist block - see BIGICON_Y_4X/
    // TITLE_Y_START below). OSC_Y_BOTBRD/OSC_Y_BOT/DISC_CY (further below)
    // are all expressions of OSC_Y_TOP now instead of independent hardcoded
    // constants, so retuning this one value keeps the box, waveform baseline,
    // and vinyl disc center all self-consistent.
    localparam [9:0]  OSC_Y_TOP      = 10'd24;   // box border, top row (was 8)
    localparam [9:0]  OSC_Y_BOTBRD   = OSC_Y_TOP + 10'd173; // box border, bottom row (174-row content height, unchanged)
    localparam [9:0]  OSC_Y_BOT      = OSC_Y_TOP + 10'd150; // waveform baseline; keeps silence centered at box-relative y=86
    // Section 35: the play/pause icon is now the SAME large 32x32 icon in
    // all three NowPlaying effects (previously only Still Thumbnail got the
    // big icon; Oscilloscope/Spinning Vinyl showed a separate, smaller 16x16
    // one - see in_big_icon below). BIGICON_X_4X is declared with the other
    // big-icon geometry further below.
    // Title/artist centered in the gap between the box bottom border and the
    // progress bar (336), now split three ways with the icon (26px gap +
    // 32px icon + 26px gap + 28px title/artist block + 26px gap = 138px,
    // exactly filling 198..335): BIGICON_Y_4X = 198+26 = 224 (see below),
    // TITLE_Y_START = 224+32+26 = 282.
    localparam [9:0]  TITLE_Y_START  = 10'd282;  // 2x scale, 16px tall, full width w/ ticker
    localparam [9:0]  ARTIST_Y_START = 10'd302;  // 1x scale, 8px tall, centered
    localparam [9:0]  BAR_Y_START    = 10'd336;
    localparam [9:0]  BAR_Y_END      = 10'd343;
    localparam [9:0]  BAR_X_START    = 10'd19;   // matches box border indent
    localparam [9:0]  BAR_X_END      = 10'd380;
    localparam [9:0]  TAB_HDR_X      = 10'd136;  // 2x scale, 8 chars, centered
    localparam [9:0]  TAB_HDR_Y      = 10'd8;
    // Section 40: dark navy-grey -> pure black, per feedback wanting the
    // progress bar black/white instead of grey/white (the Oscilloscope box
    // border this was originally shared with is long gone - this is purely
    // the progress bar's empty-track/separator color now).
    localparam [23:0] COLOR_BORDER   = 24'h000000;

    // ------------------------------------------------------------------
    // Section 30: Library track list. Replaces the old single-track
    // "browse preview" (which reused the NowPlaying title/artist area and
    // only ever showed the one currently-browsed track) with an actual
    // list of all MAX_TRACKS(8) tracks, one row each, 2x-scale text,
    // left-aligned, no ticker (title just truncates at LIST_CHARS chars -
    // trailing bytes in playlist.bin are already space-padded so they
    // render as blank, no length computation needed). The row matching
    // list_cursor is drawn with a solid highlight band behind dark text;
    // other rows show white text on the normal dark background. Rows
    // beyond the live track_count are left blank (row_has_track gates both
    // the highlight and the text).
    // ------------------------------------------------------------------
    // Section 31: no more "now playing" mini preview in Library (removed -
    // see in_title_area/in_artist_area below), so the list now fills nearly
    // the whole screen instead of a cramped 128px band: 36px/row * 8 rows =
    // 288px (y=28..316), comfortably above the y=335 separator. 2x-scale
    // text (16px tall) is vertically centered within each 36px row band
    // ((36-16)/2 = 10px padding top/bottom).
    localparam [9:0]  LIST_HL_X_START = 10'd16;  // highlight band left edge
    localparam [9:0]  LIST_HL_X_END   = 10'd384; // highlight band right edge (exclusive)
    // Section 41 follow-up: was 10'd28 (only a 4px gap under the header),
    // leaving a comparatively large 44px blank band below the 8th row
    // (screen is 360px tall; 8 rows * 36px = 288px doesn't fill it). Per
    // feedback, the leftover space reads better split roughly evenly above
    // and below the list instead of nearly all of it dumped at the bottom -
    // 48 gives a 24px gap on both ends (48-24=24 above, 360-(48+288)=24
    // below), same row count/size, no other layout change needed.
    localparam [9:0]  LIST_Y_START    = 10'd48;  // ~24px under "LIBRARY " header (ends y=23)
    localparam [9:0]  LIST_ROW_H      = 10'd36;  // full row band (highlight height)
    localparam [9:0]  LIST_TEXT_PAD   = 10'd10;  // (36-16)/2, centers the 16px-tall glyph in the row
    localparam [3:0]  LIST_MAX_ROWS   = 4'd8;   // rendering bound - must match LIST_VISIBLE_ROWS below (scrolling logic)
    // Section 43: matches the new PocketPlayer icon's background blue
    // (plans/PocketPlayer_icon.drawio, #4C7AA3) per user request, tying the
    // Library selection color to the project's own branding - was a cyan
    // accent (0x00B4D8) shared with nothing else in this file anymore.
    localparam [23:0] COLOR_HIGHLIGHT = 24'h4C7AA3;

    // Section 32: small per-row album-art icon, left of the title. Section
    // 35: track_thumb_ram.sv held real per-track art for only the one
    // currently-loaded track, so the icon only showed on that one matching
    // row - Section 39 replaced this with a genuine 8-row cache (see
    // row_icon_pixel/in_list_icon below and audio_streamer.sv's Library
    // round-robin fetch), so every visible row with a track now shows its
    // own real icon, no downscaling needed (the source image is already
    // pre-scaled to exactly LIST_ICON_SIZE on the PC).
    localparam [9:0]  LIST_ICON_SIZE  = 10'd30;
    localparam [9:0]  LIST_ICON_X     = LIST_HL_X_START + 10'd3; // = 19
    localparam [9:0]  LIST_ICON_PAD_Y = (LIST_ROW_H - LIST_ICON_SIZE) / 10'd2; // = 3
    // Section 37 follow-up: gap widened 7->16 (looked too dense per feedback,
    // observed on the currently-playing row where the icon actually shows).
    localparam [9:0]  LIST_X_START    = LIST_ICON_X + LIST_ICON_SIZE + 10'd16; // = 65, room for icon + gap
    localparam [5:0]  LIST_CHARS      = 6'd19;   // visible chars/row (19*16=304px, fits margins after the icon)

    // ------------------------------------------------------------------
    // Title/artist length (trailing-space trim): combinational scan used
    // to center short text and to gate the title news ticker. The mini
    // "now playing" preview (title/artist area below) always reflects
    // title_ram/artist_ram - i.e. whatever is ACTUALLY PLAYING - even while
    // browsing the Library tab (same idea as the progress bar there, which
    // already shows actual playback progress independent of the browse
    // cursor). The Library list itself (new, see below) reads playlist_ram's
    // lib_title_le/lib_artist_le directly per-row instead.
    // ------------------------------------------------------------------
    integer ti, ai, li;
    reg [6:0] title_len_c, artist_len_c;
    always @(*) begin
        title_len_c = 7'd0;
        for (ti = 0; ti < 64; ti = ti + 1)
            if (title_ram[ti] != 8'h20) title_len_c = ti[6:0] + 7'd1;
    end
    always @(*) begin
        artist_len_c = 7'd0;
        for (ai = 0; ai < 32; ai = ai + 1)
            if (artist_ram[ai] != 8'h20) artist_len_c = ai[6:0] + 7'd1;
    end
    wire [6:0] title_len_eff  = title_len_c;
    wire [6:0] artist_len_eff = artist_len_c;

    // Section 40: same trailing-space-trim scan as title_len_c above, but
    // for whichever Library row is CURRENTLY being scanned (lib_title_le,
    // playlist_ram's secondary read port). Only meaningful while that row
    // happens to be the selected one - see sel_title_len's latch in the
    // main video always block below, which captures this at the moment
    // row_selected is true and holds it the rest of the frame.
    reg [6:0] lib_title_len_c;
    always @(*) begin
        lib_title_len_c = 7'd0;
        for (li = 0; li < 64; li = li + 1)
            if (lib_title_le[li*8 +: 8] != 8'h20) lib_title_len_c = li[6:0] + 7'd1;
    end

    // ------------------------------------------------------------------
    // Track title: 2x scale (16px/char), 25 chars visible (400/16). Ticker
    // scrolls when the trimmed title exceeds 25 chars.
    // Section 41: both this ticker and the Library selected-row ticker
    // (lib_ticker_offset/lib_row_ticking below/above) share the same
    // hold-scroll-hold-loop shape now: hold at offset 0, scroll left one
    // character at a time only until the title's LAST character reaches the
    // rightmost visible slot (not all the way off-screen), hold there, then
    // reset to offset 0. Two independent state machines (different visible-
    // char counts/registers, different tabs) - the shapes are just kept
    // identical on purpose per user feedback.
    // ------------------------------------------------------------------
    wire       active_ticker = !lib_mode && (title_len_eff > 7'd25);
    // Library titles here (the mini "now playing" preview area, NOT the
    // list rows) never scroll; clamp to 25 chars for the centering math
    // below so a long library title truncates cleanly instead of wrapping
    // the x_start/width arithmetic negative (same class of bug as a title
    // >25 chars would hit if it weren't ticker-routed in NowPlaying mode).
    wire [6:0] title_center_len = (title_len_eff > 7'd25) ? 7'd25 : title_len_eff;
    reg  [5:0] ticker_offset;
    reg  [4:0] ticker_div;
    reg  [1:0] ticker_state;    // 0=HOLD_START, 1=SCROLL, 2=HOLD_END
    reg  [7:0] ticker_hold_ctr;
    // The title's last character reaches the rightmost of the 25 visible
    // slots once ticker_offset == title_len_eff-25 - scrolling further would
    // only reveal blank padding past the title's actual end.
    wire [6:0] ticker_max_offset = (title_len_eff > 7'd25) ? (title_len_eff - 7'd25) : 7'd0;

    // Section 40/41: Library selected-row ticker state (see lib_row_ticking/
    // list_char_idx above for the render side). Same hold-scroll-hold-loop
    // shape as the NowPlaying ticker above.
    reg  [6:0] sel_title_len;      // latched length of the selected row's title
    reg  [6:0] lib_ticker_offset;
    reg  [7:0] lib_ticker_hold_ctr;
    reg  [1:0] lib_ticker_state;   // 0=HOLD_START, 1=SCROLL, 2=HOLD_END
    reg  [4:0] lib_ticker_div;
    // Section 41: hold shortened 3s -> 1s per feedback (3s felt too long);
    // now shared by both the start hold and the new end-of-scroll hold, on
    // both tickers.
    localparam [7:0] TICKER_HOLD_VSYNCS = 8'd60; // ~1s @ 60fps
    wire [6:0] lib_ticker_max_offset = (sel_title_len > {1'b0, LIST_CHARS})
                                       ? (sel_title_len - {1'b0, LIST_CHARS}) : 7'd0;

    // Section 44: "LOCKED"/"UNLOCKED" banner, shown for ~1s (reusing
    // TICKER_HOLD_VSYNCS) after Start toggles the lock. lock_on_vid_prev is
    // a previous-vsync snapshot, same reset-on-change idea as every other
    // cross-domain flag compared this way in this file.
    reg        lock_on_vid_prev;
    reg  [7:0] lock_msg_timer;
    reg        lock_msg_showing;
    reg        lock_msg_is_lock; // which message: 1=LOCKED, 0=UNLOCKED

    wire [9:0] title_x_start = active_ticker ? 10'd0 : (10'd200 - {title_center_len, 3'b0});
    wire [9:0] title_x_off   = visible_x - title_x_start;
    wire [4:0] title_slot    = title_x_off[8:4];
    wire [5:0] title_rd_idx  = {1'b0, title_slot} + (active_ticker ? ticker_offset : 6'd0);
    wire       in_title_x    = active_ticker ||
                                (visible_x >= title_x_start &&
                                 title_x_off < {title_center_len, 4'b0});
    // Section 43: no text overlay in Full Art mode.
    wire       in_title_area = (cur_tab_vid == 2'd0) && (effect_mode_vid != EFFECT_FULL_ART) && in_title_x &&
                                (visible_y >= TITLE_Y_START) && (visible_y < TITLE_Y_START + 10'd16);
    wire [9:0] title_y_off    = visible_y - TITLE_Y_START;
    wire [2:0] title_font_row = title_y_off[3:1];
    wire [2:0] title_font_col = title_x_off[3:1];
    wire [7:0] title_char_code = title_ram[title_rd_idx];
    wire [7:0] title_pixels;
    wire       title_pixel_lit = in_title_area && title_pixels[3'd7 - title_font_col];

    // Artist: 1x scale (8px/char), always centered, no ticker (32 chars max,
    // user confirmed that's never expected to overflow).
    wire [9:0] artist_x_start = 10'd200 - {artist_len_eff, 2'b0};
    wire [9:0] artist_x_off   = visible_x - artist_x_start;
    wire [4:0] artist_rd_idx  = artist_x_off[7:3];
    wire       in_artist_area = (cur_tab_vid == 2'd0) && (effect_mode_vid != EFFECT_FULL_ART) &&
                                 (visible_x >= artist_x_start) &&
                                 (artist_x_off < {artist_len_eff, 3'b0}) &&
                                 (visible_y >= ARTIST_Y_START) && (visible_y < ARTIST_Y_START + 10'd8);
    wire [9:0] artist_y_off    = visible_y - ARTIST_Y_START;
    wire [2:0] artist_font_row = artist_y_off[2:0];
    wire [2:0] artist_font_col = artist_x_off[2:0];
    wire [7:0] artist_char_code = artist_ram[artist_rd_idx];
    wire [7:0] artist_pixels;
    wire       artist_pixel_lit = in_artist_area && artist_pixels[3'd7 - artist_font_col];

    // ------------------------------------------------------------------
    // Library track list rows (Section 30, scrolling added Section 32).
    // list_row is which of the 8 VISIBLE rows the current scanline belongs
    // to; list_track_idx (= list_scroll + list_row) is the actual playlist
    // index for that row and is what drives playlist_ram's lib_idx secondary
    // port. Section 34: that read is now registered (1-cycle latency), but
    // list_track_idx only changes at row-height boundaries (every 36
    // scanlines), which always land during horizontal blanking - hundreds of
    // cycles of margin before the next row's first visible pixel - so no
    // retiming is needed here.
    // row_selected compares against list_cursor (the persistent browse/
    // highlight position); row_has_track hides rows beyond the live
    // track_count (relevant when track_count - list_scroll < 8, i.e. the
    // last page of a list that doesn't fill all 8 rows).
    // ------------------------------------------------------------------
    wire [9:0] list_y_off    = visible_y - LIST_Y_START;
    wire [9:0] list_row_full = list_y_off / LIST_ROW_H; // 0..7 when in-range (LIST_ROW_H not power-of-2, needs real division)
    wire [2:0] list_row      = list_row_full[2:0];
    wire [8:0] list_track_idx = list_scroll_vid + {6'b0, list_row};
    wire [9:0] list_row_top  = list_row_full * LIST_ROW_H;
    wire [9:0] list_y_local  = list_y_off - list_row_top; // 0..35: position within this row's band
    wire       in_list_text_row = (list_y_local >= LIST_TEXT_PAD) && (list_y_local < LIST_TEXT_PAD + 10'd16);
    wire [9:0] list_text_y_off  = list_y_local - LIST_TEXT_PAD; // valid (0..15) only when in_list_text_row
    wire [9:0] list_x_off   = visible_x - LIST_X_START;
    // list_slot: WHICH on-screen character slot (0..LIST_CHARS-1) - ticker-
    // independent, used only to decide whether this pixel is within the
    // visible text window at all (same role as title_slot for the
    // NowPlaying ticker above).
    wire [5:0] list_slot     = {1'b0, list_x_off[8:4]}; // divide by 16 (2x-scale glyph width)
    // list_char_idx: WHICH character of the title STRING to fetch for this
    // slot - adds the Library ticker's offset (see lib_row_ticking below)
    // when this is the actively-scrolling selected row, same title_slot-vs-
    // title_rd_idx split as the NowPlaying ticker. 6-bit wire, so this
    // wraps modulo 64 if it ever exceeds lib_title_le's 64-char range -
    // same accepted precedent as the existing NowPlaying ticker (see
    // title_rd_idx above), not a new risk.
    wire [5:0] list_char_idx = list_slot + (lib_row_ticking ? lib_ticker_offset[5:0] : 6'd0);
    wire [2:0] list_font_row = list_text_y_off[3:1];
    wire [2:0] list_font_col = list_x_off[3:1];
    wire [7:0] list_char_code = lib_title_le[list_char_idx*8 +: 8];
    wire [7:0] list_pixels;
    wire       row_has_track = ({1'b0, list_track_idx} < pram_track_count);
    wire       row_selected  = (list_track_idx == list_cursor_vid);
    // Section 40: Library selected-row ticker - only the highlighted row,
    // and only when its title is actually too long to fit LIST_CHARS slots
    // (mirrors active_ticker's >25-char gate above, just against this row's
    // own title instead of the NowPlaying title_ram). sel_title_len is a
    // latched register (see the main video always block below) since
    // lib_title_le only reflects THIS row's data while it's actually being
    // scanned, not continuously.
    wire       lib_row_ticking = row_selected && (sel_title_len > {1'b0, LIST_CHARS});
    wire       in_list_row_band = lib_mode &&
                                   (visible_y >= LIST_Y_START) &&
                                   (visible_y < LIST_Y_START + LIST_MAX_ROWS * LIST_ROW_H) &&
                                   (visible_x >= LIST_HL_X_START) && (visible_x < LIST_HL_X_END);
    wire       in_list_text     = in_list_row_band && in_list_text_row &&
                                   (visible_x >= LIST_X_START) && (list_slot < LIST_CHARS);
    wire       list_pixel_lit   = in_list_text && row_has_track &&
                                   list_pixels[3'd7 - list_font_col];
    wire       list_highlight_on = in_list_row_band && row_has_track && row_selected;

    // Section 39: per-row thumbnail icon, now a genuine per-row cache (see
    // track_thumb_ram.sv's row_icon_mem and audio_streamer.sv's Library
    // round-robin fetch) instead of only ever showing the currently-loaded
    // track's row. Gating is bounded via in_list_row_band (folds in
    // lib_mode + the proper visible_y range) rather than re-deriving an
    // unbounded check - this is the exact fix Section 38 applied after
    // finding the OLD in_list_icon could alias into the header/margin
    // areas via unsigned-subtraction underflow (see git history/
    // POCKETPLAYER_NOTES.txt Section 38 for the full story) - keep this
    // condition built from in_list_row_band, don't regress that fix.
    wire       in_list_icon = in_list_row_band && row_has_track &&
                               (visible_x >= LIST_ICON_X) && (visible_x < LIST_ICON_X + LIST_ICON_SIZE) &&
                               (list_y_local >= LIST_ICON_PAD_Y) && (list_y_local < LIST_ICON_PAD_Y + LIST_ICON_SIZE);

    // Section 35: play/pause icon unified to ONE size across all three
    // NowPlaying effects (previously Still Thumbnail alone got a 4x/32x32
    // icon while Oscilloscope/Spinning Vinyl showed a separate, smaller
    // 2x/16x16 one - the small-icon path (in_icon/ICON_X_2X/ICON_Y_2X) is
    // retired entirely; see in_big_icon below, now ungated on effect_mode).
    // ALSO: source bitmap resolution doubled 8x8 -> 16x16 (rendered at 2x
    // instead of 4x for the same 32x32 final footprint) so the diagonal
    // edge of the play triangle has 8 distinct steps instead of 4 - visibly
    // less blocky at this size, per the "icon looks low-res" report.
    function [15:0] play_bmp_row;
        // Right-pointing triangle: row's lit width increases 1->8 down to
        // the vertical center (rows 7/8), then mirrors back down to 1 - same
        // shape as the original 8-row version, just twice the row/column
        // resolution. Width w (1..8) lit bits from the MSB (left) down.
        //
        // The raw shift below anchors the triangle's flat edge at column 0,
        // so its bounding box (columns 0..7 at max width) only fills the
        // LEFT HALF of the 16-wide bitmap - clearly off-center from
        // PAUSE_BMP's bars (columns 2..13, centered on column 7.5), which is
        // exactly the "icon shifts position when switching play/pause" bug
        // reported after Section 35. The trailing >>4 re-centers it: at max
        // width (w=8) the lit columns become 4..11, centered on column 7.5,
        // matching PAUSE_BMP's center exactly.
        input [3:0] row; // 0..15
        reg   [4:0] w;
        begin
            w = (row < 4'd8) ? ({1'b0, row} + 5'd1) : (5'd16 - {1'b0, row});
            play_bmp_row = (16'hFFFF << (5'd16 - w)) >> 4;
        end
    endfunction
    // Two vertical bars (columns 2-5 and 10-13 of 16, i.e. bits [13:10] and
    // [5:2]), same on every row - uniform rectangle pair, no per-row shaping
    // needed for a pause glyph.
    localparam [15:0] PAUSE_BMP = 16'h3C3C;

    wire [3:0] big_icon_col = big_icon_x_off[4:1]; // divide by 2 (2x scale of a 16-wide source)
    wire [3:0] big_icon_row = big_icon_y_off[4:1];
    wire [15:0] big_play_bmp = play_bmp_row(big_icon_row);
    // Section 41: icon meaning was backwards from every other player's
    // convention (icon shows the ACTION A TAP WILL DO, not the current
    // state) - swapped so paused shows the play triangle (tap to play) and
    // playing shows the pause bars (tap to pause).
    wire        big_icon_lit = in_big_icon && (paused_vid_s ? big_play_bmp[4'd15 - big_icon_col]
                                                             : PAUSE_BMP[4'd15 - big_icon_col]);

    // progress bar area: NowPlaying tab only (Section 35: previously also
    // shown as a footer in Library - per Section 31's own "flag if that
    // should go too" note, this turned out to be a real problem, not just
    // a cosmetic choice: since it keeps cycling as playback naturally
    // progresses/auto-advances, a user glancing at the Library tab without
    // this context read it as a stuck "loading" indicator - the actual
    // root cause of the original "library loading slowly" report. Library
    // is now track-list-only, matching its full-screen-list redesign
    // intent from Section 31 more closely (the list already reads
    // "whatever is actually playing" via row highlighting; the extra bar
    // never added information the list didn't already convey through the
    // highlighted row, only visual noise that looked like a status).
    // Section 43: no progress bar in Full Art mode either (part of the "no
    // icon/text overlay" ask).
    wire in_bar_area = (cur_tab_vid == 2'd0) && (effect_mode_vid != EFFECT_FULL_ART) &&
                       (visible_y >= BAR_Y_START) && (visible_y <= BAR_Y_END) &&
                       (visible_x >= BAR_X_START) && (visible_x < BAR_X_END);

    // Tab header: "LIBRARY " at y=8..23, 2x scale, 8 chars centered.
    // NowPlaying tab shows nothing here (in_tab_hdr excludes it).
    // Section 40: Album/Playlists tabs removed from the app (were never
    // more than a "COMING SOON" placeholder - see POCKETPLAYER_NOTES.txt
    // history) - LIBRARY is the only tab_header_char case left reachable
    // now that cur_tab only ever holds 2'd0 or 2'd2, so this simplifies to
    // a plain conditional instead of a 4-way case, and the old "COMING
    // SOON" function/wires/font instance are deleted entirely (not just
    // hidden), same treatment as the Oscilloscope's removal.
    function [7:0] tab_header_char;
        input [2:0] idx;
        reg [63:0] s;
        begin
            s = "LIBRARY ";
            tab_header_char = s[(7-idx)*8 +: 8];
        end
    endfunction

    wire in_tab_hdr = lib_mode &&
                      (visible_x >= TAB_HDR_X) && (visible_x < TAB_HDR_X + 10'd128) &&
                      (visible_y >= TAB_HDR_Y) && (visible_y < TAB_HDR_Y + 10'd16);
    wire [9:0] hdr_x_off    = visible_x - TAB_HDR_X;
    wire [9:0] hdr_y_off    = visible_y - TAB_HDR_Y;
    wire [2:0] hdr_char_idx = hdr_x_off[6:4];
    wire [2:0] hdr_font_row = hdr_y_off[3:1];
    wire [2:0] hdr_font_col = hdr_x_off[3:1];
    wire [7:0] hdr_char_code = tab_header_char(hdr_char_idx);
    wire [7:0] hdr_pixels;
    wire       hdr_pixel_lit = in_tab_hdr && hdr_pixels[3'd7 - hdr_font_col];

    // Section 44: "LOCKED"/"UNLOCKED" banner - top-left corner, 2x scale,
    // shown for ~1s after Start toggles the lock (lock_msg_showing, see the
    // vsync-boundary timer above). Visible over EITHER tab and any
    // NowPlaying effect (including Full Art) - unlike the other overlays,
    // this is a safety notification, not decoration, so it isn't suppressed
    // there. Both strings are exactly 8 characters (space-padded) so one
    // fixed-width function covers both, same technique as tab_header_char.
    localparam [9:0] LOCK_MSG_X = 10'd8;
    localparam [9:0] LOCK_MSG_Y = 10'd8;
    function [7:0] lock_msg_char;
        input [2:0] idx;
        reg [63:0] s;
        begin
            s = lock_msg_is_lock ? "LOCKED  " : "UNLOCKED";
            lock_msg_char = s[(7-idx)*8 +: 8];
        end
    endfunction

    wire in_lock_msg = lock_msg_showing &&
                        (visible_x >= LOCK_MSG_X) && (visible_x < LOCK_MSG_X + 10'd128) &&
                        (visible_y >= LOCK_MSG_Y) && (visible_y < LOCK_MSG_Y + 10'd16);
    wire [9:0] lock_msg_x_off    = visible_x - LOCK_MSG_X;
    wire [9:0] lock_msg_y_off    = visible_y - LOCK_MSG_Y;
    wire [2:0] lock_msg_char_idx = lock_msg_x_off[6:4];
    wire [2:0] lock_msg_font_row = lock_msg_y_off[3:1];
    wire [2:0] lock_msg_font_col = lock_msg_x_off[3:1];
    wire [7:0] lock_msg_char_code = lock_msg_char(lock_msg_char_idx);
    wire [7:0] lock_msg_pixels;
    wire       lock_msg_pixel_lit = in_lock_msg && lock_msg_pixels[3'd7 - lock_msg_font_col];

    // ------------------------------------------------------------------
    // Now Playing effects 2/3 (Section 30/31, reworked Section 32):
    //   1 = Still Thumbnail: static album art, centered alone, with a large
    //       play/pause icon below it (per plans/Now_Playing_Tab.drawio.png -
    //       this is what Section 30's original centered thumbnail already
    //       was; Section 31 had mistakenly folded it into the vinyl effect).
    //   2 = Spinning Vinyl: album art + a partially-hidden vinyl disc,
    //       centered TOGETHER as one unit (was left-aligned in Section 31).
    // Both reuse the same 172x172 track_thumb_ram image/read port; only the X
    // position differs (thumb_x_start_eff below). track_thumb_ram's read is
    // registered (M10K, 1-cycle latency), so - same trick as ImageViewer's
    // framebuffer_ram - it's addressed with the pixel that will be needed on
    // the NEXT clk_core_12288 cycle, one cycle ahead of vidout_rgb. That
    // same shared read port also serves the Library tab's small per-row icon
    // (added Section 32) - safe because NowPlaying and Library are never
    // the active tab at the same time.
    // ------------------------------------------------------------------
    localparam [9:0] THUMB_W       = 10'd172;
    localparam [9:0] THUMB_H       = 10'd172;
    localparam [9:0] THUMB_Y_START = OSC_Y_TOP + 10'd1;    // = 9, fills box height exactly
    // Still Thumbnail: thumbnail alone centered in the 360px-wide art area.
    localparam [9:0] THUMB_X_STILL    = OSC_X_START + 10'd94; // = 114
    // Spinning Vinyl: disc center sits exactly at the thumbnail's right edge
    // (so it hides exactly the left HALF of the circle, by symmetry), and
    // the combined thumbnail+visible-disc-half shape (172+80=252px wide) is
    // centered as a unit: margin = (360-252)/2 = 54.
    localparam [9:0] THUMB_X_SPINNING = OSC_X_START + 10'd54; // = 74
    // Section 43: Full Art - the SAME 172x172 source image, displayed at 2x
    // pixel size (344x344, nearest-neighbor doubled - not a higher-res
    // source) per user request, centered on the 400x360 active area. The
    // thin leftover margin (28px sides, 8px top/bottom) intentionally still
    // shows the existing blurred background behind it, same as the other
    // two effects already do around their own (smaller) art area - not
    // suppressed here.
    localparam [9:0] FULLART_W       = 10'd344;
    localparam [9:0] FULLART_H       = 10'd344;
    localparam [9:0] FULLART_X_START = 10'd28; // (400-344)/2
    localparam [9:0] FULLART_Y_START = 10'd8;  // (360-344)/2
    wire [9:0] thumb_x_start_eff = (effect_mode_vid == EFFECT_SPINNING_VINYL) ? THUMB_X_SPINNING :
                                    (effect_mode_vid == EFFECT_FULL_ART)      ? FULLART_X_START :
                                                                                 THUMB_X_STILL;
    wire [9:0] thumb_y_start_eff = (effect_mode_vid == EFFECT_FULL_ART) ? FULLART_Y_START : THUMB_Y_START;
    wire [9:0] thumb_w_eff       = (effect_mode_vid == EFFECT_FULL_ART) ? FULLART_W : THUMB_W;
    wire [9:0] thumb_h_eff       = (effect_mode_vid == EFFECT_FULL_ART) ? FULLART_H : THUMB_H;
    // All three effects use the thumbnail (Oscilloscope removed), so this
    // simplifies to just the tab check.
    wire       thumb_effect_active = (cur_tab_vid == 2'd0);

    wire [9:0] next_x_count = (x_count == VID_H_TOTAL-1) ? 10'd0 : (x_count + 10'd1);
    wire [9:0] next_y_count = (x_count == VID_H_TOTAL-1)
                                ? ((y_count == VID_V_TOTAL-1) ? 10'd0 : (y_count + 10'd1))
                                : y_count;
    wire [9:0] next_visible_x = next_x_count - VID_H_BPORCH;
    wire [9:0] next_visible_y = next_y_count - VID_V_BPORCH;

    wire next_in_thumb = thumb_effect_active &&
                         (next_visible_x >= thumb_x_start_eff) && (next_visible_x < thumb_x_start_eff + thumb_w_eff) &&
                         (next_visible_y >= thumb_y_start_eff) && (next_visible_y < thumb_y_start_eff + thumb_h_eff);

    // thumb_rd_addr: NowPlaying Still Thumbnail/Spinning Vinyl/Full Art only
    // now - Section 39 gave the Library's per-row icon its own dedicated
    // read port (row_icon_rd_addr below, on track_thumb_ram's separate
    // 8-slot cache), so there's no more sharing/muxing needed here.
    // Section 43: Full Art divides the on-screen local offset by 2 before
    // the same row*172+col lookup - every 2x2 screen block reads one source
    // pixel (nearest-neighbor 2x). Still/Vinyl keep the original 1:1 address.
    wire [9:0] thumb_local_x = next_visible_x - thumb_x_start_eff;
    wire [9:0] thumb_local_y = next_visible_y - thumb_y_start_eff;
    wire [9:0] thumb_src_x   = (effect_mode_vid == EFFECT_FULL_ART) ? thumb_local_x[9:1] : thumb_local_x;
    wire [9:0] thumb_src_y   = (effect_mode_vid == EFFECT_FULL_ART) ? thumb_local_y[9:1] : thumb_local_y;
    wire [14:0] thumb_rd_addr = next_in_thumb
        ? (thumb_src_y * 15'd172 + thumb_src_x)
        : 15'd0;

    // Section 39: Library per-row thumbnail icon addressing - DIRECT 1:1
    // lookup, no downscaling (the source image is already pre-scaled to
    // exactly LIST_ICON_SIZE on the PC, unlike the old single-shared-icon
    // design this replaced, which downscaled from the full 172x172 sharp
    // image on every read). "Next" coordinates for the same 1-cycle
    // registered-read-latency reason as next_in_thumb above; row_icon_mem
    // is addressed as {screen row 0..7, pixel offset within that row's
    // icon} - see track_thumb_ram.sv/audio_streamer.sv for how each row's
    // slot gets filled.
    wire [9:0] next_list_y_off    = next_visible_y - LIST_Y_START;
    wire [9:0] next_list_row_full = next_list_y_off / LIST_ROW_H;
    wire [2:0] next_list_row      = next_list_row_full[2:0];
    wire [9:0] next_list_row_top  = next_list_row_full * LIST_ROW_H;
    wire [9:0] next_list_y_local  = next_list_y_off - next_list_row_top;
    wire [9:0] next_list_icon_x_off = next_visible_x - LIST_ICON_X;      // 0..29 when in range
    wire [9:0] next_list_icon_y_off = next_list_y_local - LIST_ICON_PAD_Y; // 0..29 when in range
    // row_icon_rd_addr = row*900 + (y_off*30 + x_off); 900=30*30 is a
    // compile-time constant so this is a cheap constant multiply, same
    // reasoning as list_row_full*LIST_ROW_H above. Explicit intermediate
    // widths throughout to avoid relying on Verilog's self-determined-width
    // inference inside larger expressions.
    wire [12:0] row_icon_slot_base = {10'b0, next_list_row} * 13'd900; // 0..6300
    wire [9:0]  row_icon_px_off    = next_list_icon_y_off * 10'd30 + next_list_icon_x_off; // 0..899
    wire [12:0] row_icon_rd_addr   = row_icon_slot_base + {3'b0, row_icon_px_off};

    wire [15:0] thumb_pixel;
    wire       in_thumb_area = thumb_effect_active &&
                               (visible_x >= thumb_x_start_eff) && (visible_x < thumb_x_start_eff + thumb_w_eff) &&
                               (visible_y >= thumb_y_start_eff) && (visible_y < thumb_y_start_eff + thumb_h_eff);
    // RGB565 -> RGB888 (bit replication), same technique as ImageViewer's framebuffer.
    wire [4:0] thumb_r5 = thumb_pixel[15:11];
    wire [5:0] thumb_g6 = thumb_pixel[10:5];
    wire [4:0] thumb_b5 = thumb_pixel[4:0];
    wire [23:0] thumb_rgb888 = {thumb_r5, thumb_r5[4:2], thumb_g6, thumb_g6[5:4], thumb_b5, thumb_b5[4:2]};

    // Section 39: Library per-row icon pixel, own dedicated read port (see
    // row_icon_rd_addr above).
    wire [15:0] row_icon_pixel;
    wire [4:0] row_icon_r5 = row_icon_pixel[15:11];
    wire [5:0] row_icon_g6 = row_icon_pixel[10:5];
    wire [4:0] row_icon_b5 = row_icon_pixel[4:0];
    wire [23:0] row_icon_rgb888 = {row_icon_r5, row_icon_r5[4:2], row_icon_g6, row_icon_g6[5:4], row_icon_b5, row_icon_b5[4:2]};

    // Section 35: per-track background (own dedicated read port on
    // track_thumb_ram - unlike thumb_rd_addr above, never shared with the
    // Library icon, so no priority mux needed).
    // Section 37/38 tried a plain nearest-neighbor upscale (Section 37) then
    // doubled resolution + more blur (Section 38) then PC-side film-grain
    // dithering (Section 39, reverted - see tools/convert_audio.py, it came
    // out chromatic/wrong-looking) to fight the same underlying "visible
    // color blocks" complaint. Section 40 fixes it properly instead: real
    // BILINEAR interpolation on the FPGA side, so there's no hard block
    // edge left to hide from at all. Resolution stays 100x90 (BG_W/BG_H,
    // unchanged - no MORE BRAM for the source image itself, per the user's
    // explicit "without using more resources" constraint).
    //
    // How it avoids costing more M10K/BRAM: bilinear needs the 4 pixels
    // surrounding each output position (2 source rows x 2 columns) all
    // available at once, which a single-address M10K port can't do in one
    // cycle. Instead of a wider/multi-port memory, two small ROW BUFFERS
    // (bg_buf_top/bg_buf_bot, 100 entries x 16 bits = 1600 bits each) hold
    // a full source row apiece - `ramstyle="logic"` forces Quartus to
    // implement them as plain registers/LUTRAM, NOT M10K, so this costs
    // LUTs, not the tight block-memory budget Sections 33/34/38 have
    // already had to watch closely. Register arrays support unlimited
    // COMBINATIONAL read "ports" (unlike M10K's real port limit), so once a
    // row is buffered, reading buf[x] AND buf[x+1] in the same cycle for
    // horizontal blending is free - no addressing tricks needed for that
    // part.
    //
    // Fill mechanism: whenever the on-screen row-group changes (every 4
    // scanlines, since bg_row_now = visible_y/4 - includes the frame-wrap
    // from row 89 back to row 0, no special-casing needed since the trigger
    // only cares that the value CHANGED), both buffers are reloaded fresh
    // from track_thumb_ram's single registered bg_mem port: row_now into
    // bg_buf_top (~101 cycles), then row_now+1 (clamped at the image's last
    // row - standard edge-clamp, so the bottom edge just repeats itself
    // instead of needing off-image data) into bg_buf_bot (~101 more). A
    // group lasts ~2048 clk_core_12288 cycles, so this ~202-cycle reload
    // finishes with ~90% margin to spare.
    //
    // KNOWN TRADE-OFF, deliberately accepted rather than risk a more complex
    // redesign without any way to simulate/verify it first: bg_buf_top is
    // being actively overwritten (one pixel at a time) WHILE it's also being
    // read for display during that same ~101-cycle window, and bg_buf_bot
    // still holds 2-groups-old data until its own reload starts right after
    // - so roughly the first ~40% of the FIRST scanline of EVERY 4-line
    // band may blend from an inconsistent mix of old/new row data, not a
    // clean snapshot. Because the timing is deterministic, this could show
    // as a faint, CONSISTENT (not random) horizontal seam/banding pattern
    // repeating every 4 scanlines, not just a one-time startup blip -
    // please specifically check for this on the next hardware test. The
    // proper fix, if it's actually visible, is a double-buffered design
    // (fill a fully-separate "back" pair one whole group ahead of when it's
    // needed, then swap a single front/back select bit at the group
    // boundary instead of overwriting the buffer currently being
    // displayed) - sketched out but NOT implemented this round: getting
    // its bootstrap-at-reset edge case right by hand, with no simulation
    // able to verify pixel-level timing, was a real risk of trading this
    // known/bounded imperfection for a worse, less-understood bug. Worth
    // revisiting as its own focused round if this turns out to actually be
    // visible on hardware.
    // Must match track_thumb_ram/audio_streamer's BG_W/BG_H instantiation
    // parameters below - not passed in, just kept consistent by hand (same
    // convention already used for LIST_ICON_SIZE matching ROW_ICON_W/H, etc).
    localparam [6:0] BG_W     = 7'd100;
    localparam [6:0] BG_H     = 7'd90;
    localparam [6:0] BG_H_M1  = BG_H - 7'd1; // 89, last valid source row

    (* ramstyle = "logic" *) reg [15:0] bg_buf_top [0:BG_W-1];
    (* ramstyle = "logic" *) reg [15:0] bg_buf_bot [0:BG_W-1];
    reg [6:0] bg_disp_row_prev;
    reg [6:0] bg_load_row;
    reg       bg_load_phase;   // 0 = filling bg_buf_top, 1 = filling bg_buf_bot
    reg [6:0] bg_load_col;     // 0..100 issuing/capturing; >100 = idle

    wire [6:0] bg_row_now       = visible_y[8:2]; // 0..89 in active video; only used there (see below)
    wire       bg_row_changed   = (bg_row_now != bg_disp_row_prev);
    wire       bg_load_issuing  = (bg_load_col < 7'd100);
    wire       bg_load_capturing = (bg_load_col >= 7'd1) && (bg_load_col <= 7'd100);
    wire       bg_load_phase_done = (bg_load_col == 7'd100); // one-cycle pulse

    wire [13:0] bg_rd_addr = bg_load_issuing
        ? (({7'b0, bg_load_row} * 14'd100) + {7'b0, bg_load_col})
        : 14'd0;
    wire [15:0] bg_pixel;

    // Bilinear sample/blend for the CURRENT output pixel (combinational -
    // reads whatever bg_buf_top/bot currently hold, no "next" addressing
    // needed since these are plain register-array reads, not a registered
    // M10K port). visible_x/y's low 2 bits are the 1/4-step fractional
    // position; the top 7 bits (after >>2) are the integer column, already
    // matching bg_buf_top/bot's own indexing.
    wire [6:0] bg_x0 = visible_x[8:2];
    wire [1:0] bg_fx = visible_x[1:0];
    wire [1:0] bg_fy = visible_y[1:0];
    wire [6:0] bg_x1 = (bg_x0 >= (BG_W-1)) ? (BG_W-1) : (bg_x0 + 7'd1); // clamp right edge

    wire [15:0] bg_p00 = bg_buf_top[bg_x0];
    wire [15:0] bg_p10 = bg_buf_top[bg_x1];
    wire [15:0] bg_p01 = bg_buf_bot[bg_x0];
    wire [15:0] bg_p11 = bg_buf_bot[bg_x1];

    wire [4:0] bg_r00 = bg_p00[15:11], bg_r10 = bg_p10[15:11], bg_r01 = bg_p01[15:11], bg_r11 = bg_p11[15:11];
    wire [5:0] bg_g00 = bg_p00[10:5],  bg_g10 = bg_p10[10:5],  bg_g01 = bg_p01[10:5],  bg_g11 = bg_p11[10:5];
    wire [4:0] bg_b00 = bg_p00[4:0],   bg_b10 = bg_p10[4:0],   bg_b01 = bg_p01[4:0],   bg_b11 = bg_p11[4:0];

    // Bilinear weights, in 1/4 steps (0..4 each); the 4 corner weights
    // always sum to exactly 4*4=16, so a plain >>4 at the end exactly
    // normalizes back to each channel's native range - no rounding logic
    // needed.
    wire [2:0] bg_wx0 = 3'd4 - {1'b0, bg_fx};
    wire [2:0] bg_wx1 = {1'b0, bg_fx};
    wire [2:0] bg_wy0 = 3'd4 - {1'b0, bg_fy};
    wire [2:0] bg_wy1 = {1'b0, bg_fy};
    wire [4:0] bg_w00 = bg_wx0 * bg_wy0; // max 4*4=16
    wire [4:0] bg_w10 = bg_wx1 * bg_wy0;
    wire [4:0] bg_w01 = bg_wx0 * bg_wy1;
    wire [4:0] bg_w11 = bg_wx1 * bg_wy1;

    wire [8:0] bg_r_sum = bg_w00*bg_r00 + bg_w10*bg_r10 + bg_w01*bg_r01 + bg_w11*bg_r11; // max 16*31=496
    wire [9:0] bg_g_sum = bg_w00*bg_g00 + bg_w10*bg_g10 + bg_w01*bg_g01 + bg_w11*bg_g11; // max 16*63=1008
    wire [8:0] bg_b_sum = bg_w00*bg_b00 + bg_w10*bg_b10 + bg_w01*bg_b01 + bg_w11*bg_b11; // max 496
    wire [4:0] bg_r5 = bg_r_sum[8:4];
    wire [5:0] bg_g6 = bg_g_sum[9:4];
    wire [4:0] bg_b5 = bg_b_sum[8:4];
    wire [23:0] bg_rgb888 = {bg_r5, bg_r5[4:2], bg_g6, bg_g6[5:4], bg_b5, bg_b5[4:2]};

    // ------------------------------------------------------------------
    // Large play/pause icon (32x32), centered below the box/thumbnail/vinyl
    // area. Section 35: now shown in ALL THREE NowPlaying effects (was Still
    // Thumbnail only - Oscilloscope/Spinning Vinyl had a separate, smaller
    // 16x16 icon; that path is retired). Bitmap definitions (play_bmp_row/
    // PAUSE_BMP) are declared further above, alongside the old small-icon
    // block they replaced.
    // ------------------------------------------------------------------
    localparam [9:0] BIGICON_X_4X = 10'd184; // centered: (400-32)/2
    localparam [9:0] BIGICON_Y_4X = 10'd224; // = OSC_Y_BOTBRD+1+26 (see OSC_Y_TOP comment above)
    // Section 43: no play/pause icon overlay in Full Art mode.
    wire in_big_icon = (cur_tab_vid == 2'd0) && (effect_mode_vid != EFFECT_FULL_ART) &&
                       (visible_x >= BIGICON_X_4X) && (visible_x < BIGICON_X_4X + 10'd32) &&
                       (visible_y >= BIGICON_Y_4X) && (visible_y < BIGICON_Y_4X + 10'd32);
    wire [9:0] big_icon_x_off = visible_x - BIGICON_X_4X;
    wire [9:0] big_icon_y_off = visible_y - BIGICON_Y_4X;

    // ------------------------------------------------------------------
    // Section 35 follow-up: repeat/shuffle indicator dots, per
    // plans/UI_SPEC.md (left dot = repeat state, right dot = shuffle state) -
    // simplified to solid squares (bright = on, dim = off) rather than the
    // spec's outline/transparent styling, and shown in both remaining
    // effects (not just Still Thumbnail) to match Section 35's "same icon in
    // every effect" pattern.
    // Section 36 follow-up: repositioned per feedback to flank the
    // play/pause icon horizontally (same vertical center as the icon)
    // instead of sitting below it - centered at 1/6 and 5/6 of the 400px
    // screen width (x=66.7/333.3), vertically centered on the 32px icon
    // (224 + (32-8)/2 = 236).
    // ------------------------------------------------------------------
    // Section 37 follow-up: shown ONLY in Spinning Vinyl now (was both
    // effects) - user wants the Still Thumbnail screen to stay simple/clean.
    localparam [9:0] IND_SIZE      = 10'd8;
    localparam [9:0] IND_Y_START   = BIGICON_Y_4X + (10'd32 - IND_SIZE) / 10'd2; // = 236
    localparam [9:0] IND_REPEAT_X  = 10'd63;  // center ~66.7 (400/6)
    localparam [9:0] IND_SHUFFLE_X = 10'd329; // center ~333.3 (400*5/6)
    wire in_repeat_ind  = (cur_tab_vid == 2'd0) && (effect_mode_vid == EFFECT_SPINNING_VINYL) &&
                          (visible_x >= IND_REPEAT_X) && (visible_x < IND_REPEAT_X + IND_SIZE) &&
                          (visible_y >= IND_Y_START) && (visible_y < IND_Y_START + IND_SIZE);
    wire in_shuffle_ind = (cur_tab_vid == 2'd0) && (effect_mode_vid == EFFECT_SPINNING_VINYL) &&
                          (visible_x >= IND_SHUFFLE_X) && (visible_x < IND_SHUFFLE_X + IND_SIZE) &&
                          (visible_y >= IND_Y_START) && (visible_y < IND_Y_START + IND_SIZE);

    // ------------------------------------------------------------------
    // Vinyl disc (Spinning Vinyl only): drawn procedurally (circle/ring/
    // label distance tests, no image data needed). Groove-ring radii/style
    // (3 thin rings) match tools/make_default_thumb.py's vinyl-icon drawing,
    // but colored close to the disc's own black (real vinyl grooves are a
    // subtle texture, not a bright ring) - previously used the much lighter
    // COLOR_BORDER, which read as a flat gray ring instead of a groove
    // texture. Label color is a placeholder match to the default thumbnail's
    // accent (see tools/make_default_thumb.py) - true per-album color
    // extraction needs real per-track art (deferred, see notes).
    // ------------------------------------------------------------------
    localparam signed [10:0] DISC_CX = $signed({1'b0, THUMB_X_SPINNING}) + 11'sd172; // = 246, thumbnail's right edge
    // Section 35: derived from THUMB_Y_START (was hardcoded 95, assuming the
    // old OSC_Y_TOP=8) so the disc stays vertically centered on the
    // thumbnail (172/2=86) after the top-gap widening.
    localparam signed [10:0] DISC_CY = $signed({1'b0, THUMB_Y_START}) + 11'sd86;
    localparam signed [10:0] DISC_R  = 11'sd80;
    localparam signed [21:0] DISC_R_SQ    = 22'sd6400;  // 80^2
    localparam signed [21:0] GROOVE1_R_SQ = 22'sd4624;  // 68^2
    localparam signed [21:0] GROOVE2_R_SQ = 22'sd2916;  // 54^2
    localparam signed [21:0] GROOVE3_R_SQ = 22'sd1600;  // 40^2
    localparam signed [21:0] LABEL_R_SQ   = 22'sd784;   // 28^2
    localparam signed [21:0] HOLE_R_SQ    = 22'sd36;    // 6^2
    localparam signed [21:0] GROOVE_BAND  = 22'sd130;   // squared-distance band half-width (thin, ~1px)
    localparam [23:0] COLOR_GROOVE = 24'h14141C; // near-black, subtle texture (was COLOR_BORDER - too bright)
    localparam [23:0] COLOR_LABEL  = 24'h4A4E57; // matches the default thumbnail's grey accent (see make_default_thumb.py)

    wire signed [10:0] visible_x_s = $signed({1'b0, visible_x});
    wire signed [10:0] visible_y_s = $signed({1'b0, visible_y});
    wire signed [10:0] disc_dx = visible_x_s - DISC_CX;
    wire signed [10:0] disc_dy = visible_y_s - DISC_CY;
    wire signed [21:0] disc_dist_sq = disc_dx*disc_dx + disc_dy*disc_dy;

    wire in_disc     = (cur_tab_vid == 2'd0) && (effect_mode_vid == EFFECT_SPINNING_VINYL) && (disc_dist_sq <= DISC_R_SQ);
    wire in_label    = disc_dist_sq <= LABEL_R_SQ;
    wire in_hole     = disc_dist_sq <= HOLE_R_SQ;
    wire in_groove   = ((disc_dist_sq <= GROOVE1_R_SQ + GROOVE_BAND) && (disc_dist_sq >= GROOVE1_R_SQ - GROOVE_BAND)) ||
                        ((disc_dist_sq <= GROOVE2_R_SQ + GROOVE_BAND) && (disc_dist_sq >= GROOVE2_R_SQ - GROOVE_BAND)) ||
                        ((disc_dist_sq <= GROOVE3_R_SQ + GROOVE_BAND) && (disc_dist_sq >= GROOVE3_R_SQ - GROOVE_BAND));

    // Rotating reflection: TWO wedges 180 degrees apart (rot_idx and
    // rot_idx+8 - the +8 wraps automatically in 4-bit arithmetic, exactly
    // half of the 16-step/22.5-degree table). rot_cos/rot_sin come from a
    // 16-step ROM; "along" must be positive (correct half of the disc) and
    // "perp" small relative to "along" (narrow wedge, ~14 degree half-angle
    // via the >>>2 shift - halved from the original >>>1/~26 degrees per
    // Section 35 follow-up feedback that the reflection read too thick).
    reg  [3:0] rot_idx;
    reg  [3:0] rot_div;
    localparam ROT_DIV_MAX = 4'd15; // 16 vsyncs/step, ~4.3s per full rotation @60fps
    wire [3:0] rot_idx2 = rot_idx + 4'd8; // opposite side

    function signed [7:0] rot_cos_f;
        input [3:0] idx;
        begin
            case (idx)
                4'd0:  rot_cos_f =  8'sd127;
                4'd1:  rot_cos_f =  8'sd117;
                4'd2:  rot_cos_f =  8'sd90;
                4'd3:  rot_cos_f =  8'sd49;
                4'd4:  rot_cos_f =  8'sd0;
                4'd5:  rot_cos_f = -8'sd49;
                4'd6:  rot_cos_f = -8'sd90;
                4'd7:  rot_cos_f = -8'sd117;
                4'd8:  rot_cos_f = -8'sd127;
                4'd9:  rot_cos_f = -8'sd117;
                4'd10: rot_cos_f = -8'sd90;
                4'd11: rot_cos_f = -8'sd49;
                4'd12: rot_cos_f =  8'sd0;
                4'd13: rot_cos_f =  8'sd49;
                4'd14: rot_cos_f =  8'sd90;
                default: rot_cos_f = 8'sd117; // 4'd15
            endcase
        end
    endfunction

    function signed [7:0] rot_sin_f;
        input [3:0] idx;
        begin
            case (idx)
                4'd0:  rot_sin_f =  8'sd0;
                4'd1:  rot_sin_f =  8'sd49;
                4'd2:  rot_sin_f =  8'sd90;
                4'd3:  rot_sin_f =  8'sd117;
                4'd4:  rot_sin_f =  8'sd127;
                4'd5:  rot_sin_f =  8'sd117;
                4'd6:  rot_sin_f =  8'sd90;
                4'd7:  rot_sin_f =  8'sd49;
                4'd8:  rot_sin_f =  8'sd0;
                4'd9:  rot_sin_f = -8'sd49;
                4'd10: rot_sin_f = -8'sd90;
                4'd11: rot_sin_f = -8'sd117;
                4'd12: rot_sin_f = -8'sd127;
                4'd13: rot_sin_f = -8'sd117;
                4'd14: rot_sin_f = -8'sd90;
                default: rot_sin_f = -8'sd49; // 4'd15
            endcase
        end
    endfunction

    wire signed [7:0]  rot_cos = rot_cos_f(rot_idx);
    wire signed [7:0]  rot_sin = rot_sin_f(rot_idx);
    wire signed [21:0] refl_along = disc_dx*rot_cos + disc_dy*rot_sin;
    wire signed [21:0] refl_perp  = disc_dx*rot_sin - disc_dy*rot_cos;
    wire refl_wedge = (refl_along > 0) &&
                      (refl_perp < (refl_along >>> 2)) &&
                      (refl_perp > -(refl_along >>> 2));

    wire signed [7:0]  rot_cos2 = rot_cos_f(rot_idx2);
    wire signed [7:0]  rot_sin2 = rot_sin_f(rot_idx2);
    wire signed [21:0] refl_along2 = disc_dx*rot_cos2 + disc_dy*rot_sin2;
    wire signed [21:0] refl_perp2  = disc_dx*rot_sin2 - disc_dy*rot_cos2;
    wire refl_wedge2 = (refl_along2 > 0) &&
                       (refl_perp2 < (refl_along2 >>> 2)) &&
                       (refl_perp2 > -(refl_along2 >>> 2));

    wire disc_reflection_lit = in_disc && !in_label && (refl_wedge || refl_wedge2);

always @(posedge clk_core_12288 or negedge reset_n) begin

    if(~reset_n) begin

        x_count           <= 0;
        y_count           <= 0;
        bar_fill_x_s1     <= 0;
        bar_fill_x        <= 0;
        track_sel_s1      <= 9'd0;
        track_sel_vid     <= 9'd0;
        cur_tab_s1        <= 2'd0;
        cur_tab_vid       <= 2'd0;
        cur_tab_vid_prev  <= 2'd0;
        track_sel_vid_prev <= 9'd0;
        ticker_offset     <= 6'd0;
        ticker_div        <= 5'd0;
        ticker_state      <= 2'd0;
        ticker_hold_ctr   <= 8'd0;
        list_cursor_vid_prev <= 9'd0;
        sel_title_len       <= 7'd0;
        lib_ticker_offset    <= 7'd0;
        lib_ticker_hold_ctr  <= 8'd0;
        lib_ticker_state     <= 2'd0;
        lib_ticker_div       <= 5'd0;
        bg_disp_row_prev  <= 7'd0;
        bg_load_row       <= 7'd0;
        bg_load_phase     <= 1'b0;
        bg_load_col       <= 7'd0;
        rot_idx           <= 4'd0;
        rot_div           <= 4'd0;
        lock_on_vid_prev  <= 1'b0;
        lock_msg_timer    <= 8'd0;
        lock_msg_showing  <= 1'b0;
        lock_msg_is_lock  <= 1'b0;

    end else begin
        vidout_de <= 0;
        vidout_skip <= 0;
        vidout_vs <= 0;
        vidout_hs <= 0;
        
        vidout_hs_1 <= vidout_hs;
        vidout_de_1 <= vidout_de;
        
        // x and y counters
        x_count <= x_count + 1'b1;
        if(x_count == VID_H_TOTAL-1) begin
            x_count <= 0;
            
            y_count <= y_count + 1'b1;
            if(y_count == VID_V_TOTAL-1) begin
                y_count <= 0;
            end
        end
        
        // generate sync 
        if(x_count == 0 && y_count == 0) begin
            // sync signal in back porch
            // new frame
            vidout_vs <= 1;
            frame_count <= frame_count + 1'b1;
        end
        
        // we want HS to occur a bit after VS, not on the same cycle
        if(x_count == 3) begin
            // sync signal in back porch
            // new line
            vidout_hs <= 1;
        end

        // sync progress bar fill width from clk_74a into clk_core_12288
        bar_fill_x_s1 <= bar_fill_x_74a;
        bar_fill_x    <= bar_fill_x_s1;

        // sync track_sel, cur_tab from clk_74a for display
        track_sel_s1    <= track_sel;
        track_sel_vid   <= track_sel_s1;
        cur_tab_s1       <= cur_tab;
        cur_tab_vid      <= cur_tab_s1;

        // Section 40: latch the selected Library row's title length
        // whenever it's the row actually being scanned right now (lib_idx
        // == list_cursor_vid at that moment) - lib_title_le only reflects
        // ONE row's data at a time (whichever the scan position currently
        // addresses), so this has to be captured opportunistically rather
        // than read fresh at the vsync boundary below. Holds its last value
        // the rest of the frame; the selected row is always on-screen (the
        // scroll logic guarantees it), so this updates at least once/frame.
        if (row_selected)
            sel_title_len <= lib_title_len_c;

        // Section 40: background row-buffer fill progression - runs every
        // cycle regardless of tab/effect (harmless if nothing ever reads
        // the result), capturing bg_pixel (1-cycle-latency result for the
        // address issued last cycle) into whichever buffer bg_load_phase
        // currently targets.
        if (bg_load_capturing) begin
            if (!bg_load_phase)
                bg_buf_top[bg_load_col - 7'd1] <= bg_pixel;
            else
                bg_buf_bot[bg_load_col - 7'd1] <= bg_pixel;
        end
        if (bg_load_phase_done) begin
            if (!bg_load_phase) begin
                // Top row done - start filling bottom (row_now+1, clamped).
                bg_load_phase <= 1'b1;
                bg_load_row   <= (bg_disp_row_prev >= BG_H_M1) ? BG_H_M1 : (bg_disp_row_prev + 7'd1);
                bg_load_col   <= 7'd0;
            end else begin
                // Bottom row done - go idle until the next row-group trigger.
                bg_load_col <= 7'd101;
            end
        end else if (bg_load_col <= 7'd100) begin
            bg_load_col <= bg_load_col + 7'd1;
        end

        // title ticker: hold-scroll-hold-loop (see comments above). Resets
        // to HOLD_START at offset 0 when the track or tab changes (new
        // title now showing). Compares against snapshots taken at the
        // previous vsync (not the fast-clock sync regs above, which only
        // differ for one cycle).
        if (x_count == 10'd0 && y_count == 10'd0) begin
            cur_tab_vid_prev   <= cur_tab_vid;
            track_sel_vid_prev <= track_sel_vid;
            if (!active_ticker || track_sel_vid != track_sel_vid_prev || cur_tab_vid != cur_tab_vid_prev) begin
                ticker_offset   <= 6'd0;
                ticker_div      <= 5'd0;
                ticker_state    <= 2'd0;
                ticker_hold_ctr <= 8'd0;
            // Section 43: screensaver freezes the ticker in place (a purely
            // cosmetic counter, safe to pause) rather than continuing to
            // advance on a blanked screen.
            end else if (!screensaver_vid) case (ticker_state)
                2'd0: begin // HOLD_START: sit at offset 0 for ~1s.
                    if (ticker_hold_ctr == TICKER_HOLD_VSYNCS - 8'd1) begin
                        ticker_hold_ctr <= 8'd0;
                        ticker_state    <= 2'd1;
                    end else begin
                        ticker_hold_ctr <= ticker_hold_ctr + 8'd1;
                    end
                end
                2'd1: begin // SCROLL: advance until the title's last char
                            // reaches the rightmost visible slot.
                    if (ticker_div == 5'd31) begin
                        ticker_div <= 5'd0;
                        if ({1'b0, ticker_offset} >= ticker_max_offset) begin
                            ticker_state    <= 2'd2;
                            ticker_hold_ctr <= 8'd0;
                        end else begin
                            ticker_offset <= ticker_offset + 6'd1;
                        end
                    end else begin
                        ticker_div <= ticker_div + 5'd1;
                    end
                end
                default: begin // 2'd2 HOLD_END: sit at max offset for ~1s,
                                // then loop back to the start and hold.
                    if (ticker_hold_ctr == TICKER_HOLD_VSYNCS - 8'd1) begin
                        ticker_hold_ctr <= 8'd0;
                        ticker_offset   <= 6'd0;
                        ticker_state    <= 2'd0;
                    end else begin
                        ticker_hold_ctr <= ticker_hold_ctr + 8'd1;
                    end
                end
            endcase

            // Library selected-row ticker: same hold-scroll-hold-loop shape
            // as the NowPlaying ticker above. Restarts (back to HOLD_START
            // at offset 0) whenever the cursor moves or the Library tab
            // isn't active - same reset-on-change idea, compared against a
            // previous-vsync snapshot.
            list_cursor_vid_prev <= list_cursor_vid;
            if (!lib_mode || list_cursor_vid != list_cursor_vid_prev) begin
                lib_ticker_offset    <= 7'd0;
                lib_ticker_hold_ctr  <= 8'd0;
                lib_ticker_state     <= 2'd0;
                lib_ticker_div       <= 5'd0;
            // Section 43: same screensaver freeze as the NowPlaying ticker above.
            end else if (!screensaver_vid) case (lib_ticker_state)
                2'd0: begin // HOLD_START. If the title doesn't even need a
                            // ticker (sel_title_len <= LIST_CHARS), this
                            // just harmlessly free-runs forever -
                            // lib_row_ticking gates the visible effect on
                            // the render side regardless.
                    if (lib_ticker_hold_ctr == TICKER_HOLD_VSYNCS - 8'd1) begin
                        lib_ticker_hold_ctr <= 8'd0;
                        lib_ticker_state    <= 2'd1;
                    end else begin
                        lib_ticker_hold_ctr <= lib_ticker_hold_ctr + 8'd1;
                    end
                end
                2'd1: begin // SCROLL: advance until the title's last char
                            // reaches the rightmost visible slot.
                    if (lib_ticker_div == 5'd31) begin
                        lib_ticker_div <= 5'd0;
                        if (lib_ticker_offset >= lib_ticker_max_offset) begin
                            lib_ticker_state    <= 2'd2;
                            lib_ticker_hold_ctr <= 8'd0;
                        end else begin
                            lib_ticker_offset <= lib_ticker_offset + 7'd1;
                        end
                    end else begin
                        lib_ticker_div <= lib_ticker_div + 5'd1;
                    end
                end
                default: begin // 2'd2 HOLD_END: sit at max offset for ~1s,
                                // then loop back to the start and hold.
                    if (lib_ticker_hold_ctr == TICKER_HOLD_VSYNCS - 8'd1) begin
                        lib_ticker_hold_ctr <= 8'd0;
                        lib_ticker_offset   <= 7'd0;
                        lib_ticker_state    <= 2'd0;
                    end else begin
                        lib_ticker_hold_ctr <= lib_ticker_hold_ctr + 8'd1;
                    end
                end
            endcase

            // Spinning Vinyl reflection rotation: advances once per
            // ROT_DIV_MAX+1 vsyncs while the vinyl effect is showing and
            // playback isn't paused - freezes instead of decaying to a stop
            // when paused (simpler than the "physics-based inertia" from
            // plans/UI_SPEC.md; a reasonable first pass, can refine later).
            // Section 43: also freezes while the screensaver is blanked.
            if (effect_mode_vid == EFFECT_SPINNING_VINYL && !paused_vid_s && !screensaver_vid) begin
                if (rot_div == ROT_DIV_MAX) begin
                    rot_div <= 4'd0;
                    rot_idx <= rot_idx + 4'd1;
                end else begin
                    rot_div <= rot_div + 4'd1;
                end
            end

            // Section 44: "LOCKED"/"UNLOCKED" banner timer. Starts on every
            // lock_on_vid transition (captures which message to show), runs
            // for TICKER_HOLD_VSYNCS (~1s) regardless of what lock_on_vid
            // does afterward, then clears.
            lock_on_vid_prev <= lock_on_vid;
            if (lock_on_vid != lock_on_vid_prev) begin
                lock_msg_showing <= 1'b1;
                lock_msg_is_lock <= lock_on_vid;
                lock_msg_timer   <= 8'd0;
            end else if (lock_msg_showing) begin
                if (lock_msg_timer == TICKER_HOLD_VSYNCS - 8'd1)
                    lock_msg_showing <= 1'b0;
                else
                    lock_msg_timer <= lock_msg_timer + 8'd1;
            end
        end

        // inactive screen areas are black
        vidout_rgb <= 24'h0;
        // generate active video
        if(x_count >= VID_H_BPORCH && x_count < VID_H_ACTIVE+VID_H_BPORCH) begin
            if(y_count >= VID_V_BPORCH && y_count < VID_V_ACTIVE+VID_V_BPORCH) begin
                vidout_de <= 1;

                // Section 40: background row-group trigger - visible_y is
                // only meaningful (0..359, no underflow) inside this same
                // Y-gate, so this lives here rather than being computed
                // unconditionally. Self-limits to firing bg_load_row/phase/
                // col's reset for exactly ONE cycle per row-group change:
                // bg_disp_row_prev is updated EVERY cycle this block runs,
                // so bg_row_changed goes false again the very next cycle
                // even though this whole block re-evaluates for all 400
                // x-positions of the scanline (harmless redundancy, not a
                // repeated reset). Placed here (before the trigger check)
                // so it wins over the unconditional fill-progression logic
                // above if both ever coincide on the same cycle.
                bg_disp_row_prev <= bg_row_now;
                if (bg_row_changed) begin
                    bg_load_row   <= bg_row_now;
                    bg_load_phase <= 1'b0;
                    bg_load_col   <= 7'd0;
                end

                // Section 43: screensaver - full black blank, highest
                // priority (checked last so it overrides everything below).
                // bg_disp_row_prev/bg_row_changed above stay UNCONDITIONAL
                // (not wrapped in here) so background image loading keeps
                // running normally while blanked - avoids any stale-image
                // glitch on the frame screensaver turns back off.
                if (!screensaver_vid) begin

                // dark navy background
                vidout_rgb <= 24'h0D0D1A;

                if (effect_mode_vid == EFFECT_SPINNING_VINYL) begin
                    // Spinning Vinyl: deliberately NO box border - just the
                    // per-track background image (Section 35: replaces the
                    // flat navy fill - see bg_rgb888 above), then the album
                    // thumbnail and disc on top, centered as one unit. Layer
                    // order (each overrides the last): background -> black
                    // disc -> groove rings -> rotating reflections -> label
                    // -> spindle hole (shows the background "through" the
                    // disc's center) -> album thumbnail on top (occludes
                    // exactly the disc's left half, by construction - see
                    // DISC_CX above).
                    if (thumb_effect_active)
                        vidout_rgb <= bg_rgb888;
                    if (in_disc)
                        vidout_rgb <= 24'h000000;
                    if (in_disc && in_groove)
                        vidout_rgb <= COLOR_GROOVE;
                    if (disc_reflection_lit)
                        vidout_rgb <= 24'hFFFFFF;
                    if (in_disc && in_label)
                        vidout_rgb <= COLOR_LABEL;
                    if (in_disc && in_hole)
                        vidout_rgb <= bg_rgb888;
                    if (in_thumb_area)
                        vidout_rgb <= thumb_rgb888;
                end else begin
                    // Still Thumbnail: no box either - per-track background
                    // image (Section 35) behind the centered album art + a
                    // large play/pause icon below it (big_icon_lit).
                    if (thumb_effect_active)
                        vidout_rgb <= bg_rgb888;
                    if (in_thumb_area)
                        vidout_rgb <= thumb_rgb888;
                end

                // play/pause icon: 32x32, all three NowPlaying effects (Section 35)
                if (big_icon_lit)
                    vidout_rgb <= 24'hFFFFFF;

                // repeat/shuffle indicator dots (Section 35 follow-up): bright
                // white = on, dim gray = off (repeat_all default on, shuffle
                // default off).
                if (in_repeat_ind)
                    vidout_rgb <= repeat_all_vid ? 24'hFFFFFF : 24'h404050;
                if (in_shuffle_ind)
                    vidout_rgb <= shuffle_on_vid ? 24'hFFFFFF : 24'h404050;

                // track title, 2x scale w/ ticker (NowPlaying only - Section 31
                // removed the Library mini-preview in favor of a full-screen list)
                if (title_pixel_lit)
                    vidout_rgb <= 24'hFFFFFF;

                // artist name, 1x scale (NowPlaying only)
                if (artist_pixel_lit)
                    vidout_rgb <= 24'hFFFFFF;

                // tab header, 2x scale (Library only - Section 40)
                if (hdr_pixel_lit)
                    vidout_rgb <= 24'hFFFFFF;

                // Library track list (Section 30): highlight band on the
                // selected row first, then text on top - dark text on the
                // bright highlighted row so it stays readable, white text
                // elsewhere on the normal dark background.
                if (list_highlight_on)
                    vidout_rgb <= COLOR_HIGHLIGHT;
                if (list_pixel_lit)
                    vidout_rgb <= row_selected ? 24'h0D0D1A : 24'hFFFFFF;
                // per-row thumbnail icon (Section 32, real per-row cache
                // Section 39) - drawn after the highlight/text so it isn't
                // tinted by the highlight color
                if (in_list_icon)
                    vidout_rgb <= row_icon_rgb888;

                // thin separator line above progress bar (NowPlaying only -
                // Section 35: Library no longer shows the bar itself, see
                // in_bar_area above, so the separator above it goes too).
                // Bounded to the bar's own x-margins (19..380) - previously had no
                // x-bound at all, so it stretched across the full screen width
                // (x=0..399) while the bar/box above it were indented, making it
                // look like a stray line reaching both true screen edges.
                if (visible_y == 10'd335 && cur_tab_vid == 2'd0 && effect_mode_vid != EFFECT_FULL_ART &&
                    visible_x >= BAR_X_START && visible_x < BAR_X_END)
                    vidout_rgb <= COLOR_BORDER;

                // progress bar: x=19..380, y=336..343; white regardless of play/pause
                // state (Section 37 follow-up: was amber-when-paused/white-when-playing -
                // user pointed out the play/pause icon already indicates that, so the
                // bar itself no longer needs to encode it).
                if (in_bar_area) begin
                    if (visible_x < bar_fill_x)
                        vidout_rgb <= 24'hFFFFFF;
                    else
                        vidout_rgb <= COLOR_BORDER; // remaining: dark track
                end

                // Section 44: lock banner - highest priority within the
                // normal-render branch, drawn last so it overrides
                // everything above regardless of tab/effect.
                if (lock_msg_pixel_lit)
                    vidout_rgb <= 24'hFFFFFF;

                end else begin
                    vidout_rgb <= 24'h000000;
                end
            end
        end
    end
end




// font ROM: 8x8 pixel glyphs for all printable ASCII. Five instances: title/
// artist (mini "now playing" preview, both tabs), tab header, the Library
// track list, and the lock banner - all can be visible simultaneously
// (different areas/tabs), each needs its own combinational lookup per pixel.
font_rom u_font_title (
    .char_code (title_char_code),
    .row       (title_font_row),
    .pixels    (title_pixels)
);

font_rom u_font_artist (
    .char_code (artist_char_code),
    .row       (artist_font_row),
    .pixels    (artist_pixels)
);

font_rom u_font_tabhdr (
    .char_code (hdr_char_code),
    .row       (hdr_font_row),
    .pixels    (hdr_pixels)
);

font_rom u_font_list (
    .char_code (list_char_code),
    .row       (list_font_row),
    .pixels    (list_pixels)
);

font_rom u_font_lock (
    .char_code (lock_msg_char_code),
    .row       (lock_msg_font_row),
    .pixels    (lock_msg_pixels)
);

// title_ram/artist_ram bridge write handler (clk_74a domain, Section 29).
// Reset initialises to a default so display works before first update
// (real title only refreshes on first track-select/advance event - same
// known boot-text gap as before, deferred to Section 30).
// pram_title/pram_artist become valid one cycle after pram_read_idx_next
// pre-fetches the new row (Section 34: playlist_ram's read is now
// registered) - each _r-delayed branch below (dpad_advance_r, auto_advance_r,
// lib_select_r2) copies the full 64/32 bytes once that settling cycle has
// passed.
integer bi;
always @(posedge clk_74a or negedge reset_n) begin
    if (~reset_n) begin
        track_sel    <= 9'h0;
        list_cursor  <= 9'h0;
        list_scroll  <= 9'h0;
        cur_tab      <= 2'h0;
        btn_shl_r    <= 1'b0;
        btn_shr_r    <= 1'b0;
        btn_up_r     <= 1'b0;
        btn_dn_r     <= 1'b0;
        updn_hold_ctr  <= 26'd0;
        updn_repeating <= 1'b0;
        effect_mode  <= 2'd0;
        boot_refresh_done <= 1'b0;
        title_ram[0]  <= 8'h42; title_ram[1]  <= 8'h4F; // B O
        title_ram[2]  <= 8'h59; title_ram[3]  <= 8'h53; // Y S
        title_ram[4]  <= 8'h20; title_ram[5]  <= 8'h4C; // _ L
        title_ram[6]  <= 8'h49; title_ram[7]  <= 8'h4B; // I K
        title_ram[8]  <= 8'h45; title_ram[9]  <= 8'h20; // E _
        title_ram[10] <= 8'h59; title_ram[11] <= 8'h4F; // Y O
        title_ram[12] <= 8'h55;                          // U
        for (bi = 13; bi < 64; bi = bi + 1) title_ram[bi] <= 8'h20;
        artist_ram[0] <= 8'h49; artist_ram[1] <= 8'h54; // I T
        artist_ram[2] <= 8'h5A; artist_ram[3] <= 8'h59; // Z Y
        for (bi = 4; bi < 32; bi = bi + 1) artist_ram[bi] <= 8'h20;
    end else begin
        // Track-select / title-artist refresh: exactly one of these fires per cycle.
        if (cur_tab == 2'd0 && (dpad_next || dpad_prev)) begin
            track_sel <= dpad_next ? next_track_eff : prev_track_sel;
        end else if (dpad_advance_r) begin
            for (bi = 0; bi < 64; bi = bi + 1) title_ram[bi]  <= pram_title[(63-bi)*8 +: 8];
            for (bi = 0; bi < 32; bi = bi + 1) artist_ram[bi] <= pram_artist[(31-bi)*8 +: 8];
        end else if (auto_advance) begin
            // Natural end of track: advance track_sel; title/artist updated next cycle (auto_advance_r).
            // Section 35 follow-up: unless "stop after all tracks played" is
            // on (repeat_all off) and we just finished the last track in
            // sequence - then stay parked on it instead of wrapping (paused
            // is set from the SAME auto_advance_would_stop condition in the
            // btn_a_r always block below, since `paused` can only be driven
            // from one always block).
            if (!auto_advance_would_stop)
                track_sel <= next_track_eff;
        end else if (auto_advance_r) begin
            // Cycle after track_sel updated: pram_read_idx_next pre-fetched
            // this row last cycle (playlist_ram's registered read), so
            // pram_title/artist are valid here.
            for (bi = 0; bi < 64; bi = bi + 1) title_ram[bi]  <= pram_title[(63-bi)*8 +: 8];
            for (bi = 0; bi < 32; bi = bi + 1) artist_ram[bi] <= pram_artist[(31-bi)*8 +: 8];
        end else if (lib_select_r2) begin
            // One cycle after lib_select_r adopted list_cursor into track_sel:
            // pram_read_idx_next's pre-fetch has landed, so pram_title/artist
            // are correct here. (Previously lib_select_r never refreshed
            // title_ram/artist_ram at all - the newly-selected track played
            // correctly but the displayed title/artist kept showing whatever
            // was there before.)
            for (bi = 0; bi < 64; bi = bi + 1) title_ram[bi]  <= pram_title[(63-bi)*8 +: 8];
            for (bi = 0; bi < 32; bi = bi + 1) artist_ram[bi] <= pram_artist[(31-bi)*8 +: 8];
        end else if (lib_select_r) begin
            // A pressed in Library tab: adopt the browsed track, jump to NowPlaying
            track_sel <= list_cursor;
            cur_tab   <= 2'd0;
        end else if (boot_refresh_r) begin
            // Section 39: fires once, the cycle after reset exit, to replace
            // the hardcoded reset placeholder text below with track_sel's
            // REAL title/artist - fixes a reported boot-time mismatch
            // ("showed a different song than what was actually loaded").
            // pram_title/pram_artist are already valid here with NO extra
            // settling delay needed (unlike the other _r-delayed branches
            // above): pram_read_idx_next's fallback continuously targets
            // track_sel, and track_sel is held at its reset value (0) by
            // this same always block for the entire static boot-load
            // window (reset_n stays low through all of it) - so
            // playlist_ram's registered track_row has already been reading
            // pram[0] continuously for thousands of cycles by the time
            // reset_n actually goes high, not just the one cycle other
            // branches need to wait for.
            for (bi = 0; bi < 64; bi = bi + 1) title_ram[bi]  <= pram_title[(63-bi)*8 +: 8];
            for (bi = 0; bi < 32; bi = bi + 1) artist_ram[bi] <= pram_artist[(31-bi)*8 +: 8];
        end
        // Unconditional (not part of the priority chain above) so it still
        // latches even on a cycle where some higher-priority branch (e.g. a
        // bridge_wr Track-menu write racing the very first cycle) wins instead.
        if (boot_refresh_r) boot_refresh_done <= 1'b1;

        // Shoulder L/R: cycle tabs (independent of the track-select chain above;
        // last write wins if it collides with lib_select_r in the same cycle).
        // Section 40: Album (1) and Playlists (3) removed from the app per
        // user request (never had more than a "COMING SOON" placeholder
        // behind them - see POCKETPLAYER_NOTES.txt history) - both L and R
        // now just toggle between NowPlaying (0) and Library (2), same
        // "only 2 valid values" pattern as effect_mode after the
        // Oscilloscope's removal. cur_tab is kept at 2 bits (not shrunk to
        // 1) since that's a purely cosmetic simplification with no
        // functional benefit and only adds risk of missing a stray
        // 2'd1/2'd3 comparison somewhere.
        if (((cont1_key[8] && !btn_shl_r) || (cont1_key[9] && !btn_shr_r)) && !input_locked)
            cur_tab <= (cur_tab == 2'd0) ? 2'd2 : 2'd0;
        btn_shl_r <= cont1_key[8];
        btn_shr_r <= cont1_key[9];

        // Up/Down: browse Library cursor + scroll (Library tab) or cycle the
        // Now Playing effect (NowPlaying tab - Up/Down is otherwise unused
        // there). Section 32: list_scroll keeps the cursor on-screen within
        // an 8-row visible window over up to 32 tracks - scrolled by the
        // minimum amount needed each step, and reset to match on wraparound.
        // Section 43: do_step_up/do_step_down (declared above) fire on the
        // ORIGINAL press edge exactly as before, PLUS on every long-press
        // auto-repeat tick - the cursor-move logic itself is unchanged
        // either way, it doesn't know or care which triggered it.
        if (cur_tab == 2'd2) begin
            if (do_step_up) begin
                if (list_cursor == 9'd0) begin
                    list_cursor <= last_track_idx;
                    list_scroll <= (last_track_idx >= LIST_VISIBLE_ROWS - 9'd1)
                                   ? (last_track_idx - LIST_VISIBLE_ROWS + 9'd1) : 9'd0;
                end else begin
                    list_cursor <= list_cursor - 9'd1;
                    if ((list_cursor - 9'd1) < list_scroll)
                        list_scroll <= list_cursor - 9'd1;
                end
            end else if (do_step_down) begin
                if (list_cursor == last_track_idx) begin
                    list_cursor <= 9'd0;
                    list_scroll <= 9'd0;
                end else begin
                    list_cursor <= list_cursor + 9'd1;
                    if ((list_cursor + 9'd1) > (list_scroll + LIST_VISIBLE_ROWS - 9'd1))
                        list_scroll <= list_cursor + 9'd1 - LIST_VISIBLE_ROWS + 9'd1;
                end
            end

            // Hold-timer: resets whenever neither key is held; once it
            // crosses the applicable threshold (see updn_thresh_hit above)
            // it fires this cycle's do_step_up/down and restarts counting
            // at the FASTER repeat interval for next time.
            if (!updn_held) begin
                updn_hold_ctr  <= 26'd0;
                updn_repeating <= 1'b0;
            end else if (updn_thresh_hit) begin
                updn_hold_ctr  <= 26'd0;
                updn_repeating <= 1'b1;
            end else begin
                updn_hold_ctr <= updn_hold_ctr + 26'd1;
            end
        end else if (cur_tab == 2'd0) begin
            // Section 43 follow-up: Up and Down previously both advanced
            // forward (a bug - "does the same actions" regardless of which
            // was pressed, e.g. 123123123). Now genuinely bidirectional:
            // Up cycles forward (wraps Full Art -> Still), Down cycles
            // backward (wraps Still -> Full Art), so alternating presses
            // actually reverse direction (e.g. 1232321). No long-press
            // repeat here - a single press-edge step same as always.
            if (cont1_key[0] && !btn_up_r && !input_locked)
                effect_mode <= (effect_mode == EFFECT_FULL_ART) ? EFFECT_STILL_THUMB : effect_mode + 2'd1;
            else if (cont1_key[1] && !btn_dn_r && !input_locked)
                effect_mode <= (effect_mode == EFFECT_STILL_THUMB) ? EFFECT_FULL_ART : effect_mode - 2'd1;
        end
        btn_up_r <= cont1_key[0];
        btn_dn_r <= cont1_key[1];
    end
end

//
// audio i2s playback: looped PCM clip from PSRAM (Module 2b, cram0)
//

assign audio_mclk = audgen_mclk;
assign audio_dac = audgen_dac;
assign audio_lrck = audgen_lrck;

// generate MCLK = 12.288mhz with fractional accumulator
    reg         [21:0]  audgen_accum;
    reg                 audgen_mclk;
    parameter   [20:0]  CYCLE_48KHZ = 21'd122880 * 2;
always @(posedge clk_74a) begin
    audgen_accum <= audgen_accum + CYCLE_48KHZ;
    if(audgen_accum >= 21'd742500) begin
        audgen_mclk <= ~audgen_mclk;
        audgen_accum <= audgen_accum - 21'd742500 + CYCLE_48KHZ;
    end
end

// generate SCLK = 3.072mhz by dividing MCLK by 4
    reg [1:0]   aud_mclk_divider;
    wire        audgen_sclk = aud_mclk_divider[1] /* synthesis keep*/;
    reg         audgen_lrck_1;
always @(posedge audgen_mclk) begin
    aud_mclk_divider <= aud_mclk_divider + 1'b1;
end

// playlist_ram: loads playlist.bin (slot 17) at boot; exposes per-track
// start_chunk, chunk_count, and song_name from a small register file.
// No FPGA recompile needed to add/change tracks - just regenerate the .bin files.
    wire        pram_ds_read;
    wire [15:0] pram_ds_id;
    wire [31:0] pram_ds_slotoffset;
    wire [31:0] pram_ds_bridgeaddr;
    wire [31:0] pram_ds_length;
    wire        playlist_loaded;
    wire [15:0] pram_start;
    wire [15:0] pram_chunks;
    wire [3:0]  pram_audio_bank;
    wire [511:0] pram_title;   // 64 ASCII bytes, big-endian
    wire [255:0] pram_artist;  // 32 ASCII bytes, big-endian
    // Section 34: playlist_ram's track_idx read is now REGISTERED (required
    // for block-RAM inference - see playlist_ram.sv). pram_read_idx_next
    // PREDICTS what track_sel is about to become, one cycle before it
    // actually changes, so the registered read has already fetched the new
    // row by the time external consumers (title_ram/artist_ram refresh via
    // dpad_advance_r/auto_advance_r/lib_select_r2, and audio_streamer's
    // chunk_idx seed) expect it - mirrors the SAME priority chain that
    // updates track_sel further down this file (D-pad prev/next >
    // auto_advance > Library A-select); the fallback (no event this cycle)
    // just re-reads the current track_sel, harmless since the address
    // hasn't changed.
    wire [8:0]  pram_read_idx_next =
        (cur_tab == 2'd0 && (dpad_next || dpad_prev)) ? (dpad_next ? next_track_eff : prev_track_sel) :
        (auto_advance && !auto_advance_would_stop)    ? next_track_eff :
        lib_select_r                                  ? list_cursor :
        track_sel;

    // audio_streamer's dataslot signals (muxed with playlist_ram below).
    // Section 35: audio_streamer is now ALSO the sole requester for
    // per-track album art (see audio_streamer.sv header) - the old
    // thumb_ram module (a separate, boot-once requester for a single
    // shared default image) is retired; track_thumb_ram.sv is a purely
    // passive memory with no dataslot ports of its own.
    wire        as_ds_read;
    wire [15:0] as_ds_id;
    wire [31:0] as_ds_slotoffset;
    wire [31:0] as_ds_bridgeaddr;
    wire [31:0] as_ds_length;

    // Mux: playlist_ram has priority, then audio_streamer. playlist_ram's
    // request is boot-once (S_DONE forever after); audio_streamer waits for
    // playlist_loaded (see its `enable` input below) before its first
    // request - so exactly one of {pram_ds_read, as_ds_read} is ever high
    // at a time.
    assign target_dataslot_read       = pram_ds_read | as_ds_read;
    assign target_dataslot_id         = pram_ds_read ? pram_ds_id         : as_ds_id;
    assign target_dataslot_slotoffset = pram_ds_read ? pram_ds_slotoffset : as_ds_slotoffset;
    assign target_dataslot_bridgeaddr = pram_ds_read ? pram_ds_bridgeaddr : as_ds_bridgeaddr;
    assign target_dataslot_length     = pram_ds_read ? pram_ds_length     : as_ds_length;

    localparam          AUDIO_NUM_SAMPLES = 2097152; // 2^21, ~43.69s @ 48kHz
    localparam          AUDIO_AW          = 21;      // ceil(log2(AUDIO_NUM_SAMPLES))

    wire                initial_fill_done;
    wire                psram_test_done;
    wire                psram_test_pass;
    // initial_fill_done is in clk_74a domain; sync into audgen_sclk before gating audio.
    wire                initial_fill_done_s;
    wire                audio_loaded = initial_fill_done_s && psram_test_pass;

    // slot_consumed_pulse: one clk_74a pulse each time the consumer leaves a ring slot.
    // Toggled in audgen_sclk domain; synchronized into clk_74a via synch_3 + edge detect.
    reg                 slot_consumed_tog;
    wire                slot_consumed_tog_s;
    reg                 slot_consumed_tog_s_r;
    wire                slot_consumed_pulse = slot_consumed_tog_s ^ slot_consumed_tog_s_r;
    reg  [AUDIO_AW-1:0] audio_addr;
    wire [31:0]         audio_frame; // [15:0]=left sample, [31:16]=right sample

    // cur_track_chunks: chunk count for active track, from playlist_ram (combinatorial).
    // Full 16 bits (was [6:0], silently truncating any track over ~5.5 minutes/
    // 127 chunks - found while investigating the wraparound bug; see chunks_played below).
    wire [15:0] cur_track_chunks = pram_chunks;

    // auto_advance: fires for 1 clk_74a cycle when the current track's last chunk is
    // consumed naturally. Guards against cur_track_chunks=0 (pre-boot) and bridge_wr
    // (interact write) coinciding with slot_consumed_pulse.
    wire auto_advance = slot_consumed_pulse && !bridge_wr &&
                        (cur_track_chunks != 16'd0) &&
                        (chunks_played == cur_track_chunks - 16'd1);
    // auto_advance_r: 1-cycle delay so pram_read_idx_next's pre-fetch (issued
    // the cycle auto_advance fired) has landed in playlist_ram's registered
    // read before title_ram/artist_ram are written.
    reg auto_advance_r;
    always @(posedge clk_74a or negedge reset_n) begin
        if (~reset_n) auto_advance_r <= 1'b0;
        else          auto_advance_r <= auto_advance;
    end

    // lib_select_r2: same 1-cycle delay pattern as auto_advance_r above, but
    // for the Library A-select jump (lib_select_r sets track_sel <= list_cursor
    // one cycle earlier; by the time lib_select_r2 fires, pram_read_idx_next's
    // pre-fetch has landed so pram_title/pram_artist are correct).
    always @(posedge clk_74a or negedge reset_n) begin
        if (~reset_n) lib_select_r2 <= 1'b0;
        else          lib_select_r2 <= lib_select_r;
    end

    wire    clk_psram_133;

psram_audio_buffer #(
    .NUM_SAMPLES ( AUDIO_NUM_SAMPLES ),
    .BASE_ADDR   ( 32'h2000_0000 )
) audio_mem (
    .clk_psram_133  ( clk_psram_133 ),
    .reset          ( reset ),

    .wr_clk         ( clk_74a ),
    .bridge_wr      ( bridge_wr ),
    .bridge_addr    ( bridge_addr ),
    .bridge_wr_data ( bridge_wr_data ),

    .rd_clk         ( audgen_sclk ),
    .rd_addr        ( audio_addr ),
    .rd_data        ( audio_frame ),

    .psram_test_done ( psram_test_done ),
    .psram_test_pass ( psram_test_pass ),

    .cram0_a        ( cram0_a ),
    .cram0_dq       ( cram0_dq ),
    .cram0_wait     ( cram0_wait ),
    .cram0_clk      ( cram0_clk ),
    .cram0_adv_n    ( cram0_adv_n ),
    .cram0_cre      ( cram0_cre ),
    .cram0_ce0_n    ( cram0_ce0_n ),
    .cram0_ce1_n    ( cram0_ce1_n ),
    .cram0_oe_n     ( cram0_oe_n ),
    .cram0_we_n     ( cram0_we_n ),
    .cram0_ub_n     ( cram0_ub_n ),
    .cram0_lb_n     ( cram0_lb_n )
);

playlist_ram #(
    .SLOT_ID     ( 16'd17         ),
    .BRIDGE_BASE ( 32'h2100_0000  ),
    .MAX_TRACKS  ( 512            )
) u_playlist_ram (
    .clk                        ( clk_74a ),
    .reset                      ( reset ),
    .target_dataslot_read       ( pram_ds_read ),
    .target_dataslot_id         ( pram_ds_id ),
    .target_dataslot_slotoffset ( pram_ds_slotoffset ),
    .target_dataslot_bridgeaddr ( pram_ds_bridgeaddr ),
    .target_dataslot_length     ( pram_ds_length ),
    .target_dataslot_done       ( target_dataslot_done ),
    .bridge_wr                  ( bridge_wr ),
    .bridge_addr                ( bridge_addr ),
    .bridge_wr_data             ( bridge_wr_data ),
    .loaded                     ( playlist_loaded ),
    .track_idx                  ( pram_read_idx_next ),
    .track_start                ( pram_start ),
    .track_chunks               ( pram_chunks ),
    .track_title                ( pram_title ),
    .track_artist               ( pram_artist ),
    .track_audio_bank           ( pram_audio_bank ),
    .track_count                ( pram_track_count ),
    .lib_idx                    ( list_track_idx ),
    .lib_title_le               ( lib_title_le ),
    .lib_artist_le              ( lib_artist_le )
);

// Section 35: passive per-track image storage - no dataslot ports (see
// audio_streamer.sv, which now issues the actual fetches).
track_thumb_ram #(
    .IMG_W              ( 172           ),
    .IMG_H              ( 172           ),
    .BG_W               ( 100           ), // Section 37 follow-up: 50->100 (blur "color blocks" fix)
    .BG_H               ( 90            ), // Section 37 follow-up: 45->90
    .ROW_ICON_W         ( 30            ), // Section 39: per-row Library thumbnail cache
    .ROW_ICON_H         ( 30            ),
    .ROW_SLOTS          ( 8             ),
    .IMG_BASE_ADDR      ( 32'h2300_0000 ),
    .BG_BASE_ADDR       ( 32'h2301_0000 ),
    .ROW_ICON_BASE_ADDR ( 32'h2303_0000 )
) u_track_thumb_ram (
    .clk            ( clk_74a ),
    .bridge_wr      ( bridge_wr ),
    .bridge_addr    ( bridge_addr ),
    .bridge_wr_data ( bridge_wr_data ),

    .rd_clk           ( clk_core_12288 ),
    .img_rd_addr      ( thumb_rd_addr ),
    .img_rd_data      ( thumb_pixel ),
    .bg_rd_addr       ( bg_rd_addr ),
    .bg_rd_data       ( bg_pixel ),
    .row_icon_rd_addr ( row_icon_rd_addr ),
    .row_icon_rd_data ( row_icon_pixel )
);

audio_streamer #(
    .AUDIO_SLOT_ID_BASE   ( 16'd20        ), // Section 41 follow-up: multi-bank audio, see audio_streamer.sv
    .BASE_ADDR            ( 32'h2000_0000 ),
    .RING_SLOTS           ( 16            ),
    .CHUNK_BYTES          ( 32'h0008_0000 ),
    .INITIAL_FILL_CHUNKS  ( 2             ), // Section 32: was implicitly RING_SLOTS (16); see audio_streamer.sv
    .IMG_SLOT_ID          ( 16'd19        ),
    .IMG_BASE_ADDR        ( 32'h2300_0000 ),
    .BG_BASE_ADDR         ( 32'h2301_0000 ),
    .IMG_BYTES            ( 32'd59168     ),
    .BG_BYTES             ( 32'd18000     ), // Section 37 follow-up: 100x90*2 (was 4500 = 50x45*2)
    .ROW_ICON_BASE_ADDR   ( 32'h2303_0000 ), // Section 39: per-row Library thumbnail cache
    .ROW_ICON_BYTES       ( 32'd1800      ), // 30x30 RGB565, one row's worth
    .ROW_SLOTS            ( 8             ),
    .MAX_TRACKS           ( 512           ) // must match playlist_ram's MAX_TRACKS above
) audio_stream (
    .clk                        ( clk_74a ),
    .reset                      ( reset ),
    .enable                     ( playlist_loaded ),
    .track_select               ( track_sel ),
    .cur_start                  ( pram_start ),
    .cur_chunks                 ( pram_chunks ),
    .cur_audio_bank             ( pram_audio_bank ),
    .lib_mode                   ( cur_tab == 2'd2 ),
    .list_scroll                ( list_scroll ),

    .target_dataslot_read       ( as_ds_read ),
    .target_dataslot_id         ( as_ds_id ),
    .target_dataslot_slotoffset ( as_ds_slotoffset ),
    .target_dataslot_bridgeaddr ( as_ds_bridgeaddr ),
    .target_dataslot_length     ( as_ds_length ),
    .target_dataslot_done       ( target_dataslot_done ),

    .slot_consumed_pulse        ( slot_consumed_pulse ),
    .initial_fill_done          ( initial_fill_done )
);

// shift out audio data as I2S
// 32 total bits per channel, but only 16 active bits at the start and then 16 dummy bits
//
    reg     [4:0]   audgen_lrck_cnt;
    reg             audgen_lrck;
    reg             audgen_dac;
    reg     [15:0]  audgen_shift;
always @(negedge audgen_sclk) begin
    audgen_dac <= 1'b0;
    // 48khz * 64
    audgen_lrck_cnt <= audgen_lrck_cnt + 1'b1;
    if(audgen_lrck_cnt < 16) begin
        audgen_dac   <= audio_loaded & audgen_shift[15];
        audgen_shift <= {audgen_shift[14:0], 1'b0};
    end
    if(audgen_lrck_cnt == 31) begin
        // switch channels
        audgen_lrck <= ~audgen_lrck;
        if (audio_loaded) begin
            if (!audgen_lrck) begin
                // ending the left half: load the right sample of the
                // current frame, and advance to the next frame so
                // psram_audio_buffer's read CDC has the ~10us until the
                // right half ends to fetch the new frame from PSRAM
                audgen_shift <= audio_frame[31:16];
                if (!paused_s) begin
                    audio_addr <= audio_addr + 1'b1; // natural 2^21 overflow = ring wrap
                    // signal producer when we're about to leave the current ring slot
                    if (audio_addr[16:0] == 17'h1FFFF)
                        slot_consumed_tog <= ~slot_consumed_tog;
                end
            end else begin
                // ending the right half: load the left sample of the
                // (already-advanced) next frame
                audgen_shift <= audio_frame[15:0];
            end
        end else begin
            audio_addr <= 0; // hold at 0 during gap; new track starts from ring slot 0
        end
    end
end


///////////////////////////////////////////////


    wire    clk_core_12288;
    wire    clk_core_12288_90deg;

    wire    pll_core_locked;
    wire    pll_core_locked_s;
synch_3 s01(pll_core_locked, pll_core_locked_s, clk_74a);

// sync initial_fill_done (clk_74a) into audgen_sclk for audio_loaded gate
synch_3 s_fill(initial_fill_done, initial_fill_done_s, audgen_sclk);

// sync paused into audio (audgen_sclk) and video (clk_core_12288) domains
synch_3 s_paused    (paused, paused_s,     audgen_sclk);
synch_3 s_paused_vid(paused, paused_vid_s, clk_core_12288);

// sync effect_mode (clk_74a) into video domain for the Now Playing renderer.
// 2 bits (Section 43: 3-way cycle, Still/Vinyl/Full Art).
synch_3 #(.WIDTH(2)) s_effect_vid(effect_mode, effect_mode_vid, clk_core_12288);

// sync repeat_all/shuffle_on into video domain for the NowPlaying indicator dots.
wire repeat_all_vid, shuffle_on_vid;
synch_3 s_repeat_vid (repeat_all, repeat_all_vid, clk_core_12288);
synch_3 s_shuffle_vid(shuffle_on, shuffle_on_vid, clk_core_12288);

// sync screensaver_on into video domain (Section 43).
synch_3 s_screensaver_vid(screensaver_on, screensaver_vid, clk_core_12288);

// sync lock_on into video domain (Section 44) - used only to detect the
// transition and drive the "LOCKED"/"UNLOCKED" message timer below, not to
// gate rendering directly (input_locked itself is a clk_74a-domain wire,
// button handling doesn't need a video-domain copy).
wire lock_on_vid;
synch_3 s_lock_vid(lock_on, lock_on_vid, clk_core_12288);

// sync list_scroll/list_cursor into video domain (Section 36 follow-up - see
// declaration comment above for why these two were missing a synchronizer).
synch_3 #(.WIDTH(9)) s_scroll_vid(list_scroll, list_scroll_vid, clk_core_12288);
synch_3 #(.WIDTH(9)) s_cursor_vid(list_cursor, list_cursor_vid, clk_core_12288);

// sync slot_consumed_tog from audgen_sclk into clk_74a; edge detect -> pulse
synch_3 s_slot(slot_consumed_tog, slot_consumed_tog_s, clk_74a);
always @(posedge clk_74a) begin
    slot_consumed_tog_s_r <= slot_consumed_tog_s;
end

// chunks_played: per-track progress counter in clk_74a domain.
// Resets to 0 on track change; increments each slot_consumed_pulse;
// wraps at cur_track_chunks for the active track.
// 16 bits (was [6:0] - silently truncated/wrapped at 127 chunks, ~5.5 minutes
// of audio at CHUNK_BYTES=512KB - found while investigating the wraparound
// bug; matches cur_track_chunks/playlist_ram's real track_chunks width).
reg [15:0] chunks_played;
reg [8:0]  track_sel_r_core; // registered copy to detect track changes
always @(posedge clk_74a or posedge reset) begin
    if (reset) begin
        chunks_played    <= 16'd0;
        track_sel_r_core <= 9'd0;
    end else begin
        track_sel_r_core <= track_sel;
        if (track_sel != track_sel_r_core)
            chunks_played <= 16'd0;
        else if (slot_consumed_pulse)
            chunks_played <= (chunks_played == cur_track_chunks - 16'd1) ? 16'd0 : chunks_played + 16'd1;
    end
end

// A button: pause/resume in NowPlaying tab, select+jump in Library tab;
// d-pad right/left rising-edge = next/prev track (NowPlaying only, gated
// in the title_ram/artist_ram handler above).
always @(posedge clk_74a or posedge reset) begin
    if (reset) begin
        btn_a_r      <= 1'b0;
        btn_right_r  <= 1'b0;
        btn_left_r   <= 1'b0;
        // Section 32: start paused/silent, not playing. Previously `paused`
        // reset to 0 (playing), so whatever track interact.json's persisted
        // "Track" setting restores at boot (a normal Pocket interact
        // behavior, confirmed happening every boot in the debug logs) would
        // start audio automatically with no user action this session. Now
        // audio stays silent until the user explicitly selects a track.
        paused       <= 1'b1;
        lib_select_r <= 1'b0;
    end else begin
        btn_a_r      <= cont1_key[4];
        btn_right_r  <= cont1_key[3];
        btn_left_r   <= cont1_key[2];
        lib_select_r <= 1'b0;
        if (auto_advance && auto_advance_would_stop) begin
            // Section 35 follow-up: "stop after all tracks played" reached
            // the end of the sequence - go silent instead of wrapping (see
            // auto_advance_would_stop/track_sel handler above). Checked
            // ahead of the A-button branch since this is a rare, one-cycle
            // system event (same "system events first" convention as the
            // track_sel priority chain above), not because a same-cycle
            // A-press is expected to actually occur.
            paused <= 1'b1;
        end else if (cont1_key[4] && !btn_a_r && !input_locked) begin
            if (cur_tab == 2'd2) begin
                lib_select_r <= 1'b1; // pulse: consumed next cycle in the title/artist handler
                // Section 32: selecting a track always starts it playing,
                // even if a DIFFERENT track was paused beforehand - previously
                // `paused` was untouched here, so a paused session required a
                // separate A-press in NowPlaying after selecting to actually
                // hear anything.
                paused <= 1'b0;
            end else
                paused <= ~paused;
        end
    end
end

// Section 35 follow-up: X = shuffle on/off, Y = repeat-all/stop-at-end
// toggle (plans/UI_SPEC.md's Now Playing button table), NowPlaying tab only.
// LFSR free-runs unconditionally (every cycle, any tab) so it's not
// correlated with when the user happens to press X/Y or when a track ends.
// Section 43: Select toggles the screensaver (full black blank, see
// screensaver_vid's use in the render block) - deliberately NOT gated by
// cur_tab, works from either tab. cont1_key[14] is Select on this platform/
// template - confirmed working via ImageViewer's own history on the same
// template (its debug-overlay toggle uses the same bit).
// Section 44: Start (cont1_key[15], confirmed via ImageViewer's own
// Start-button-menu history on this template) toggles the button lock -
// also NOT gated by cur_tab. Select's toggle gains a !lock_on guard and
// Start's gains a !screensaver_on guard so neither can activate while the
// OTHER is already active - see input_locked's declaration comment for why
// that keeps the two mutually exclusive by construction.
always @(posedge clk_74a or posedge reset) begin
    if (reset) begin
        btn_x_r      <= 1'b0;
        btn_y_r      <= 1'b0;
        btn_select_r <= 1'b0;
        btn_start_r  <= 1'b0;
        shuffle_on   <= 1'b0;
        repeat_all   <= 1'b1;
        screensaver_on <= 1'b0;
        lock_on        <= 1'b0;
        lfsr         <= 16'hACE1; // any nonzero seed
        shuffle_pick <= 9'd0;
    end else begin
        btn_x_r <= cont1_key[6];
        btn_y_r <= cont1_key[7];
        btn_select_r <= cont1_key[14];
        btn_start_r  <= cont1_key[15];
        if (cont1_key[14] && !btn_select_r && !lock_on)
            screensaver_on <= ~screensaver_on;
        if (cont1_key[15] && !btn_start_r && !screensaver_on)
            lock_on <= ~lock_on;
        if (cur_tab == 2'd0 && !input_locked) begin
            if (cont1_key[6] && !btn_x_r)
                shuffle_on <= ~shuffle_on;
            if (cont1_key[7] && !btn_y_r)
                repeat_all <= ~repeat_all;
        end
        // Galois LFSR, taps at bits 16/14/13/11 (maximal-length for 16 bits).
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        // Registered modulo reduction (see shuffle_pick's declaration
        // comment above for why this must be a register, not a bare wire).
        shuffle_pick <= (pram_track_count != 10'd0)
                        ? (lfsr % {6'b0, pram_track_count}) : 9'd0;
    end
end

always @(posedge clk_74a or posedge reset) begin
    if (reset) dpad_advance_r <= 1'b0;
    else        dpad_advance_r <= dpad_next || dpad_prev;
end

mf_pllbase mp1 (
    .refclk         ( clk_74a ),
    .rst            ( 0 ),

    .outclk_0       ( clk_core_12288 ),
    .outclk_1       ( clk_core_12288_90deg ),
    .outclk_2       ( clk_psram_133 ),

    .locked         ( pll_core_locked )
);


    
endmodule
