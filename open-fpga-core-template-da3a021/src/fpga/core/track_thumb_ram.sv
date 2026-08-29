// track_thumb_ram.sv - per-track album art storage (Section 35).
//
// Replaces thumb_ram.sv's single "always the bundled default image" design
// with real per-track thumbnails: a sharp 172x172 image (same size/role as
// the old default thumbnail - Still Thumbnail/Spinning Vinyl centerpiece,
// Library per-row icon) PLUS a small 50x45 "background" image (a PC-side
// pre-blurred/dimmed downscale of the same source art, meant to be
// upscaled with simple nearest-neighbor to fill the screen behind the
// Still Thumbnail/Spinning Vinyl effects - see CLAUDE.md's guidance to let
// the PC do expensive image work and keep the hardware to simple reads).
//
// UNLIKE thumb_ram.sv, this module has NO target_dataslot_read/loader FSM
// of its own - it is a PURE passive memory + bridge-write capture, same
// technique as psram_audio_buffer.sv/playlist_ram.sv's write side. The
// actual dataslot REQUESTS (one pair per track change: sharp image, then
// background) are issued by audio_streamer.sv, which already owns the
// single dataslot requester slot in core_top.v's arbitration mux. This
// deliberately avoids introducing a SECOND independent requester: the APF
// data-slot protocol only supports one outstanding target_dataslot_read at
// a time system-wide (target_dataslot_done is a single shared completion
// signal, not per-request), so two modules ever asserting overlapping
// requests would corrupt each other's completion detection. Routing both
// fetches through audio_streamer's existing single-requester FSM sidesteps
// that risk entirely instead of building new cross-module arbitration.
//
// Every one of the 32 track slots in track_thumbs.bin is guaranteed (by
// tools/convert_audio.py) to hold a valid image - either the track's real
// extracted cover art or a copy of the default note-icon graphic - so this
// module and its consumers never need a "does this track have art" special
// case; the PC did that work once, at conversion time.
//
// Section 39: added a THIRD image per track - a small, sharp ROW_ICON_W x
// ROW_ICON_H icon (pre-scaled on the PC, no blur) sized to drop directly
// into the Library list's per-row icon slot with no FPGA-side scaling math
// at all. Unlike img_mem/bg_mem (which hold only the ONE currently-playing
// track's art), row_icon_mem holds ROW_SLOTS (8) of these at once - one per
// visible Library row - so every visible row can show its own real
// thumbnail, not just the currently-loaded track's row. audio_streamer.sv
// keeps this cache filled via a continuous low-priority round-robin fetch
// while the Library tab is open (see its header comment).

