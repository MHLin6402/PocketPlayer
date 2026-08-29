// audio_streamer.sv - Module 3g: playlist-driven ring-buffer producer FSM
//
// Extends Module 3f: per-track start/chunk_count now come from playlist_ram
// (cur_start / cur_chunks inputs) instead of compile-time localparams.
// No FPGA recompile needed to add or change tracks.
//
// Waits in BOOT state until enable (= playlist_loaded from playlist_ram)
// before issuing the first dataslot read.  This prevents a race where
// audio_streamer misinterprets playlist_ram's target_dataslot_done pulse.
//
// On track_select change (REQ state only, never mid-read): soft-resets ring,
// jumps chunk_idx to cur_start, clears initial_fill_done to gate audio until
// the new track's ring is full.
//
// Ring constants (unchanged from Module 2c):
//   RING_FRAMES  = 2^21 = 2,097,152 (all of cram0)
//   RING_SLOTS   = 16
//   CHUNK_FRAMES = 131,072 = 2^17  (~2.73s per chunk)
//   CHUNK_BYTES  = 524,288 = 0x80000
//
// Section 35: this module is now ALSO the sole requester for per-track
// album art (track_thumb_ram.sv's storage). The APF data-slot protocol only
// supports one outstanding target_dataslot_read at a time system-wide
// (target_dataslot_done is a single shared completion pulse, not tagged per
// request) - core_top.v's arbitration mux already relies on this being true
// by construction (each boot-time-only requester finishes before the next
// starts). Track art needs to be RE-fetched every track change, which would
// have made it a second ongoing requester competing with this module for
// the whole rest of the session - unsafe without real cross-module
// handshaking. Instead, image fetching is folded into THIS state machine as
// a LOWEST-PRIORITY filler task: on every track change, in addition to the
// existing reseed, img_pending is set; REQ only starts an image/background
// fetch once there is no audio chunk work to do this cycle
// (chunks_in_flight >= RING_SLOTS) - so audio chunk fetching is completely
// unaffected (identical priority/timing to before) and art loading simply
// happens in the gaps. No new arbitration logic needed anywhere else.
//
// Section 39: same trick again, one priority level lower still, for the
// Library tab's per-row thumbnails: while lib_mode is asserted, REQ
// continuously cycles a small (1800-byte) row-icon fetch through all
// ROW_SLOTS (8) visible rows, round-robin, keyed off list_scroll - no
// explicit "did the page change" detection needed, since it just keeps
// re-fetching all 8 slots forever while the tab is open, so it "catches up"
// within at most 8 fetch cycles after any scroll. Only active when
// lib_mode is true (no wasted fetches while NowPlaying is shown). A
// defensive bound (row_track_idx >= MAX_TRACKS) guards against ever
// requesting an out-of-range playlist slot, since an out-of-range dataslot
// read would exceed track_thumbs.bin's size_exact and hang
// target_dataslot_done forever (see CLAUDE.md's APF dataslot length rule) -
// catastrophic here since this FSM is the system's ONLY dataslot requester.
//
// Section 41: MAX_TRACKS added as a parameter (matching playlist_ram.sv's)
// so this bound scales with the library size instead of a hardcoded 31 -
// flagged as needed the moment MAX_TRACKS grew past 32 (Section 40 notes).
//
// Section 41 follow-up: a 32-bit target_dataslot_slotoffset hard-caps any
// single data slot at 4GB/8192 chunks (see the slotoffset computation
// below - 13+19 bits exactly fills 32) - a limit the MAX_TRACKS=512 library
// (13GB+ of audio) blew straight through, corrupting playback partway
// through the library (see POCKETPLAYER_NOTES.txt). Fixed by splitting audio
// across multiple "Audio Bank N" data slots, each under that ceiling;
// AUDIO_SLOT_ID (a single fixed slot) becomes AUDIO_SLOT_ID_BASE + a new
// per-track cur_audio_bank input (from playlist_ram), latched into
// audio_bank_r at the exact same moment track_sel_r/chunk_idx reseed on a
// track change - same timing, no new race window. The slotoffset math
// itself is UNCHANGED: chunk_idx was never the bug, a global (cross-bank)
// chunk_idx was - once it's bank-local (which playlist_ram's track_start
// already is now), {chunk_idx[12:0], 19'b0} is correct as-is.

`default_nettype none

module audio_streamer #(
    parameter logic [15:0] AUDIO_SLOT_ID_BASE = 16'd20,
    parameter logic [31:0] BASE_ADDR     = 32'h2000_0000,
    parameter int          RING_SLOTS    = 16,
    parameter logic [31:0] CHUNK_BYTES   = 32'h0008_0000,
    // Section 32: how many chunks must land before initial_fill_done asserts
    // and audio starts playing. Was hardcoded to RING_SLOTS (the WHOLE ring,
    // 16 chunks = 8MB) - i.e. every track-switch/boot silently waited for a
    // full ring refill before making a sound, even though the ring only needs
    // to STAY ahead of playback, not start full. At ~20-24MB/s this dominated
    // the "a few seconds before playback starts" symptom (confirmed on
    // hardware, see POCKETPLAYER_NOTES.txt section 32). Lowering this to a
    // small number means audio starts almost immediately; REQ keeps
    // requesting further chunks up to RING_SLOTS in the background exactly as
    // before, so steady-state margin is unchanged.
    parameter int          INITIAL_FILL_CHUNKS = 2,
    // Section 35: per-track album art (track_thumb_ram.sv). One slot
    // ("Track Thumbs") holds, for every track index 0..31, a fixed-size
    // sharp-thumbnail + background pair back-to-back (tools/convert_audio.py
    // guarantees every slot is populated, real art or fallback).
    parameter logic [15:0] IMG_SLOT_ID   = 16'd19,
    parameter logic [31:0] IMG_BASE_ADDR = 32'h2300_0000,
    parameter logic [31:0] BG_BASE_ADDR  = 32'h2301_0000,
    parameter logic [31:0] IMG_BYTES     = 32'd59168,  // 172x172 RGB565
    parameter logic [31:0] BG_BYTES      = 32'd18000,  // 100x90 RGB565
    // Section 39: Library per-row thumbnails - a THIRD sub-image per track,
    // right after the sharp image + background in the same Track Thumbs
    // slot (see track_thumb_ram.sv/tools/convert_audio.py).
    parameter logic [31:0] ROW_ICON_BASE_ADDR = 32'h2303_0000,
    parameter logic [31:0] ROW_ICON_BYTES     = 32'd1800, // 30x30 RGB565, one row's worth
    parameter int          ROW_SLOTS          = 8,
    parameter int          MAX_TRACKS         = 512  // must match playlist_ram.sv's MAX_TRACKS
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,          // assert when playlist_ram is loaded
    input  logic [8:0]  track_select,    // active track index, clk_74a domain
    input  logic [15:0] cur_start,       // from playlist_ram: LOCAL start chunk within cur_audio_bank
    input  logic [15:0] cur_chunks,      // from playlist_ram: chunk count for track_select
    input  logic [3:0]  cur_audio_bank,  // from playlist_ram: which Audio Bank N slot holds track_select's audio
    input  logic        lib_mode,        // Library tab is active (clk_74a domain)
    input  logic [8:0]  list_scroll,     // top visible row's track index (clk_74a domain)

    output logic        target_dataslot_read,
    output logic [15:0] target_dataslot_id,
    output logic [31:0] target_dataslot_slotoffset,
    output logic [31:0] target_dataslot_bridgeaddr,
    output logic [31:0] target_dataslot_length,
    input  logic        target_dataslot_done,

    input  logic        slot_consumed_pulse,
    output logic        initial_fill_done
);

  localparam logic [31:0] PER_TRACK_IMG_BYTES = IMG_BYTES + BG_BYTES + ROW_ICON_BYTES;

  typedef enum logic [3:0] {
    BOOT,        // waiting for enable (playlist_loaded)
    REQ,
    WAIT_CLEAR,
    WAIT_DONE,
    IMG_WAIT_CLEAR,
    IMG_WAIT_DONE,
    BG_WAIT_CLEAR,
    BG_WAIT_DONE,
    ROW_WAIT_CLEAR,
    ROW_WAIT_DONE
  } state_t;
  state_t state;

  logic [15:0] chunk_idx;       // chunk offset LOCAL to audio_bank_r's data slot
  logic [7:0]  chunks_written;  // free-running; [3:0] = ring slot_idx
  logic [3:0]  slot_idx;
  assign slot_idx = chunks_written[3:0];
  logic [4:0]  chunks_in_flight;

  wire do_consume = slot_consumed_pulse && (chunks_in_flight > 5'h0);

  // track_sel_r: which track is actively loading (updated in REQ only)
  logic [8:0] track_sel_r;
  // audio_bank_r: which "Audio Bank N" data slot track_sel_r's audio lives
  // in - latched in lockstep with track_sel_r/chunk_idx on every track
  // change (see REQ below), so target_dataslot_id always matches whichever
  // bank chunk_idx is currently indexing into.
  logic [3:0] audio_bank_r;

  // img_pending: set on every track change, cleared once BOTH the sharp
  // image and background for track_sel_r have been (re-)fetched. Serviced
  // at lowest priority - see REQ below - so it never competes with audio
  // chunk fetching for the bus.
  logic img_pending;
  wire [31:0] img_slotoffset = 32'(track_sel_r) * PER_TRACK_IMG_BYTES;

  // Section 39: round-robin cursor over the 8 visible Library rows. Free-runs
  // (wraps 0..ROW_SLOTS-1) once per completed row-icon fetch, independent of
  // track changes - see REQ below and the file header comment.
  logic [2:0]  row_fetch_idx;
  // row_track_idx: playlist index for the row currently being fetched.
  // Widened to 10 bits purely as a defensive margin around the addition
  // (list_scroll + row_fetch_idx) - the surrounding scroll-clamp logic in
  // core_top.v already keeps this < MAX_TRACKS by construction, but the
  // guard below (row_track_idx >= MAX_TRACKS) is checked regardless, since
  // the failure mode of ever being wrong here (a hung dataslot request) is
  // severe.
  wire [9:0] row_track_idx = {1'b0, list_scroll} + {7'b0, row_fetch_idx};
  wire [31:0] row_icon_slotoffset = 32'(row_track_idx) * PER_TRACK_IMG_BYTES + IMG_BYTES + BG_BYTES;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state                      <= BOOT;
      target_dataslot_read       <= 1'b0;
      target_dataslot_id         <= AUDIO_SLOT_ID_BASE;
      target_dataslot_slotoffset <= 32'h0;
      target_dataslot_bridgeaddr <= BASE_ADDR;
      target_dataslot_length     <= CHUNK_BYTES;
      chunk_idx                  <= 16'h0;
      chunks_written             <= 8'h0;
      chunks_in_flight           <= 5'h0;
      initial_fill_done          <= 1'b0;
      track_sel_r                <= 9'h0;
      audio_bank_r               <= 4'h0;
      img_pending                <= 1'b1; // fetch track 0's art on first boot too
      row_fetch_idx              <= 3'h0;
    end else begin
      target_dataslot_read <= 1'b0;

      case (state)
        BOOT: begin
          if (enable) state <= REQ;
        end

        REQ: begin
          if (do_consume)
            chunks_in_flight <= chunks_in_flight - 1'b1;

          if (track_select != track_sel_r) begin
            // Track changed: soft-reset ring, jump to new track start.
            // Detected in REQ only to avoid aborting an in-progress SD read.
            track_sel_r       <= track_select;
            audio_bank_r      <= cur_audio_bank;
            chunk_idx         <= cur_start;
            chunks_written    <= 8'h0;
            chunks_in_flight  <= 5'h0;
            initial_fill_done <= 1'b0;
            img_pending       <= 1'b1;
          end else if (img_pending && (chunks_in_flight >= INITIAL_FILL_CHUNKS)) begin
            // Section 35 follow-up: grab album art as soon as the SAME
            // playback-safety margin that gates initial_fill_done is met,
            // instead of waiting for the ring to be COMPLETELY full
            // (chunks_in_flight >= RING_SLOTS, the original condition below).
            // That original design meant art could take ~10 real seconds to
            // appear after a track change - the ring greedily refills from
            // empty first (RING_SLOTS=16 chunks * ~2.73s/chunk of SD-read
            // time each), and only image-fetches once ALL of that is done.
            // Diverting one bus turn here costs only a small, one-time delay
            // to reaching a fully-topped-up ring - chunks_in_flight is still
            // well below RING_SLOTS at this point, so normal audio top-up
            // simply resumes and finishes after this single image+background
            // fetch, unaffected long-term. Checked ahead of the ring top-up
            // below so it wins once eligible (img_pending only true once per
            // track change, so this can only divert once per change).
            target_dataslot_id         <= IMG_SLOT_ID;
            target_dataslot_bridgeaddr <= IMG_BASE_ADDR;
            target_dataslot_slotoffset <= img_slotoffset;
            target_dataslot_length     <= IMG_BYTES;
            target_dataslot_read       <= 1'b1;
            state                      <= IMG_WAIT_CLEAR;
          end else if (chunks_in_flight < RING_SLOTS) begin
            target_dataslot_id         <= AUDIO_SLOT_ID_BASE + {12'b0, audio_bank_r};
            target_dataslot_bridgeaddr <= BASE_ADDR + (32'(slot_idx) << 19);
            target_dataslot_slotoffset <= {chunk_idx[12:0], 19'b0}; // chunk_idx * 0x80000, LOCAL to audio_bank_r
            target_dataslot_length     <= CHUNK_BYTES;
            target_dataslot_read       <= 1'b1;
            state                      <= WAIT_CLEAR;
          end else if (lib_mode && (row_track_idx < 10'(MAX_TRACKS))) begin
            // Section 39: lowest priority of all - ring is topped up, no
            // single-track art fetch pending, and the Library tab is open.
            // Keep cycling through all 8 visible rows' small icons
            // (row_fetch_idx advances in ROW_WAIT_DONE below). The
            // (row_track_idx < MAX_TRACKS) guard is the defensive bound
            // described above; if it's ever false this cycle, REQ just falls through
            // doing nothing and retries next cycle (list_scroll/row_fetch_idx
            // may have changed by then) rather than issuing a request that
            // could hang forever.
            target_dataslot_id         <= IMG_SLOT_ID;
            // Each of the 8 rows writes to its OWN address window
            // (track_thumb_ram.sv's row_icon_mem is one combined array
            // spanning all 8 slots) - varies by row_fetch_idx, unlike the
            // single-track img/bg fetches above which always reuse the same
            // fixed address since there's only ever one of those buffered.
            target_dataslot_bridgeaddr <= ROW_ICON_BASE_ADDR + (32'(row_fetch_idx) * ROW_ICON_BYTES);
            target_dataslot_slotoffset <= row_icon_slotoffset;
            target_dataslot_length     <= ROW_ICON_BYTES;
            target_dataslot_read       <= 1'b1;
            state                      <= ROW_WAIT_CLEAR;
          end
        end

        WAIT_CLEAR: begin
          if (do_consume)
            chunks_in_flight <= chunks_in_flight - 1'b1;
          if (!target_dataslot_done)
            state <= WAIT_DONE;
        end

        WAIT_DONE: begin
          if (target_dataslot_done) begin
            // wrap within current track's chunk range
            chunk_idx      <= (chunk_idx == (cur_start + cur_chunks - 16'd1))
                              ? cur_start : chunk_idx + 16'd1;
            chunks_written <= chunks_written + 1'b1;
            if (!initial_fill_done && (chunks_written == 8'(INITIAL_FILL_CHUNKS - 1)))
              initial_fill_done <= 1'b1;
            chunks_in_flight <= chunks_in_flight + 1'b1 - do_consume;
            state <= REQ;
          end else if (do_consume) begin
            chunks_in_flight <= chunks_in_flight - 1'b1;
          end
        end

        // ---- Section 35: per-track art, lowest priority (see REQ above) ----
        // Same do_consume bookkeeping as WAIT_CLEAR/WAIT_DONE throughout:
        // playback keeps draining the ring via the I2S/PSRAM read side
        // regardless of what this producer FSM is fetching, so
        // chunks_in_flight must stay accurate across these states too.
        IMG_WAIT_CLEAR: begin
          if (do_consume)
            chunks_in_flight <= chunks_in_flight - 1'b1;
          if (!target_dataslot_done)
            state <= IMG_WAIT_DONE;
        end

        IMG_WAIT_DONE: begin
          if (target_dataslot_done) begin
            // Sharp image landed - now fetch the matching background image.
            target_dataslot_id         <= IMG_SLOT_ID;
            target_dataslot_bridgeaddr <= BG_BASE_ADDR;
            target_dataslot_slotoffset <= img_slotoffset + IMG_BYTES;
            target_dataslot_length     <= BG_BYTES;
            target_dataslot_read       <= 1'b1;
            state                      <= BG_WAIT_CLEAR;
          end else if (do_consume) begin
            chunks_in_flight <= chunks_in_flight - 1'b1;
          end
        end

        BG_WAIT_CLEAR: begin
          if (do_consume)
            chunks_in_flight <= chunks_in_flight - 1'b1;
          if (!target_dataslot_done)
            state <= BG_WAIT_DONE;
        end

        BG_WAIT_DONE: begin
          if (target_dataslot_done) begin
            img_pending <= 1'b0;
            state       <= REQ;
          end else if (do_consume) begin
            chunks_in_flight <= chunks_in_flight - 1'b1;
          end
        end

        // ---- Section 39: Library row icons, lower priority still ----
        ROW_WAIT_CLEAR: begin
          if (do_consume)
            chunks_in_flight <= chunks_in_flight - 1'b1;
          if (!target_dataslot_done)
            state <= ROW_WAIT_DONE;
        end

        ROW_WAIT_DONE: begin
          if (target_dataslot_done) begin
            row_fetch_idx <= row_fetch_idx + 3'd1; // free-running wrap 0..7
            state         <= REQ;
          end else if (do_consume) begin
            chunks_in_flight <= chunks_in_flight - 1'b1;
          end
        end

        default: state <= BOOT;
      endcase
    end
  end

endmodule