`default_nettype none

module track_thumb_ram #(
    parameter int IMG_W = 172,
    parameter int IMG_H = 172,
    parameter int BG_W  = 100,
    parameter int BG_H  = 90,
    parameter int ROW_ICON_W = 30,
    parameter int ROW_ICON_H = 30,
    parameter int ROW_SLOTS  = 8,
    parameter logic [31:0] IMG_BASE_ADDR      = 32'h2300_0000,
    parameter logic [31:0] BG_BASE_ADDR       = 32'h2301_0000,
    parameter logic [31:0] ROW_ICON_BASE_ADDR = 32'h2303_0000
) (
    // ---------------- write (clk_74a / bridge domain) ----------------
    input  logic        clk,
    input  logic        bridge_wr,
    input  logic [31:0] bridge_addr,
    input  logic [31:0] bridge_wr_data,

    // ---------------- read (pixel clock domain) ----------------
    input  logic                          rd_clk,
    input  logic [$clog2(IMG_W*IMG_H)-1:0] img_rd_addr,
    output logic [15:0]                    img_rd_data,
    input  logic [$clog2(BG_W*BG_H)-1:0]   bg_rd_addr,
    output logic [15:0]                    bg_rd_data,
    input  logic [$clog2(ROW_SLOTS*ROW_ICON_W*ROW_ICON_H)-1:0] row_icon_rd_addr,
    output logic [15:0]                                        row_icon_rd_data
);

    localparam int          IMG_PIXELS  = IMG_W * IMG_H;
    localparam logic [31:0] IMG_BYTES   = IMG_PIXELS * 2;
    localparam int          IMG_WORDS   = IMG_PIXELS / 2; // IMG_W*IMG_H even for 172x172
    localparam int          BG_PIXELS   = BG_W * BG_H;
    localparam logic [31:0] BG_BYTES    = BG_PIXELS * 2;
    localparam int          BG_WORDS    = BG_PIXELS / 2;   // BG_W*BG_H even for 100x90
    localparam int          ROW_ICON_PIXELS = ROW_ICON_W * ROW_ICON_H;
    localparam logic [31:0] ROW_ICON_BYTES  = ROW_ICON_PIXELS * 2;      // one slot
    localparam int          ROW_TOTAL_PIXELS = ROW_SLOTS * ROW_ICON_PIXELS;
    localparam logic [31:0] ROW_TOTAL_BYTES  = ROW_TOTAL_PIXELS * 2;    // all slots combined
    localparam int          ROW_TOTAL_WORDS  = ROW_TOTAL_PIXELS / 2;    // 900*8/2=3600, even

    (* ramstyle = "M10K" *) logic [31:0] img_mem      [0:IMG_WORDS-1];
    (* ramstyle = "M10K" *) logic [31:0] bg_mem       [0:BG_WORDS-1];
    (* ramstyle = "M10K" *) logic [31:0] row_icon_mem [0:ROW_TOTAL_WORDS-1];

    // ---------------- write side (clk_74a / bridge) ----------------
    // Same byte-reversal as thumb_ram.sv/framebuffer_ram.sv: host bytes
    // arrive in ascending file-offset order per 32-bit word; the PC tool
    // writes each RGB565 pixel little-endian, 2 pixels per word - reversing
    // here makes bridge_wr_data[15:0]/[31:16] equal pixel 2N/2N+1 exactly as
    // written to the .bin file.
    wire               img_in_range = (bridge_addr >= IMG_BASE_ADDR) &&
                                       (bridge_addr < IMG_BASE_ADDR + IMG_BYTES);
    wire [$clog2(IMG_WORDS)-1:0] img_wr_word = (bridge_addr - IMG_BASE_ADDR) >> 2;
    wire               bg_in_range  = (bridge_addr >= BG_BASE_ADDR) &&
                                       (bridge_addr < BG_BASE_ADDR + BG_BYTES);
    wire [$clog2(BG_WORDS)-1:0]  bg_wr_word  = (bridge_addr - BG_BASE_ADDR) >> 2;
    // Section 39: audio_streamer issues one ROW_ICON_BYTES-sized fetch per
    // visible row, each with target_dataslot_bridgeaddr offset by that
    // row's slot number (ROW_ICON_BASE_ADDR + slot*ROW_ICON_BYTES) - so a
    // single range check + word index spanning ALL slots combined is enough
    // here; which slot a given write lands in falls out of the address
    // automatically, no separate "which row" signal needed on this side.
    wire               row_icon_in_range = (bridge_addr >= ROW_ICON_BASE_ADDR) &&
                                            (bridge_addr < ROW_ICON_BASE_ADDR + ROW_TOTAL_BYTES);
    wire [$clog2(ROW_TOTAL_WORDS)-1:0] row_icon_wr_word = (bridge_addr - ROW_ICON_BASE_ADDR) >> 2;

    always_ff @(posedge clk) begin
        if (bridge_wr && img_in_range)
            img_mem[img_wr_word] <= {bridge_wr_data[7:0], bridge_wr_data[15:8],
                                      bridge_wr_data[23:16], bridge_wr_data[31:24]};
        if (bridge_wr && bg_in_range)
            bg_mem[bg_wr_word] <= {bridge_wr_data[7:0], bridge_wr_data[15:8],
                                    bridge_wr_data[23:16], bridge_wr_data[31:24]};
        if (bridge_wr && row_icon_in_range)
            row_icon_mem[row_icon_wr_word] <= {bridge_wr_data[7:0], bridge_wr_data[15:8],
                                                bridge_wr_data[23:16], bridge_wr_data[31:24]};
    end

    // ---------------- read side (pixel clock) ----------------
    // Registered reads (M10K requirement - see CLAUDE.md's memory-inference
    // notes); core_top.v addresses these one pixel/track-icon-cell ahead
    // ("next" coordinates), same convention as the old thumb_ram.sv.
    logic        img_sel_q;
    logic [31:0] img_word_q;
    always_ff @(posedge rd_clk) begin
        img_sel_q  <= img_rd_addr[0];
        img_word_q <= img_mem[img_rd_addr[$clog2(IMG_PIXELS)-1:1]];
    end
    assign img_rd_data = img_sel_q ? img_word_q[31:16] : img_word_q[15:0];

    logic        bg_sel_q;
    logic [31:0] bg_word_q;
    always_ff @(posedge rd_clk) begin
        bg_sel_q  <= bg_rd_addr[0];
        bg_word_q <= bg_mem[bg_rd_addr[$clog2(BG_PIXELS)-1:1]];
    end
    assign bg_rd_data = bg_sel_q ? bg_word_q[31:16] : bg_word_q[15:0];

    logic        row_icon_sel_q;
    logic [31:0] row_icon_word_q;
    always_ff @(posedge rd_clk) begin
        row_icon_sel_q  <= row_icon_rd_addr[0];
        row_icon_word_q <= row_icon_mem[row_icon_rd_addr[$clog2(ROW_TOTAL_PIXELS)-1:1]];
    end
    assign row_icon_rd_data = row_icon_sel_q ? row_icon_word_q[31:16] : row_icon_word_q[15:0];

endmodule
