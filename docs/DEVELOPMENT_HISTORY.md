# Development History

> **About this file:** this is the complete, unedited internal build log
> kept during PocketPlayer's development (44 numbered sections, in
> chronological order) - every design decision, bug, root cause, and dead
> end, written as they happened. It's included as deep-reference material
> for anyone who wants the full story behind a particular piece of the
> design. For a curated starting point, see
> [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) (humans) or
> [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) (AI assistants) instead - both
> are self-contained and don't require reading this file first.
>
> Two things to know before diving in: it refers to the project by its
> original working name, "MusicPlayer" (renamed to PocketPlayer in Section
> 44, for the v1 release - the history below is left exactly as written,
> since it's an accurate record of what the project was called at each
> point in time). It also occasionally points to a sibling file,
> `POCKET_CORE_NOTES.txt`, from the private multi-project workspace this
> was developed in - that file documents a different, earlier project
> (general Analogue Pocket / openFPGA platform reference) and isn't part
> of this repository; where it matters, the same information has been
> folded into AI_AGENT_GUIDE.md instead.

================================================================================
 ANALOGUE MUSICPLAYER - BUILD/DEBUG HISTORY AND CURRENT STATUS
================================================================================
This is the Analogue MusicPlayer-specific companion to ../POCKET_CORE_NOTES.txt.
Read the "WHERE WE ARE / NEXT STEPS" section below first when picking up work
on this project.

SHARED PLATFORM REFERENCE: everything in ../POCKET_CORE_NOTES.txt sections 1-8
(toolchain/project layout, .sof->.rbf->.rbf_r conversion, SD card layout,
core.json/data.json/video.json/etc. schemas, platform files, on-Pocket
debugging tools, error message meanings, and the working end-to-end recipe)
applies UNCHANGED to this project too - that file's "NOTES FOR NEXT PROJECT:
AUDIO ON ANALOGUE POCKET" section (its final section) is the carry-forward
summary that kicked this project off. This file only tracks
MusicPlayer-specific design decisions and hardware status.

PROJECT ROOT: MusicPlayer/open-fpga-core-template-da3a021/ (copied
from the root open-fpga-core-template, same as ImageViewer's setup).
  - Author/shortname: mhlin / "MusicPlayer" -> SD folder
    /Cores/mhlin.MusicPlayer/ (renamed from "AnalogueMusicPlayer" - section 6).
  - Platform id: musicplayer (renamed from "analogue_musicplayer" - section 5)
    -> dist/Platforms/musicplayer.json, branded "MusicPlayer (WIP)" / "mhlin"
    / 2026 / category "Music Players".
  - Overall roadmap/UI spec: MusicPlayer/prompts/prompt_000.txt and
    MusicPlayer/plans/UI_SPEC.md (multi-tab UI: Album, Library,
    Playlist, Now Playing; generative visualizers; playback modes; etc.) -
    long-term vision, NOT all built yet. Current work follows a de-risking
    "Module" sequence agreed with the user, starting with the single hardest
    new piece (real audio output) before any UI work.


================================================================================
 WHERE WE ARE / NEXT STEPS
================================================================================
STATUS: Modules 2a/2b/2c all HARDWARE-CONFIRMED. Module 3a (full-screen
400x360, 10:9, no black bars) HARDWARE-CONFIRMED (2026-06-16, section 13).
Module 3b (progress bar) HARDWARE-CONFIRMED (2026-06-16, section 14).
Module 3c (font ROM + static text) HARDWARE-CONFIRMED (2026-06-16, section 15).

REPO FOLDER RENAME: DONE 2026-06-16 (section 9).

Module 3e HARDWARE-CONFIRMED (2026-06-16, section 17): interact "Track" menu
drives text_ram in real time. Module 3f superseded by Module 3g (section 19):
playlist.bin architecture (no localparams, no recompile to change tracks).
Module 3g bugs:
  Section 20: playlist.bin undersize (96 vs 256 bytes) - FIXED
  Section 21: playlist_ram FSM wrong (3-state) - FIXED
  Section 22: pram[] reset-gated (APF static boot writes ignored) + auto-advance
              display - FIXED. HARDWARE-CONFIRMED (Test 4, log _153746, 2026-06-17).
              Auto-advance, track select from menu, title updates all working.
              ~3s gap between tracks on auto-advance (acceptable). See section 23.
  Section 23: Progress bar formula hardcoded for 82-chunk track (Boys Like You).
              Tracks with fewer chunks (Cheshire=67, Blah Blah Blah=69) don't reach
              full bar before track advances. Fixed: compute fill = chunks_played*399/
              cur_track_chunks in clk_74a domain; 2-FF sync to video domain.
              HARDWARE-CONFIRMED Test 5, log _163602, 2026-06-17. MODULE 3g COMPLETE.

Section 24: Music library tool (convert_audio.py --dir / --use-tags).
              HARDWARE-CONFIRMED (log _173938, 2026-06-17). CHESHIRE (2022) 4-track
              album tested: all 4 tracks load, play, OSD titles correct, manual track
              switching works. Minor issue: progress bar falls ~1 chunk short at end of
              each track. Auto-advance NUM_TRACKS bug also found (hardcoded 3, skips
              track 3 on 4-track album).

Section 25: Progress bar fix + pause/resume (A button, amber bar) + auto-advance fix
              (pram_track_count from playlist_ram). HARDWARE-CONFIRMED (log _182052,
              2026-06-17). All three working: bar reaches full, A pauses/resumes (incl.
              track change while paused), auto-advance Freaky→Boys Like You confirmed.

Section 26: D-pad prev/next track + play/pause icon (▶/▐▐) + track number "X/Y".
              HARDWARE-CONFIRMED (log _231045, 2026-06-17). All three working. Different
              album (274MB) tested: library tool confirmed for multi-album use.
              16-char track name limit noted — 32+ chars + scrolling ticker deferred.

Section 27: Oscillograph "Now Playing" visualizer. HARDWARE-CONFIRMED (log _235950,
              2026-06-17/18). Live PCM waveform displayed in upper screen area. 8-track
              album used. Waveform visible but UNSTABLE: "tilted line" across ALL tracks =
              rolling/untriggered oscilloscope (each frame snaps at a different audio phase).

Section 28: Zero-crossing triggered oscilloscope.
              Rev1 (log _010851, 2026-06-18): NO SOUND — scope_ram [0:359] non-power-of-2
              + mixed constant/variable writes → Quartus 2880 regs → PSRAM timing fail.
              Rev2 (HW test 2026-06-18): AUDIO WORKS. Waveform still shows diagonal/tearing
              artifacts: fill writes to scope_ram while VGA reads it (MLAB async read, same
              frame). Not a clock-domain issue — both video and capture run on clk_core_12288.
              Rev3 fix: ping-pong double buffer (scope_ram_a + scope_ram_b), capture writes
              to back buffer, video reads stable front buffer, buffers swap at vsync only when
              HOLD state (complete capture ready).
              HARDWARE-CONFIRMED rev3 (log _022347, 2026-06-18). Section 28 complete.

Section 29: Now Playing redesign + tabs (Shoulder L/R: NowPlaying/Album/Library/
              Playlists) + 64-char title/32-char artist w/ news ticker. playlist_ram.sv
              and convert_audio.py rewritten for 128-byte records; core_top.v fully
              implemented 2026-07-22 (a prior session had only planned it, see section 29
              below for the full writeup and the correction note). HARDWARE-CONFIRMED
              2026-07-22 (debug logs _214227/_230954): loads correctly (new 1024-byte
              8-track playlist.bin, slot 18 not yet added at that point), tab structure
              and Shoulder L/R both work, Library A-select correctly plays the chosen
              track. Three bugs found in that test, addressed in Section 30: thin
              separator line spanning the full screen width instead of the bar's own
              margins; Library tab only ever showed the single browsed track (no real
              list); Library A-select didn't refresh the displayed title/artist even
              though the new track played correctly.

Section 30: Bug fixes from the Section 29 hardware test (progress-bar separator width,
              Library title-not-updating) + Library tab redesigned into a real
              scrollable track list with a highlighted selection + first iteration of a
              second Now Playing effect (static album-art thumbnail, D-pad Up/Down
              toggle, much less switching activity than the oscilloscope - for cooler
              long-duration testing). HARDWARE-CONFIRMED (2026-07-23, debug log
              _002804): all fixes working, list/highlight working. Two refinements
              requested, addressed in Section 31 (see below).

Section 31: SD card boot load ~5 minutes fix (data.json "deferload" on the Test
              Audio slot - Pocket was doing a full unnecessary 274MB static boot copy
              on top of audio_streamer's own on-demand chunked reads); Thumbnail effect
              redesigned into "Spinning Vinyl" (procedural disc + rotating reflection
              wedge, no box, per plans/Now_Playing_Tab.drawio.png); Library tab's mini
              "now playing" preview removed, track list rows expanded to fill nearly
              the whole screen (36px/row); Now Playing title/artist repositioned to
              center in the gap between the box and the progress bar. HARDWARE-
              CONFIRMED 2026-07-23 (log _013720) - deferload fix verified via the
              log's own "Deferred load" message; Spinning Vinyl didn't match the
              intended design, corrected in Section 32.

Section 32: MAX_TRACKS 8->32 + Library scrolling; no-autoplay-at-boot + always-
              play-on-select fixes; track-switch load delay fix (initial ring fill
              2 chunks instead of 16); Library per-row thumbnail icons; Still
              Thumbnail restored as its own effect (large icon) with Spinning Vinyl
              as a separate 3rd effect (centered as a unit with the album art, half
              the disc hidden, dual reflections, subtler 3-ring grooves); default
              thumbnail redesigned as a music-note icon; test library expanded to 26
              tracks across 2 artists/5 albums. Album tab (two-screen drill-down)
              explicitly DEFERRED - too large to fold into this same batch safely,
              see Section 32 for details. SOURCE DONE (2026-07-23), self-reviewed,
              not yet compiled.


--------------------------------------------------------------------------------
1. MODULE 2a: AUDIO "HELLO WORLD" - LOOPED PCM CLIP THROUGH I2S (source done,
   awaiting hardware test)
--------------------------------------------------------------------------------
GOAL: de-risk the single most novel piece of this project - real audio output
- before any UI/menu work begins. The stock core_top.v's I2S block is a
"silence generator" (audgen_dac hardcoded to 0). This module replaces that
with real PCM playback of a 1-second clip, loaded from the SD card via the
confirmed target_dataslot_* mechanism (../POCKET_CORE_NOTES.txt section 2 of
the "next project" notes), looping forever. No PSRAM, no UI, no song
selection - those come later (Module 2b+).

DESIGN:
- Clip: 48kHz / 16-bit / stereo, NUM_SAMPLES=48000 (1.000s), 192,000 bytes
  total. audio_ram is 48000 x 32-bit (~190KB on-chip, comfortably within the
  5CEBA4's ~385KB M10K budget for an otherwise-empty core).
- Source track: MusicPlayer/source_musics/ITZY/Boys Like You
  (2022)/01 - Boys Like You.flac (first track, single recognizable beat -
  good for confirming pitch/timing). Easy to change via convert_audio.py's
  argument.
- Byte order: reuses framebuffer_ram.sv's confirmed pattern. convert_audio.py
  writes raw interleaved PCM s16le stereo (ffmpeg `-f s16le -ar 48000 -ac 2`).
  audio_ram.sv's write port byte-reverses bridge_wr_data the same way
  framebuffer_ram.sv does:
    mem[addr] <= {bridge_wr_data[7:0], bridge_wr_data[15:8],
                   bridge_wr_data[23:16], bridge_wr_data[31:24]};
  which yields mem[addr][15:0]=left sample, mem[addr][31:16]=right sample -
  the natural little-endian PCM layout, no Python-side repacking needed.

NEW FILES (open-fpga-core-template-da3a021/src/fpga/core/):
- audio_ram.sv: on-chip BRAM (* ramstyle = "M10K" *), modeled directly on
  framebuffer_ram.sv. Parameters NUM_SAMPLES=48000, BASE_ADDR=0x2000_0000.
  Write port (clk_74a/bridge domain) snoops bridge_wr/bridge_addr/
  bridge_wr_data for [0x2000_0000, 0x2000_0000+192000]. Read port registered,
  1-cycle latency, addressed by sample index 0..47999, returns 32-bit
  {right,left} frame.
- audio_loader.sv: one-shot dataslot-read FSM mirroring image_controller.sv's
  request pattern (REQ -> WAIT_CLEAR -> WAIT_DONE -> DONE). Parameters
  AUDIO_SLOT_ID=16'd16, AUDIO_BRIDGE_ADDR=32'h2000_0000, AUDIO_BYTES=32'd192000.
  WAIT_CLEAR/WAIT_DONE sequencing (wait for target_dataslot_done to go 0 THEN
  1) avoids mistaking a stale "done" from a previous request for completion -
  same caution as image_controller.sv. Outputs audio_loaded.
- Both registered in ap_core.qsf as SYSTEMVERILOG_FILE entries (after
  core_bridge_cmd.v).

core_top.v CHANGES (open-fpga-core-template-da3a021/src/fpga/core/):
- Added `wire reset = ~reset_n;` (active-high derived reset), mirroring
  ImageViewer's pattern, used by audio_loader's
  `always_ff @(posedge clk or posedge reset)`.
- target_dataslot_read/write/getfile/openfile/id/slotoffset/bridgeaddr/length
  changed from `reg` to `wire`; write/getfile/openfile tied to `= 0` in their
  wire declarations (audio_loader drives read/id/slotoffset/bridgeaddr/length
  as output ports - same confirmed pattern as image_controller.sv in
  ImageViewer).
- Instantiated audio_ram and audio_loader.
- MCLK generator (12.288MHz fractional accumulator from clk_74a) and SCLK
  divider (MCLK/4 = 3.072MHz) LEFT UNCHANGED from the stock silence generator.
- Replaced the `always @(negedge audgen_sclk)` shift-out block: while
  audgen_lrck_cnt < 16, shifts out sample_shift[15] MSB-first (else 0, as
  before); on the audgen_lrck_cnt==31->0 boundary, toggles audgen_lrck,
  advances sample_addr (wrapping at NUM_SAMPLES) once per full L+R frame, and
  reloads sample_shift from audio_ram's output for the new channel. Output
  stays silent (audgen_dac=0) until audio_loaded is asserted.
  TIMING NOTE: sample_addr increments ONE STEP EARLY (at the left-half's
  cnt==31 boundary, not the right-half's) so audio_ram's 1-cycle registered
  read latency resolves before the right-half's cnt==31 boundary needs the
  new sample.

data.json / dist PACKAGING (mirrors ImageViewer's dist/ layout exactly):
- New data slot: id=16, name "Test Audio", required=false, address
  "0x20000000", size_exact "0x2EE00" (192000 bytes) - added to both the
  dev-copy data.json and dist/Cores/mhlin.AnalogueMusicPlayer/data.json.
- dist/Cores/mhlin.AnalogueMusicPlayer/: core.json (shortname "Music Player
  (WIP)", version 0.1.0, date_release 2026-06-15, platform_ids
  ["ex_platform"]), audio.json/input.json/variants.json (identical to stock),
  interact.json (empty - no settings yet), video.json (stock scaler_modes
  only, 320x240 4:3, no display_modes), data.json (as above), icon.bin
  (moved from stock dist/icon.bin, 2592 bytes).
- dist/Platforms/ex_platform.json + dist/Platforms/_images/ex_platform.bin:
  recovered from the untouched root template copy after an accidental
  case-insensitive-filesystem mishap during reorganization (see "GOTCHAS"
  below) - content unchanged from stock except ex_platform.json's
  name/year/manufacturer (see PROJECT ROOT above).
- dist/Assets/ex_platform/common/test_audio.bin: 192,000 bytes, generated by
  convert_audio.py (run once already - output verified to be exactly
  0x2EE00 bytes, matching data.json's size_exact).

TOOLING:
- MusicPlayer/tools/convert_audio.py (new): ffmpeg subprocess
  wrapper. `ffmpeg -y -v error -i <input> -f s16le -ar 48000 -ac 2 -`
  (stdout pipe), then trims/zero-pads to exactly --seconds worth of frames
  (default 1.0s = 48000 frames = 192000 bytes). Default input/output paths
  point at the ITZY track and dist/Assets/ex_platform/common/test_audio.bin
  respectively. Usage: `py tools/convert_audio.py [input] [output]
  [--seconds N]`.
- MusicPlayer/tools/make_rbf_r.py: copied UNCHANGED from
  ImageViewer/tools/make_rbf_r.py (generic .rbf -> .rbf_r bit-reversal
  converter, no audio-specific changes needed).

GOTCHAS HIT THIS ROUND:
- Windows/NTFS is case-insensitive: "Platforms" and "platforms" (similarly
  "Assets"/"assets") are the SAME directory entry. A `mkdir -p
  Platforms/...` + `mv platforms/X Platforms/X` + `rm -rf platforms` sequence
  is a NO-OP for the mkdir/mv (target==source) followed by a real delete of
  the content - this destroyed dist/Platforms/ex_platform.json and
  _images/ex_platform.bin until recovered via `cp` from the untouched
  root-level open-fpga-core-template-da3a021/dist/platforms/ (a fresh,
  never-modified copy of the template). LESSON: when changing directory
  case, use genuinely distinct temp paths or `cp` from an untouched source -
  never `mv`+`rm` chains across a case-only rename on Windows.

STATUS: source-complete, built, deployed, HARDWARE-CONFIRMED WORKING
(2026-06-15 re-test, after the section 2 core.json fix) - see section 3 for
the audio playback diagnosis.


--------------------------------------------------------------------------------
2. FIRST HARDWARE TEST: core.json shortname/folder-name mismatch -> core
   failed to load, fell back to ImageViewer (FIXED, CONFIRMED by re-test)
--------------------------------------------------------------------------------
SYMPTOM (user report, 2026-06-15): selecting "Music Player (WIP)" from
Tools/Developer/Build (or the Cores menu) and running it actually displayed/
behaved like the previous ImageViewer core. Tools/Developer/Build listed both
"ImageViewer v1.3.0" and "Music Player (WIP) v0.1.0" as separate entries
(so both cores WERE recognized individually - no SD-card "clean slate" or
de-duplication issue, no need to wipe the SD card).

DIAGNOSIS: the SD debug dump's System/Logs/mhlin.Music Player (WIP)_
20260615_162906.txt contains only 7 lines, ending right after:
    Opening /Cores/mhlin.Music Player (WIP)/core.json
with no further lines (no "Opening variants.json", no "Done loading core
json", nothing). Compare to a working ImageViewer log, which proceeds
through core.json -> variants.json -> data.json -> interact.json ->
video.json -> audio.json -> input.json -> "Done loading core json" ->
bitstream load -> Prerun -> Run.

ROOT CAUSE: this is the exact failure mode already documented in
../POCKET_CORE_NOTES.txt section 3 (lines ~74-93): "The folder name under
/Cores/ MUST be EXACTLY <author>.<shortname> from core.json's metadata."
Our SD card folder is /Cores/mhlin.AnalogueMusicPlayer/ (set up correctly at
project start), but core.json's metadata.shortname was "Music Player (WIP)"
- so the Pocket computed the path /Cores/mhlin.Music Player (WIP)/core.json,
which doesn't exist, and the load aborted immediately (-> "error in core" /
"error in core setup" popups, and the FPGA fabric stayed configured with
whatever ran last - ImageViewer - which is why ImageViewer's content
appeared). This mismatch was baked into MUSICPLAYER_NOTES.txt's own "PROJECT
ROOT" section from the start (it documented shortname "Music Player (WIP)"
-> folder "AnalogueMusicPlayer" as if that were fine) - an oversight carried
over without re-checking section 3's rule.

FIX APPLIED (source, not yet redeployed... well, dist/ IS updated, just needs
copying to the SD card - see NEXT STEPS):
- dist/Cores/mhlin.AnalogueMusicPlayer/core.json: metadata.shortname changed
  from "Music Player (WIP)" to "AnalogueMusicPlayer" (matches the existing
  folder name exactly, no spaces/parens). This is a cosmetic rename in the
  Tools/Developer/Build menu (now reads "AnalogueMusicPlayer v0.1.0") and in
  future debug log filenames (mhlin.AnalogueMusicPlayer_*.txt) - no HDL or
  asset changes, no recompile needed.

OTHER ITEMS CHECKED AND FOUND OK (not the cause, but verified while
investigating):
- Bitstream conversion: the deployed Cores/mhlin.AnalogueMusicPlayer/
  bitstream.rbf_r on the SD card (1,372,468 bytes) IS correctly bit-reversed
  - verified byte-for-byte against tools/make_rbf_r.py applied fresh to
    output_files/ap_core.rbf (compiled 2026-06-15 16:02, matches our Module
    2a source). The make_rbf_r.py step was done correctly; only the SD-card
    *copy* step was done by hand (the provided robocopy command failed to
    paste correctly in PowerShell - likely the multi-line backtick
    continuation breaking on paste). This file was copied straight into the
    relocated dist/ (see below) so no reconversion is needed.
- data.json: dist copy and SD-card copy are byte-identical (single "Test
  Audio" slot, id 16) - no data.json regeneration step was missing.
  ImageViewer/tools/generate_data_json.py is ImageViewer-specific
  (album/image slot generator) and doesn't apply to MusicPlayer's one
  hand-written slot.
- interact.json: standard empty `{"interact": {"variables": [], "messages":
  []}}` - valid, not a cause.

RESTRUCTURING DONE AT THE SAME TIME (user request - easier SD-card access):
- Moved dist/ from open-fpga-core-template-da3a021/dist/ to
  MusicPlayer/dist/ (project root), matching ImageViewer/dist/'s
  location. Updated tools/convert_audio.py's DEFAULT_OUTPUT accordingly.
  All future make_rbf_r.py / dist edits target MusicPlayer/dist/.
- Added MusicPlayer/NEXT_STEPS.txt: a short, copy-paste-friendly
  "what to run next" file (situation summary + single-line PowerShell
  commands, no backtick continuations - those break when pasted). Will be
  kept up to date each session per user request, going forward for both
  this project and future ones (see CLAUDE.md).

STATUS: FIX CONFIRMED. User re-deployed dist/ and re-tested on 2026-06-15:
"This time after selecting the right core it worked properly." Core now loads
correctly - see section 3 for the audio playback result.


--------------------------------------------------------------------------------
3. MODULE 2a HARDWARE TEST: AUDIO PLAYBACK CONFIRMED (2026-06-15)
--------------------------------------------------------------------------------
RESULT (user report, 2026-06-15, after the section 2 fix was redeployed):
"This time after selecting the right core it worked properly. The screen goes
gray and there is a beep sound repeating every 1 second (I don't have the
ability to count the very short time but it sounds normal)."

DIAGNOSIS against the diagnostic tree in "WHERE WE ARE / NEXT STEPS":
- Gray screen: EXPECTED. video.json only declares the stock 320x240 4:3
  scaler mode with no framebuffer content - this is the same gray test
  pattern the stock template/ImageViewer showed before any video work.
- NOT silence: audio_loader's target_dataslot_read for slot 16 completed,
  audio_ram was populated, and audio_loaded gated the I2S output as designed
  - ruling out a loader/dataslot failure.
- NOT noise/static: a clean, periodic "beep" rules out a byte-order or
  bit-shift-timing bug in the new I2S shift-out block (those produce
  garbled/random-sounding output, not a clean repeating tone).
- Timing CONFIRMED CORRECT: the beep repeats every ~1 second, which is
  exactly NUM_SAMPLES=48000 @ 48kHz = 1.000s - i.e. the MCLK
  (12.288MHz)/SCLK (3.072MHz) generators (left unchanged from the stock
  silence generator) and the sample_addr wrap-around logic are all correct.
- The "beep" character itself (vs. a recognizable song snippet) is most
  likely either (a) the actual first-second content of "01 - Boys Like
  You.flac" (many K-pop tracks open with a short synth/percussion hit), or
  (b) the loop-boundary discontinuity "click" - this hello-world module does
  no loop crossfade/smoothing by design, so a click every 1.000s at the seam
  is expected. Either way, this is NORMAL for Module 2a's scope.

CONCLUSION: Module 2a's goal - de-risk real PCM audio output via I2S, driven
by an SD-card-loaded clip through the target_dataslot_* mechanism - is
ACHIEVED and HARDWARE-CONFIRMED. The full pipeline (loader FSM -> audio_ram
BRAM -> I2S shift-out -> DAC, with correct 48kHz/16-bit/stereo timing) works
end to end on real hardware.

STATUS: SUCCESS. Per CLAUDE.md standing instructions, this section + section
1/2's status lines were updated and a git commit covers dist/ + source +
notes. Module 2b (PSRAM-backed full-song streaming) is next.


--------------------------------------------------------------------------------
4. MENU STRUCTURE: ImageViewer/AnalogueMusicPlayer shared platform_id
   "ex_platform" -> "Change Core" collision (FIXED in dist/, awaiting
   redeploy)
--------------------------------------------------------------------------------
SYMPTOM (user report, 2026-06-15): "why is the menu of both the ImageViewer
and the AnalogueMusicPlayer both under Example Cores/MusicPlayer (WIP), and
I'll have to change core under this place ... the menu should be
openFPGA/ImageViewer and openFPGA/AnalogueMusicPlayer, and the core should
not be able to change since the ImageViewer itself is the core and so does
the MusicPlayer."

HOW THE openFPGA MENU IS STRUCTURED (per POCKET_CORE_NOTES.txt section 5):
openFPGA > <platform's "category"> > <platform's "name"> > <core>. The
"category"/"name" come from /Platforms/<platform_id>.json, which is keyed by
the platform_id(s) a core.json declares in metadata.platform_ids. If MULTIPLE
cores on the SD card declare the SAME platform_id, the Pocket groups them all
under that ONE platform entry and offers a "Change Core" picker between them
- this is the openFPGA UI's normal, intentional behavior for that case (think
of "platform" as a virtual console/system, and "core" as one of several
implementations of it).

ROOT CAUSE: both projects' core.json declared platform_ids: ["ex_platform"]
(carried over from the stock template). Both dist/ trees also shipped their
own Platforms/ex_platform.json + _images/ex_platform.bin - but the SD card
only has ONE /Platforms/ex_platform.json, so whichever dist/ was copied LAST
"wins". Today, copying AnalogueMusicPlayer's dist/ (still declaring
platform_ids: ["ex_platform"], branded category "Example Cores" / name
"Analogue MusicPlayer (WIP)") overwrote ImageViewer's earlier "AnalogueFoto"/
"Photo Viewers" rebrand of that same file - so BOTH cores now show up grouped
under "Example Cores > Analogue MusicPlayer (WIP)" with a Change Core choice.

FIX APPLIED (in MusicPlayer/dist/, NOT YET on the SD card):
- New file Platforms/analogue_musicplayer.json:
  { "platform": { "category": "Music Players", "name": "AnalogueMusicPlayer
    (WIP)", "year": 2026, "manufacturer": "mhlin" } }
- New file Platforms/_images/analogue_musicplayer.bin (copy of the stock
  ex_platform.bin icon for now - cosmetic, can be replaced later).
- Cores/mhlin.AnalogueMusicPlayer/core.json: platform_ids changed from
  ["ex_platform"] to ["analogue_musicplayer"].
- Assets/ex_platform/common/test_audio.bin moved to
  Assets/analogue_musicplayer/common/test_audio.bin (the platform's default
  asset folder is named after platform_ids[0] - POCKET_CORE_NOTES.txt section
  3/9). tools/convert_audio.py's DEFAULT_OUTPUT updated to match.
- Removed Platforms/ex_platform.json, Platforms/_images/ex_platform.bin, and
  the (now-empty) Assets/ex_platform/ directory from
  MusicPlayer/dist/ entirely - this project no longer touches
  "ex_platform" at all, so re-copying its dist/ can never again clobber
  ImageViewer's Platforms/ex_platform.json.

RESULT (once redeployed, see "WHERE WE ARE / NEXT STEPS"): two independent
menu entries - "Photo Viewers > AnalogueFoto" (ImageViewer only) and "Music
Players > AnalogueMusicPlayer (WIP)" (AnalogueMusicPlayer only) - each with a
single core, so there's nothing to "Change Core" between. This is as close to
"openFPGA/ImageViewer" and "openFPGA/AnalogueMusicPlayer" as the openFPGA
category/platform/core hierarchy allows; the category/name strings can be
freely renamed later (e.g. category "mhlin" for both, or anything else) if a
different grouping is preferred - just keep the platform_ids DISTINCT per
project. A general note was added to POCKET_CORE_NOTES.txt section 5.

STATUS: redeployed 2026-06-15 - Developer menu now lists both cores
separately (CONFIRMED), so the platform-split itself is correct. But this
redeploy surfaced a NEW bug (platform_id "analogue_musicplayer" too long) -
see section 5 for the follow-on fix. FINAL RESULT (section 7): with
platform_id shortened to "musicplayer", the split is fully CONFIRMED working
in openFPGA too, no crash.


--------------------------------------------------------------------------------
5. PLATFORM_ID LENGTH LIMIT (>15 CHARS): SILENT ASSET-PATH TRUNCATION +
   openFPGA BROWSE CRASH (FIXED in dist/, awaiting SD card cleanup + redeploy)
--------------------------------------------------------------------------------
SYMPTOM (user report, 2026-06-15, after redeploying section 4's fix): "This
time I enter the developer first. I can see the two cores here. The
MusicPlayer worked normally with the gray screen but without sound. after
that I went to the menu and tried to enter openFPGA, then the screen starts
flashing and uncontrollable again. The screen goes all black for like 1
second and turned on back to the menu and repeats. none of the button works
in this situation but only the power button after holding a few seconds."

DIAGNOSIS: read the fresh SD card dump (MusicPlayer/debug/AP/).
System/Logs/mhlin.AnalogueMusicPlayer_20260615_183322.txt shows:
    Slot: checking name [Test Audio] ID [16] idx 0
    Checking file /Assets/analogue_musicp/common/test_audio.bin
    Host: Updating core data slot BRAM table. Slot ID [16] idx 0 - size 0 bytes
    ...
    Target: Read to 0x20000000 from file ... filename [/Assets/analogue_musicp/common/test_audio.bin]
    Target: Start failed

Our platform_id is "analogue_musicplayer" (20 chars), but the path Pocket OS
actually checked is "/Assets/analogue_musicp/..." - truncated to 15 chars
("analogue_musicp"). The real folder (Assets/analogue_musicplayer/common/)
was never found, "Total loadsize is 0", the data slot load fails ("Start
failed"), audio_ram is never populated, and audio_loaded never asserts - so
core_top.v correctly stays silent (by design - see section 1/Module 2a). This
fully explains "gray screen but no sound".

THEORY for the openFPGA crash: the SAME 20-char platform_id is very likely
copied into the SAME ~16-byte buffer by the openFPGA library/platform-list
cache builder (the code that populates platform_viewby_category.bin /
core_viewby_platform.bin and renders "openFPGA > category > platform > core").
The data-slot code path above truncates safely (just fails the file lookup);
this other code path is apparently NOT bounds-checked and overruns its
buffer, corrupting adjacent state and crash-looping the UI (matches "the
platform this time seems to only appear the Foto one" from the user's
previous message - AnalogueFoto's entry, built first/alphabetically, renders
fine; the crash happens while building AnalogueMusicPlayer's entry, right
after). Both of our previously-working platform_ids (ex_platform,
imageviewer) are 11 chars - well under 15 - which is why this never surfaced
before.

FIX APPLIED in MusicPlayer/dist/ (platform_id "analogue_musicplayer"
-> "musicplayer", 11 chars):
  - Cores/mhlin.AnalogueMusicPlayer/core.json: platform_ids -> ["musicplayer"]
  - Platforms/analogue_musicplayer.json renamed -> Platforms/musicplayer.json
    (content unchanged: category "Music Players", name "AnalogueMusicPlayer
    (WIP)")
  - Platforms/_images/analogue_musicplayer.bin renamed ->
    Platforms/_images/musicplayer.bin
  - Assets/analogue_musicplayer/common/test_audio.bin moved ->
    Assets/musicplayer/common/test_audio.bin (empty analogue_musicplayer/
    dirs removed)
  - tools/convert_audio.py DEFAULT_OUTPUT updated to match

SD CARD RECOVERY NEEDED (this is NOT a simple "copy dist/ again" - the SD
card still has the old 20-char-named platform files, which are now orphaned
but could still independently trigger the openFPGA browse crash if left in
place, since nothing deletes extra files on the destination):
  - DELETE from the SD card: Platforms/analogue_musicplayer.json,
    Platforms/_images/analogue_musicplayer.bin,
    Assets/analogue_musicplayer/ (whole folder)
  - DELETE the 6 /System/*cache*.bin browse-cache files again (rebuilt
    automatically) - they may also be incomplete/corrupt from the crash
    that happened mid-rebuild.
  - THEN copy the corrected MusicPlayer/dist/ (now "musicplayer").
  - Exact single-line commands in NEXT_STEPS.txt.

GENERAL RULE added to POCKET_CORE_NOTES.txt section 5: platform_ids must be
<= 15 characters (both known-good ones, ex_platform/imageviewer, are 11).

STATUS: FIXED AND CONFIRMED (section 7). With platform_id "musicplayer" (11
chars), the Assets path resolves correctly (no truncation), audio is back,
and openFPGA browse no longer crashes.


--------------------------------------------------------------------------------
6. PROJECT RENAME: "AnalogueMusicPlayer" -> "MusicPlayer" (SD-facing parts
   FIXED in dist/, repo folder/docs DEFERRED - awaiting redeploy + retest)
--------------------------------------------------------------------------------
REQUEST (user, 2026-06-15, same session as section 5): "since the name of the
project is a problem and also might lead to other problems in the future,
let's change the project name to MusicPlayer instead. without the
'Analogue_' in the name is probably safe enough. ... change everything that
has to be changed or you can leave a note for next build to change entirely."

SCOPE DECISION: only the two SD-facing identifiers were renamed now, bundled
into the SAME redeploy as section 5's platform_id fix (one cleanup + one
redeploy + one retest, rather than two separate cycles):
  - core.json "shortname": "AnalogueMusicPlayer" -> "MusicPlayer" (19 -> 11
    chars). This changes the SD folder names to /Cores/mhlin.MusicPlayer/ and
    /Settings/mhlin.MusicPlayer/ (and future debug log filenames). Note:
    "AnalogueMusicPlayer" (19 chars) was NOT actually hitting the 15-char
    limit (Developer menu found it fine) - this rename is precautionary per
    the user's request, not a confirmed second instance of the section-5 bug.
  - Platforms/musicplayer.json "name": "AnalogueMusicPlayer (WIP)" ->
    "MusicPlayer (WIP)" (the openFPGA menu's display string). category
    "Music Players" unchanged.
  - dist/Cores/mhlin.AnalogueMusicPlayer/ directory renamed ->
    dist/Cores/mhlin.MusicPlayer/ (core.json description string also updated
    to drop "Analogue").
  - tools/convert_audio.py docstring updated to say "MusicPlayer" instead of
    "Analogue MusicPlayer".
  - platform_id stays "musicplayer" (already <=15 chars from section 5's
    fix; no further change needed there).

SD CARD IMPACT: the OLD /Cores/mhlin.AnalogueMusicPlayer/ folder (which
currently has platform_ids: ["analogue_musicplayer"], the BROKEN 20-char id,
from the section-4 partial redeploy) becomes orphaned once the new
/Cores/mhlin.MusicPlayer/ is copied - it must be explicitly DELETED from the
SD card (not just superseded), both for cleanliness and because an orphaned
core.json still referencing the 20-char platform_id could plausibly
contribute to the section-5 openFPGA crash on its own. Likewise
/Settings/mhlin.AnalogueMusicPlayer/ (persisted interact/input/video state)
is now orphaned and removed. See NEXT_STEPS.txt step 1 for the combined
delete command (covers both this and section 5's cleanup).

DEFERRED (NOT done, per user's "leave a note for next build" option): the
repo folder Analogue_MusicPlayer/ and this project's doc filenames
(MUSICPLAYER_NOTES.txt, NEXT_STEPS.txt, plans/, prompts/ - all still say
"Analogue_MusicPlayer"/"MusicPlayer" inconsistently) were NOT renamed. This
is purely a local dev-machine/git concern - it has ZERO effect on what gets
deployed to the SD card (only dist/'s contents matter for that, and those ARE
renamed above). Renaming the repo folder itself would mean `git mv` across
~180 tracked files including the 162MB debug dump, plus updating every path
reference in CLAUDE.md, POCKET_CORE_NOTES.txt, and this file. Recommended:
do this AFTER section 5+6's SD-facing fix is confirmed working on hardware,
as its own isolated, easily-reviewed commit (so a bad outcome on the next
hardware test isn't conflated with an unrelated bulk file-rename).

STATUS: combined with section 5 - CONFIRMED (section 7). Repo folder rename
(deferred per the note above) is now DONE - see section 9 (2026-06-16).


--------------------------------------------------------------------------------
7. FINAL HARDWARE CONFIRMATION (2026-06-15): combined platform_id-shortening +
   rename fix - audio AND openFPGA menu both working
--------------------------------------------------------------------------------
RESULT (user report, 2026-06-15, after redeploying the combined section 5+6
fix and cleaning up orphaned SD files): "this time it worked as expected. The
platform and cores lie perfectly in the place they should be. ... the sound
works perfectly this time with the gray screen."

EVIDENCE from the fresh SD debug dump (MusicPlayer/debug/AP/):
  - System/Logs/mhlin.MusicPlayer_20260615_202045.txt shows the full slot
    load succeeding:
      Checking file /Assets/musicplayer/common/test_audio.bin
      Found, 192000 bytes
      ...
      Slot: load done
    (vs. the broken 20260615_183322.txt log which had
    "/Assets/analogue_musicp/..." truncated to 0 bytes / "Start failed").
  - No error/crash logs present in the dump - openFPGA browse completed
    without the flash-loop.

CONCLUSION: both section 5 (platform_id length) and section 6 (project
rename) fixes are CONFIRMED CORRECT on real hardware. Nothing further needed
for this fix - dist/ matches the deployed SD card state.

"(WIP)" IN THE PLATFORM NAME (user question): "MusicPlayer (WIP)" is just the
display string in Platforms/musicplayer.json's "name" field (shown in the
openFPGA > Music Players menu) - purely cosmetic, added when the platform
file was first created (section 4) to signal "work in progress" since only
Module 2a (a silent-by-default audio test with a gray screen, no UI) exists
so far. It has no functional effect. Recommend keeping it until the
multi-tab UI (prompt_000.txt / plans/UI_SPEC.md) is further along, then drop
it as a one-line edit to Platforms/musicplayer.json's "name" field as part of
a later "release polish" pass - no rush either way.

STATUS: DONE. Module 2b (PSRAM-backed audio buffer) is source-complete - see
section 8.


--------------------------------------------------------------------------------
8. MODULE 2b: PSRAM-BACKED AUDIO BUFFER, ONE-SHOT LONGER CLIP
   (HARDWARE-CONFIRMED WORKING, 2026-06-16)
--------------------------------------------------------------------------------
GOAL: replace Module 2a's on-chip-BRAM 1-second loop with a PSRAM (cram0)
-backed buffer holding ~43.69s of audio (all of cram0's 8MB), while keeping
the same ONE-SHOT load semantics (audio_loader streams the whole buffer once
at boot via the SD-card dataslot, then it loops forever). This isolates the
new risk - PSRAM read latency + clock-domain-crossing into the real-time I2S
consumer - from continuous-refill streaming (Module 2c, later). Plan file:
C:\Users\minhao\.claude\plans\twinkly-rolling-peacock.md

NUMERIC DESIGN: cram0 = 2^22 sixteen-bit words = 2^21 stereo frames @
48kHz/16-bit = 8,388,608 bytes (0x800000) ~= 43.691s. AUDIO_NUM_SAMPLES =
2097152, AUDIO_AW = 21. Each stereo frame occupies 2 PSRAM words: left sample
at word address 2*frame_idx, right sample at 2*frame_idx+1 - a clean fit, no
remainder.

NEW FILE core/psram.sv: copied VERBATIM from
ImageViewer/open-fpga-core-template-da3a021/src/fpga/core/psram.sv (MIT,
agg23/analogue-pocket-utils port) - already Quartus-clean at 133.12MHz and
hardware-confirmed (~20-24MB/s single-access read) from the since-removed
ImageViewer PSRAM test.

NEW FILE core/psram_audio_buffer.sv (replaces + deletes audio_ram.sv): single
module wrapping one `psram` instance (bank_sel=0, cram0), exposing the SAME
external interface as audio_ram.sv (wr_clk/bridge_wr/bridge_addr/
bridge_wr_data, rd_clk/rd_addr/rd_data) plus clk_psram_133 and two status
outputs psram_test_done/psram_test_pass. Three phases, temporally disjoint by
construction so the single psram instance needs only a simple priority mux
(no real arbiter):
  - Phase A (self-test, gated on `reset`): write+read-back 4 address/data
    vectors spanning the 22-bit address range (0x000000, 0x00000F, 0x3FFFFF,
    0x155555 with patterns AAAA/5555/F0F0/0F0F). ISSUE->LAUNCH->POLL FSM per
    transaction (LAUNCH absorbs the 1-cycle delay before psram.sv's
    busy/read_avail reflect a new request - same pattern as the b659f97
    ImageViewer test). ~10 transactions, ~1us @133MHz. Sets psram_test_done=1
    and psram_test_pass (1 if all 4 vectors matched).
  - Phase B (one-shot load, gated on psram_test_done): clk_74a-domain bridge
    writes in [BASE_ADDR, BASE_ADDR+NUM_SAMPLES*4) are byte-reversed exactly
    as audio_ram.sv did, latched with a toggle bit, crossed to clk_psram_133
    via synch_3, and turned into 2 sequential 16-bit psram writes (word addrs
    2*frame_idx, 2*frame_idx+1). No FIFO - PSRAM write throughput (~12
    cycles/word @133MHz) is orders of magnitude faster than dataslot writes
    arrive via the SPI bridge, so the single-buffer latch is never overrun.
  - Phase C (playback, gated on psram_test_done): rd_addr (=audio_addr)
    changes are detected in the rd_clk (audgen_sclk) domain, toggle-crossed
    to clk_psram_133 via synch_3, which issues 2 sequential 16-bit reads and
    returns the assembled 32-bit frame via a toggle-crossed ack back to
    rd_clk. Budget: audio_addr's new value must be ready ~32 audgen_sclk
    cycles (~10.4us) after it changes (the next lrck half-cycle that consumes
    audio_frame[15:0]); the actual round trip is ~200ns - large margin.
  - Phase B and C can never overlap: Phase C's first rd_req_pulse can't fire
    until audio_addr starts advancing, which requires audio_loaded
    (= audio_load_loaded && psram_test_pass), which requires Phase B's last
    write to have completed (audio_load_loaded only asserts once the SD-card
    dataslot transfer is fully done).

core_top.v CHANGES:
  - Added `wire clk_psram_133;` and `.outclk_2(clk_psram_133)` to the
    existing mf_pllbase mp1 instantiation (outclk_0/outclk_1 unchanged;
    mf_pllbase.v already declared outclk_2 at 133.119989MHz, no IP
    regeneration needed).
  - Removed the cram0_* tie-off assigns (now driven by psram_audio_buffer);
    cram1_* tie-offs untouched.
  - AUDIO_NUM_SAMPLES 48000 -> 2097152, AUDIO_AW 16 -> 21. audio_addr
    wraparound literal updated from 16'd0 to {AUDIO_AW{1'b0}}.
  - Replaced the audio_ram + audio_loader instantiation with
    psram_audio_buffer (NUM_SAMPLES=AUDIO_NUM_SAMPLES, BASE_ADDR=
    32'h2000_0000, all cram0_* pins) + audio_loader with
    AUDIO_BYTES=32'd8388608. audio_loaded gated on
    audio_load_loaded && psram_test_pass (silent forever if the PSRAM
    self-test fails - same "silence = storage/loader problem" diagnostic
    category as Module 2a).

ap_core.qsf: added core/psram.sv and core/psram_audio_buffer.sv as
SYSTEMVERILOG_FILE (before audio_loader.sv); removed the audio_ram.sv line.
audio_ram.sv deleted (recoverable from git history).

data.json (both MusicPlayer/open-fpga-core-template-da3a021/data.json
and dist/Cores/mhlin.MusicPlayer/data.json): "Test Audio" slot (id 16)
size_exact 0x2EE00 -> 0x800000.

tools/convert_audio.py: added NUM_SAMPLES=2097152 constant; --seconds default
changed from 1.0 to None (defaults to the full 2097152-frame buffer);
docstring/print updated for Module 2b. Re-ran it -> regenerated
dist/Assets/musicplayer/common/test_audio.bin = 8,388,608 bytes (2097152
frames @ 48000Hz, 43.691s) from source_musics/ITZY/Boys Like You (2022)/01 -
Boys Like You.flac (zero-padded - the source track is shorter than 43.69s).

SDC: no changes needed/expected - core_constraints.sdc already has
set_clock_groups -asynchronous separating clk_74a, clk_74b, and each
mf_pllbase output (including general[2]/outclk_2/clk_psram_133) into separate
groups, so the new clk_74a<->clk_psram_133 and audgen_sclk<->clk_psram_133
CDCs are already covered. Sanity-check after compile that no new
unconstrained-path warnings appear for clk_psram_133.

DIAGNOSTIC TREE for the hardware test (per the plan):
  - Silence -> psram_test_pass=0 or the data-slot load failed (check the
    debug log for "Start failed"/loadsize, as in Module 2a).
  - Noise/garbled audio or audible dropouts/glitches throughout playback ->
    Phase C (read-side CDC) isn't completing within one audgen_sclk
    half-period - the core new risk this module tests.
  - Glitches only at specific fixed points in the loop -> Phase B (load-side)
    corruption - revisit the single-buffer-vs-FIFO assumption.
  - Clean ~43.7s loop (vs. Module 2a's 1s loop) -> Module 2b CONFIRMED, Module
    2c (continuous SD-card refill, ring buffer + producer FSM) is next.

HARDWARE TEST RESULT (2026-06-16): compiled clean (no warnings reported for
psram.sv/psram_audio_buffer.sv/clk_psram_133/cram0_*), redeployed to the SD
card, and ran on the Pocket. Result: the ~43.7s "Boys Like You" clip plays
all the way through with normal sound (no noise/garbling/dropouts/glitches),
then loops cleanly - per the diagnostic tree above, this is the "Clean ~43.7s
loop" outcome, i.e. Module 2b CONFIRMED. Volume Up/Down also work normally
during playback. This confirms: psram_test_pass=1 (Phase A self-test passed,
otherwise silence), Phase B's one-shot load completed without corruption (no
fixed-point glitches), and Phase C's read-side CDC handshake reliably meets
its ~10.4us budget (no dropouts/garbling) - the core new risk this module was
built to test.

STATUS: DONE - HARDWARE-CONFIRMED WORKING. Module 2c (continuous SD-card
refill, ring buffer + producer FSM, for arbitrary song length) is next - see
NEXT_STEPS.txt.


--------------------------------------------------------------------------------
9. REPO FOLDER RENAME: Analogue_MusicPlayer/ -> MusicPlayer/ (DONE 2026-06-16)
--------------------------------------------------------------------------------
CONTEXT: section 6 (2026-06-15) renamed all SD-facing identifiers
("AnalogueMusicPlayer" -> "MusicPlayer") but deferred the repo folder itself
and this project's doc filenames, recommending it be done "AFTER section 5+6's
SD-facing fix is confirmed working on hardware, as its own isolated, easily-
reviewed commit". Module 2b's hardware confirmation (section 8) cleared that
condition, and the user requested the rename this session.

WHAT WAS DONE:
- Top-level repo folder Analogue_MusicPlayer/ -> MusicPlayer/. Most top-level
  items (MUSICPLAYER_NOTES.txt, NEXT_STEPS.txt, dist/, plans/, prompts/,
  tools/) moved via `git mv` cleanly as renames. source_musics/ (gitignored,
  5.2GB) moved via a plain filesystem move. debug/ and
  open-fpga-core-template-da3a021/ initially failed with "Permission denied"/
  "being used by another process" on the top-level Analogue_MusicPlayer/ entry
  (some other process - likely Windows Search/Defender indexing the large
  debug dump, or a transient handle on the Quartus project tree - briefly held
  it); debug/AP/ was moved one level down first (git mv succeeded), the
  now-empty debug/ was rmdir'd, and a retry of the whole
  open-fpga-core-template-da3a021/ directory then succeeded. Finally the
  empty Analogue_MusicPlayer/ was rmdir'd. No content was lost; git correctly
  recorded ~180 file renames.
- Updated path references: .gitignore (source_musics line), CLAUDE.md
  (6 references + the "active project" narrative, now reflects Module 2b
  CONFIRMED / Module 2c PLANNED / rename DONE), POCKET_CORE_NOTES.txt (2
  references in the platform_id section), and this file's own internal path
  references (PROJECT ROOT, prompts/plans, dist/, debug/, tools/, source
  track, data.json paths, the WHERE WE ARE summary).
- Historical sections (1-8) describing PAST states/decisions were left as
  accurate historical record where they describe what was true AT THE TIME
  (e.g. section 6's deferral rationale); only its STATUS line was updated to
  point here. prompts/prompt_000.txt's "Analogue_MusicPlayer (temporarily)"
  text and the two historical debug-log filenames containing
  "AnalogueMusicPlayer" (from section 6/7's pre-rename SD state) were left
  unchanged - they are dated artifacts of their own moment in history.

STATUS: DONE. Working tree is clean aside from this rename + the pre-existing
unrelated ap_core.qsf modifications (both ImageViewer's and MusicPlayer's
copies - neither touched by this rename). Committed as its own isolated
commit per section 6's recommendation.


--------------------------------------------------------------------------------
10. MODULE 2c: CONTINUOUS SD-CARD REFILL (ring buffer + producer FSM) - PLANNED
    2026-06-16, not yet implemented
--------------------------------------------------------------------------------
GOAL: replace Module 2b's one-shot ~43.7s buffer with a continuous ring buffer
fed by repeated target_dataslot_read chunk requests, so a song LONGER than
cram0's 8MB/43.7s capacity plays back-to-back without dropouts and loops the
whole song at the end - the architecture prompts/prompt_000.txt always called
for ("Streaming: Fetch WAV PCM data via target_dataslot_read with dynamic
offsets").

KEY DESIGN (full plan: C:\Users\minhao\.claude\plans\twinkly-rolling-peacock.md):
- RING_FRAMES = 2,097,152 = 2^21 (= cram0's full capacity, unchanged from
  Module 2b - psram_audio_buffer.sv needs ZERO changes). RING_SLOTS=16,
  CHUNK_FRAMES = 131,072 (0.5MB, ~2.73s/chunk).
- Test song: full "01 - Boys Like You.flac" (223.373s), padded to NUM_CHUNKS=
  82 chunks (~3:44, ~41MB, ~5.1x cram0's capacity - exercises ~5 ring refills
  plus a song-loop wraparound per playthrough).
- New module audio_streamer.sv (replaces audio_loader.sv): producer FSM
  tracking chunk_idx (song position, wraps at 82), chunks_written (ring slot
  to write), chunks_in_flight (ring fullness via a toggle+synch_3
  slot_consumed_pulse from the consumer - safe because chunk boundaries are
  ~2.73s apart, vastly slower than either clock domain).
- core_top.v: audio_addr becomes a free-running 21-bit counter (natural 2^21
  overflow = ring wrap); detect audio_addr[20:17] changes -> toggle pulse to
  the producer; audio_loaded = initial_fill_done && psram_test_pass.
- data.json "Test Audio" slot size_exact -> 0x2900000 (82 * 0x80000 = 42,991,616 bytes;
  the plan file had a hex typo of 0x28F0000 - the decimal 42,991,616 was correct).
- convert_audio.py: new full-song padded-conversion mode, prints NUM_CHUNKS.

KNOWN LIMITATION (accepted for this de-risking module): no explicit underrun
stall - if the producer falls behind, audio_addr reads a stale chunk (glitch/
repeat, not silence/crash) - a diagnosable symptom, not a hang. NUM_CHUNKS=82
is a compile-time constant tied to this test file; per-song variable length
comes with the future UI/library.

STATUS: PLANNED (plan approved 2026-06-16). Source implementation not yet
started - see NEXT_STEPS.txt.


--------------------------------------------------------------------------------
11. MODULE 2c SOURCE IMPLEMENTATION (2026-06-16) - AWAITING HARDWARE TEST
--------------------------------------------------------------------------------
CONTEXT: Section 10 is the plan; this section records what was actually built.

FILES CHANGED:
- NEW: core/audio_streamer.sv (replaces audio_loader.sv):
    Producer FSM in clk_74a domain. States: REQ -> WAIT_CLEAR -> WAIT_DONE ->
    REQ (loops per chunk, same APF bridge protocol as audio_loader). Tracks:
    - chunk_idx [6:0]: song position 0..81, wraps to 0 after chunk 81.
    - chunks_written [7:0]: ever-incrementing; [3:0] = slot_idx (ring write
      destination). Natural 8-bit overflow is harmless.
    - chunks_in_flight [4:0]: confirmed-written but not-yet-consumed slots
      (0..16). Incremented on WAIT_DONE completion; decremented via
      slot_consumed_pulse.
    - initial_fill_done: set once (chunks_written == 15 upon chunk 15's
      completion), stays high. Same role as audio_load_loaded / 'loaded' in
      Modules 2a/2b.
    Key: `do_consume` wire reads chunks_in_flight combinatorially; WAIT_DONE
    does `chunks_in_flight + 1 - do_consume` as a single NB assignment so
    simultaneous completion+consume is handled correctly (no last-wins hazard).

- MODIFIED: core/core_top.v:
    1. Declarations: audio_load_loaded -> initial_fill_done; added
       slot_consumed_tog (reg, audgen_sclk), slot_consumed_tog_s (synch_3
       output, clk_74a), slot_consumed_tog_s_r (edge-detect reg), and
       slot_consumed_pulse = tog_s XOR tog_s_r (1-cycle clk_74a pulse).
    2. audio_loaded = initial_fill_done && psram_test_pass (unchanged usage).
    3. audgen_sclk block: audio_addr becomes `audio_addr + 1'b1` (free-running
       21-bit, natural 2^21 overflow = ring wrap; explicit AUDIO_NUM_SAMPLES-1
       compare removed - it was already redundant). When audio_addr[16:0] ==
       17'h1FFFF (last frame of the current ring slot), slot_consumed_tog ^= 1.
    4. Audio_loader instance replaced with audio_streamer instance (same port
       wiring for the APF bridge signals; adds slot_consumed_pulse in /
       initial_fill_done out).
    5. synch_3 s_slot instance added (slot_consumed_tog -> slot_consumed_tog_s,
       clk_74a); always_ff for slot_consumed_tog_s_r edge-detect.

- MODIFIED: ap_core.qsf: audio_loader.sv -> audio_streamer.sv.

- MODIFIED: data.json (dev copy + dist/Cores/mhlin.MusicPlayer/data.json):
    "Test Audio" slot size_exact: 0x800000 -> 0x2900000 (82 * 0x80000 = ~41MB).

- MODIFIED: tools/convert_audio.py:
    - Added CHUNK_BYTES = 524288 (0x80000) constant.
    - Added --full flag: decode full track, pad UP to multiple of CHUNK_BYTES,
      print NUM_CHUNKS and the expected size_exact hex for data.json.
    - Default (no --full) behavior unchanged: trim/pad to NUM_SAMPLES frames.

TIMING ANALYSIS (why underrun is unlikely):
- SD read bandwidth: ~20-24MB/s (confirmed Module 2b). Chunk size 0.5MB:
  load time ~25ms. Slot lifetime ~2.73s @ 48kHz. Producer has ~109x margin.

WHAT NEEDS TO HAPPEN BEFORE HARDWARE TEST:
1. `cd MusicPlayer && py tools/convert_audio.py --full` (generates ~41MB
   test_audio.bin; verify NUM_CHUNKS=82 printed).
2. Recompile in Quartus (ap_core.qpf) - will pick up audio_streamer.sv,
   drop audio_loader.sv.
3. `py tools/make_rbf_r.py` (bit-reverse the .rbf).
4. Copy dist/ to SD card (test_audio.bin is ~41MB; SD copy takes longer).
5. Run on Pocket and report back per the diagnostic tree (section 10).

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16, section 12).

================================================================================
12. MODULE 2c HARDWARE TESTS + PSRAM BUS ARBITRATION FIX (2026-06-16)
================================================================================

CONTEXT/GOAL: Hardware-test Module 2c (section 11). Two test iterations.

TEST 1 (bitstream not updated):
- Symptom: 43.7s audio loop repeating identically.
- Diagnosis: Log showed `len 0x00800000` (8MB) = old Module 2b audio_loader
  bitstream still on SD. Quartus compile had not been completed yet.
- Fix: completed Quartus compile + make_rbf_r.py.

TEST 2 (correct Module 2c bitstream):
- Symptom: ~3 seconds of clean audio then silence for at least 1 minute.
- Log (174133): 47 consecutive chunk requests, all `len 0x00080000` (0.5MB).
  FSM correct, slot_consumed_pulse working, ring refill working. 47 chunks =
  initial 16 + 31 refills = audio_streamer is completely functional.
- Root cause: psram_audio_buffer.sv Phase B / Phase C bus contention.
  In Module 2b, Phase B (bridge writes) was a one-shot load that finished
  BEFORE audio started, so Phase B and Phase C (PSRAM reads) never ran at
  the same time. In Module 2c (ring buffer), Phase B runs continuously
  DURING audio playback. The PSRAM bus mux gives Phase B priority:
    psram_read_en = testA_active ? ... : (loadB_active ? 1'b0 : playC_read_en)
  When Phase B took the bus while Phase C was in PC_R0_LAUNCH (the 1-cycle
  window when it issues psram_read_en), the read command was silently dropped
  by the mux. Phase C then stalled in PC_R0_POLL waiting for psram_read_avail
  that could never arrive. audio_frame froze. Silence.
  Timing: first ring refill fires ~2.73s after audio_loaded → first collision
  possible at ~2.73s ≈ "3 seconds" reported by user.

FIX (psram_audio_buffer.sv, 2026-06-16):
1. Phase B (LB_IDLE → LB_W0_ISSUE): added `playC_state == PC_IDLE` guard.
   Phase B now waits for Phase C to be between reads before starting any
   PSRAM write. Added `wr_req_pending` register to latch pulses that arrive
   while Phase C is busy (prevents lost bridge writes).
2. Phase C (PC_R0_ISSUE, PC_R1_ISSUE): added `!loadB_active` guard.
   Phase C now waits for Phase B to be idle before issuing each PSRAM read
   command. Belt-and-suspenders with fix #1.
Together: Phase B and Phase C run exclusively - no interleaved PSRAM
transactions. Performance impact negligible (Phase C reads: ~90ns; Phase B
writes: ~180ns; bridge write interval: ~400ns+; audio frame period: 20.8us).

TEST 3 (PSRAM arbitration fix applied):
- Log (181433, 2026-06-16): 82 chunks streamed (slotoffset 0x00 through
  0x2880000 = full 41MB song), then song-loop wrap: slotoffset resets to
  0x0000000000 (chunk_idx=0) and streaming continues from the start.
  User confirmed: full ~3:44 song played clean, seamlessly looping.
- All three Module 2c risks resolved: (1) initial fill ✓, (2) continuous
  ring refill during playback ✓, (3) PSRAM Phase B/C arbitration ✓.

STATUS: MODULE 2c HARDWARE-CONFIRMED WORKING (2026-06-16).


================================================================================
13. MODULE 3a: FULL-SCREEN DISPLAY - 400x360 / 10:9 (source done, awaiting
    hardware test)
================================================================================

GOAL: Eliminate the black bars caused by the 320x240 / 4:3 video mode.
The Pocket's native screen is 1600x1440 (10:9 aspect). The scaler fills the
screen only when the declared aspect matches 10:9. The natural integer-scale
target is 400x360 (4x to 1600x1440).

MATH (key insight - no PLL change needed):
- Existing pixel clock: clk_core_12288 = 12.288 MHz (PLL outclk_0, unchanged).
- Old total: H_TOTAL(400) x V_TOTAL(512) = 204,800 clocks/frame = 60fps.
- New total: H_TOTAL(512) x V_TOTAL(400) = 204,800 clocks/frame = 60fps.
- Same total clock budget, just redistributed: more H blanking, less V blanking.

CHANGES (source done 2026-06-16):
1. core_top.v localparams:
     VID_H_ACTIVE: 320 -> 400
     VID_V_ACTIVE: 240 -> 360
     VID_H_TOTAL:  400 -> 512
     VID_V_TOTAL:  512 -> 400
2. video.json (both dev-copy and dist/):
     width: 320 -> 400, height: 240 -> 360
     aspect_w: 4 -> 10, aspect_h: 3 -> 9

Screen content was still the gray fill from Module 2c at confirmation time.
Module 3b (progress bar, section 14) builds on this confirmed canvas.

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16). Gray screen fills the
entire Pocket display with no black bars. Audio unaffected.


================================================================================
14. MODULE 3b: PLAYBACK PROGRESS BAR (HARDWARE-CONFIRMED 2026-06-16)
================================================================================

GOAL: Replace the gray fill with a dark background and a horizontal progress
bar that advances as the song plays. First real dynamic visual linked to audio.

DESIGN:
- Background: 24'h0D0D1A (dark navy)
- Separator line at visible_y=339: 24'h1E1E30 (slightly lighter)
- Progress bar at visible_y=340..349 (10px tall, full width):
    - Played portion (visible_x < bar_fill_x): 24'h00B4D8 (sky blue)
    - Remaining portion: 24'h1E1E30 (dark track)
- bar_fill_x = (chunks_played * 39) >> 3  -> 0..399px for 0..82 chunks.
  No hardware divider needed (39/8 ≈ 400/82 exactly at chunk 82 → 399px).

IMPLEMENTATION (core_top.v only):
1. chunks_played counter (clk_74a domain): 7-bit, driven by slot_consumed_pulse,
   wraps at 81→0 (NUM_CHUNKS=82 song loop). Each tick = ~2.73s.
2. 2-FF synchronizer (chunks_played_s1/s2, clk_core_12288 domain): safe for a
   value that changes every 2.73s.
3. bar_mul wire: 13'd39 * {6'b0, chunks_played_s2}; bar_fill_x = bar_mul[12:3].
4. Video always block: bar_fill_x, chunks_played_s1/s2 updated each cycle;
   draw logic using visible_x/visible_y.

TEST RESULT (log mhlin.MusicPlayer_20260616_215802.txt):
Dark navy background and cyan progress bar confirmed. Bar advanced every ~2.73s
as expected. Log captures the full 82-chunk song + loop wrap + well into the
second cycle (115 total chunk reads before user exited), audio clean throughout.

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16).


================================================================================
15. MODULE 3c: FONT ROM + STATIC TEXT (HARDWARE-CONFIRMED 2026-06-16)
================================================================================

GOAL: Prove the bitmapped font ROM works end-to-end before wiring dynamic
metadata. Display "BOYS LIKE YOU   " (16 chars) as white 8x8 pixels on the
dark navy background. Font ROM is the permanent architecture for all future
text rendering (track name, artist, album, time).

DESIGN:
- font_rom.v: new module, combinational always@(*) case statement covering all
  printable ASCII (0x20-0x7F). Input: char_code [7:0], row [2:0].
  Output: pixels [7:0], bit 7 = leftmost pixel. Inferred as LUTs (~256 ALMs,
  <1% of 5CEBA4 at 12.288 MHz - very relaxed timing).
- Text position: x=136..263, y=165..172 (centered horizontally on 400px screen;
  vertically centered above separator in the 339px content area).
  16 chars * 8px = 128px; (400-128)/2 = 136. y=165 ≈ (339-8)/2.
- Pipeline: font_pixels is combinational (no clock). font_pixel_lit wire is
  evaluated inside the always@(posedge clk_core_12288) block, meaning the
  white pixel decision is captured alongside other vidout_rgb decisions with
  no extra latency. Correct for 12.288 MHz pipelined video.
- Pixel selection: font_pixels[3'd7 - char_col] → bit 7 = leftmost (col 0),
  bit 0 = rightmost (col 7).

CORE_TOP.V CHANGES:
1. Declarations: TEXT_X_START/TEXT_Y_START localparams; text_offset_x/y,
   char_idx[3:0], char_col/char_row[2:0], in_text_area, test_char[7:0],
   font_pixels[7:0], font_pixel_lit wires.
2. Video block: `if (font_pixel_lit) vidout_rgb <= 24'hFFFFFF;` inserted after
   navy background, before separator/bar checks (so separator/bar override it
   if they overlap - but text at y=165..172 is well above y=339/340).
3. font_rom instantiation (u_font_rom) connecting test_char, char_row, font_pixels.
4. `always @(*)` case on char_idx driving test_char (hard-coded string).

NEW FILES:
- core/font_rom.v: 8x8 ASCII font ROM (combinational, all printable ASCII).

QSF CHANGE:
- Added `set_global_assignment -name VERILOG_FILE core/font_rom.v` after core_top.v.

EXPECTED ON HARDWARE:
- Dark navy background (unchanged).
- "BOYS LIKE YOU   " in white 8x8 pixels, centered horizontally, ~midscreen.
  At 4x scale on Pocket: 32x32px per character, 512px wide total string.
- Progress bar (cyan, y=340..349) unchanged.
- Audio unchanged.

HARDWARE TEST RESULT (log 225441):
- "BOYS LIKE YOU   " displayed in white 8x8 pixels, centered horizontally.
  User confirmed: "The fonts looks amazing."
- Audio clean: 115 chunks (82 initial song + song-loop wrap + continued
  refill), no glitches or regressions. Ring-buffer streaming unaffected.
- Progress bar (cyan, y=340..349) unchanged.

NEXT:
- Module 3d: Replace hard-coded test_char case with a small bridge-writable
  string RAM, so Chip32 can push dynamic track metadata to the display.

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16).


================================================================================
18. MODULE 3f: MULTI-TRACK AUDIO SWITCHING - CONCATENATED FILE
    (source done, awaiting audio prep + hardware test)
================================================================================

GOAL: When user changes Track in interact menu, audio switches to the
corresponding song after a brief gap while the ring buffer refills.
Text display already switches live (Module 3e). This module proves the
full stack end-to-end.

ARCHITECTURE (Option B - concatenated file):
- One test_audio.bin holds all tracks back-to-back, each padded to a chunk
  boundary (CHUNK_BYTES = 0x80000). Per-track offsets are compile-time
  localparams in core_top.v and audio_streamer.sv parameters.
- interact "Track" bridge write (0xF3000010) now writes BOTH text_ram
  and track_sel[1:0], which feeds audio_streamer.track_select.

KEY DESIGN POINTS:
- audio_streamer.sv (full rewrite): new track_select[1:0] input. Track change
  detected in REQ state only (never aborts an in-progress SD read). On change:
  soft-reset ring (chunk_idx = new start, chunks_written/in_flight = 0,
  initial_fill_done = 0). Placeholder params: TRACK1_CHUNKS=82, TRACK2_CHUNKS=82
  - update after running convert_audio.py --concat.
- core_top.v: initial_fill_done now synchronized into audgen_sclk via new
  synch_3 s_fill (was unsynced level - safe for one-shot startup but risky
  for repeated track-change toggles). audio_loaded = initial_fill_done_s && psram_test_pass.
- core_top.v audgen_sclk block: else audio_addr <= 0 added so audio_addr
  resets to 0 while !audio_loaded. Ring is filled from slot 0 on each track
  start, so audio_addr=0 correctly lands on the first frame.
- core_top.v chunks_played: resets on track change via track_sel_r_core edge
  detect; wraps at cur_track_chunks (per-track length) for correct progress bar.
- Silence gap: ~16 chunks x 2.73s loading time from SD before new track plays.

FILES CHANGED:
- audio_streamer.sv: full rewrite; removes NUM_CHUNKS, adds track_select,
  TRACK*_START/CHUNKS params, track_sel_r, cur_start/cur_len combinational.
- core_top.v: TRACK* localparams, track_sel reg + bridge write, synch_3 s_fill,
  audio_streamer instantiation update, audio_addr reset, chunks_played update.
- tools/convert_audio.py: added --concat mode.

PRE-TEST WORKFLOW (must complete before hardware test):
1. Provide 2 additional audio source files.
2. Run convert to build concatenated file (single-line PowerShell):
   py "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer\tools\convert_audio.py" --concat "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer\dist\Assets\musicplayer\common\test_audio.bin" "song0.flac" "song1.flac" "song2.flac"
3. Script prints TRACK*_START, TRACK*_CHUNKS per track, and size_exact.
   Update core_top.v localparams (TRACK1_START, TRACK1_CHUNKS, TRACK2_START,
   TRACK2_CHUNKS) and both data.json files (size_exact).
4. Recompile in Quartus + make_rbf_r.py + copy dist/ to SD.

EXPECTED ON HARDWARE:
- Track 0 loads and plays as before.
- Changing Track in interact menu to "Song Two": brief silence (~40s) while
  ring refills from SD, then new audio plays. Display already shows new title.
- Same for "Song Three". Switching back restarts Boys Like You from beginning.
- Progress bar resets to 0 on each track change.

STATUS: SOURCE DONE, AWAITING AUDIO PREP + HARDWARE TEST.


================================================================================
16. MODULE 3d: BRIDGE-WRITABLE STRING RAM (HARDWARE-CONFIRMED 2026-06-16)
================================================================================

GOAL: Replace the hard-coded "BOYS LIKE YOU   " combinational case with a
16-byte register array writable via APF bridge, so future Chip32 code can
push dynamic track metadata (title, artist, etc.) to the display at runtime.

DESIGN:
- `reg [7:0] text_ram [0:15]` in core_top.v (clk_74a domain).
- Initialised on reset to "BOYS LIKE YOU   " (same as Module 3c), so the
  display works correctly before any bridge write is issued.
- `font_rom u_font_rom` now takes `.char_code(text_ram[char_idx])` directly -
  combinational read from the register array, safe because text updates are
  extremely infrequent (track-change timescale >> video clock period).
- Bridge-write handler at `always @(posedge clk_74a or negedge reset_n)`:
  4 chars packed per 32-bit bridge word, big-endian (bridge_endian_little=0):
    0xF3000020: chars 0-3  (bridge_wr_data[31:24..7:0])
    0xF3000024: chars 4-7
    0xF3000028: chars 8-11
    0xF300002C: chars 12-15

CORE_TOP.V CHANGES:
1. `reg [7:0] test_char` -> `reg [7:0] text_ram [0:15]` (declaration).
2. font_rom `.char_code(test_char)` -> `.char_code(text_ram[char_idx])`.
3. Removed: `always @(*) case(char_idx) ... endcase`.
4. Added: `always @(posedge clk_74a or negedge reset_n)` block with reset
   init + bridge_wr case for 0xF3000020/24/28/2C.

HARDWARE TEST EXPECTATION:
- Display still shows "BOYS LIKE YOU   " (from reset init) - proving the
  text_ram register-read path into font_rom works correctly.
- Audio, progress bar, video timing: all unchanged.
- Bridge_wr path confirmed correct by code review; dynamic writes tested
  when Chip32 code is added in a later module.

HARDWARE TEST RESULT (log 232645):
- "BOYS LIKE YOU   " displayed correctly from reset init - text_ram
  register-read path into font_rom confirmed working at video timing.
- Audio clean (chunk reads flowing from line 117). No regressions.

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16).


================================================================================
17. MODULE 3e: INTERACT.JSON TRACK SELECT -> DYNAMIC TEXT UPDATE
    (HARDWARE-CONFIRMED 2026-06-16)
================================================================================

GOAL: Prove end-to-end dynamic text update: user picks a track in the Pocket
interact menu -> APF framework issues bridge_wr to 0xF3000010 -> core_top
decodes index -> text_ram updates -> display changes in real time.

DESIGN:
- interact.json: one "list" variable "Track", id=1, address=0xF3000010,
  persist=true, writeonly=true, defaultval=0. Three options:
    0: "Boys Like You"  -> displays "BOYS LIKE YOU   "
    1: "Song Two"       -> displays "SONG TWO        "
    2: "Song Three"     -> displays "SONG THREE      "
- APF framework writes `value` field (0/1/2) of selected option as a 32-bit
  word to 0xF3000010 on every selection change (and at core startup for
  defaultval). bridge_wr_data[7:0] carries the index.
- core_top.v: new `32'hF3000010` case inside the existing bridge_wr handler.
  Nested case on bridge_wr_data[7:0] writes all 16 text_ram bytes for the
  selected title. Default case writes spaces (future-proof).
- No bitstream change needed for the interact.json defaultval write at
  startup: it fires the 0xF3000010 case with value=0, re-writing "BOYS LIKE
  YOU   " (same as reset init, no visible change on first load).
- persist=true: Pocket remembers the last Track selection across sessions.

FILES CHANGED:
- core_top.v: 0xF3000010 case added (46 lines) before 0xF3000020.
- interact.json (source + dist): was empty [], now has 1 variable.

HARDWARE TEST:
- Core loads: "BOYS LIKE YOU   " displayed (defaultval=0 fires at startup).
- Open interact menu -> change Track to "Song Two" -> display updates to
  "SONG TWO        " immediately (no reboot needed).
- Change to "Song Three" -> "SONG THREE      " appears.
- Cycle back to "Boys Like You" -> original text restored.
- Audio plays throughout with no interruption.

HARDWARE TEST RESULT (log 235053):
- Line 60: "Interact: Added element ID [1] name [Track]" — interact.json loaded.
- Lines 97-100: APF wrote defaultval 0x00000000 to 0xF3000010 at startup;
  "BOYS LIKE YOU   " displayed correctly on first load.
- User changed Track selection in interact menu -> display updated live to
  "SONG TWO        " then "SONG THREE      " then back, with no reboot.
- Audio (Boys Like You) continued uninterrupted throughout all selections
  (expected — audio switching not yet implemented).

STATUS: HARDWARE-CONFIRMED WORKING (2026-06-16).


================================================================================
18. MODULE 3f: MULTI-TRACK AUDIO SWITCHING - CONCATENATED FILE
    (source done, awaiting audio prep + hardware test)
================================================================================

GOAL: When user changes Track in interact menu, audio switches to the
corresponding song (after a brief gap while the ring buffer refills with
the new track's first 16 chunks). Text display already switches live
(Module 3e). This module proves the full stack end-to-end.

ARCHITECTURE (Option B - concatenated file):
- One test_audio.bin holds all tracks back-to-back, each padded to chunk
  boundary (CHUNK_BYTES = 0x80000). Per-track offsets are compile-time
  localparams (TRACK*_START, TRACK*_CHUNKS) in core_top.v and audio_streamer.
- data.json slot 16 size_exact updated to total file size.
- interact "Track" list (0xF3000010) now also writes track_sel[1:0], wired
  to audio_streamer.track_select. Same bridge_wr updates both text and audio.

KEY DESIGN POINTS:
- audio_streamer.sv: new track_select[1:0] input. Track change detected in
  REQ state only (avoids aborting in-progress SD reads). On change: soft-reset
  ring (chunk_idx = new track start, chunks_written/in_flight = 0,
  initial_fill_done = 0). Wrap logic uses cur_start+cur_len per live track.
- core_top.v audio_loaded: initial_fill_done now synced into audgen_sclk via
  synch_3 s_fill (was unsynced level - fine for one-shot but risky for
  repeated track-change toggles). audio_loaded = initial_fill_done_s && psram_test_pass.
- core_top.v audgen_sclk block: added `else begin audio_addr <= 0; end` so
  audio_addr resets to 0 while !audio_loaded. New track's ring is filled from
  slot 0, so audio_addr=0 correctly points to the first frame of the new track.
- core_top.v chunks_played: resets to 0 on track change (track_sel_r_core
  detects edge); wrap uses cur_track_chunks[track_sel] for correct progress bar.
- Silence gap on track change: ~16 chunks x 2.73s/chunk (SD limited) until
  initial_fill_done goes high again and audio resumes.

FILES CHANGED:
- audio_streamer.sv: full rewrite - adds track_select, per-track params,
  track_sel_r for change detection in REQ, cur_start/cur_len combinational
  lookup. Removes old NUM_CHUNKS parameter.
- core_top.v: 6 changes - track_sel reg (written by 0xF3000010 bridge_wr),
  TRACK* localparams, audio_streamer instantiation update, synch_3 s_fill,
  audio_addr reset in audgen_sclk block, chunks_played track-change reset.
- tools/convert_audio.py: added --concat mode for concatenating multiple tracks.

PRE-TEST WORKFLOW (user must complete before hardware test):
1. Provide 2 additional audio source files (Songs Two and Three).
2. Run: py "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer	ools\convert_audio.py" --concat "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer\dist\Assets\musicplayer\common	est_audio.bin" song0.flac song1.flac song2.flac
3. Script prints per-track params. Update core_top.v localparams
   (TRACK1_START, TRACK1_CHUNKS, TRACK2_START, TRACK2_CHUNKS).
4. Update data.json size_exact in both source and dist.
5. Recompile + make_rbf_r.py + copy dist/.

STATUS: SUPERSEDED BY MODULE 3g (2026-06-17). Per-track params moved to
playlist.bin; no localparams needed.


--------------------------------------------------------------------------------
19. MODULE 3g: PLAYLIST.BIN - DYNAMIC PER-TRACK DATA (no recompile) (2026-06-17)
--------------------------------------------------------------------------------
CONTEXT/GOAL: Module 3f required updating compile-time localparams
(TRACK*_START, TRACK*_CHUNKS) in core_top.v after each convert_audio.py run.
Module 3g replaces those localparams with a runtime-loaded playlist.bin (slot
17), so adding or changing tracks only requires re-running the script and
copying .bin files to the SD card - no Quartus recompile.

WHAT WAS BUILT:
- New playlist_ram.sv: single-shot loader FSM (same WAIT_CLEAR/WAIT_DONE
  handshake as audio_streamer, confirmed working). Loads slot 17 (256 bytes
  max = 8 tracks x 32 bytes) to bridge address 0x21000000. Exposes
  track_start[15:0] / track_chunks[15:0] / track_name[127:0] combinatorially
  via a 64-word register file. Address decode: bridge_addr[31:8] == 24'h210000.
- playlist.bin format (32 bytes/track, big-endian APF delivery):
    Word 0: [31:16]=start_chunk, [15:0]=chunk_count
    Words 1-4: song_name (16 ASCII bytes, 4/word)
    Words 5-7: reserved zeros
- audio_streamer.sv: TRACK*_START/TRACK*_CHUNKS parameters removed. New ports:
    enable (wait for playlist_loaded before starting)
    track_select[2:0] (widened from 2-bit)
    cur_start[15:0], cur_chunks[15:0] (from playlist_ram, replacing localparams)
  chunk_idx widened to 16-bit (supports multi-track files up to ~8191 chunks
  = ~6.25 hours total @ 2.73s/chunk). New BOOT state: waits for enable=1
  before issuing first dataslot read, preventing a done-signal race with
  playlist_ram's boot load.
- core_top.v changes: removed TRACK* localparams; added pram_ds_*/as_ds_*
  wires + priority mux for target_dataslot_* (playlist_ram loads first, then
  audio_streamer takes over - they never overlap due to the BOOT state);
  bridge_wr 0xF3000010 case replaced 45-line nested title case with
  16 pram_name byte assignments; track_sel and track_sel_r_core widened to 3-bit;
  pram_read_idx mux gives playlist_ram the NEW track index during bridge_wr.
- convert_audio.py: concat mode now also generates playlist.bin alongside
  test_audio.bin. Derives song name from filename (strips leading track number,
  uppercases, pads/truncates to 16 bytes). Prints slot 16 and slot 17
  size_exact values separately.
- data.json (both source + dist): slot 17 added (address 0x21000000,
  size_exact 0x60 for 3 tracks = 96 bytes; update if track count changes).
- ap_core.qsf: playlist_ram.sv added as SYSTEMVERILOG_FILE.

WORKFLOW (to go from source-done to tested):
1. Re-run convert_audio.py --concat (fixes 2-track bug + generates playlist.bin)
2. Update data.json slot 16 size_exact from script output (both copies)
3. Recompile in Quartus + make_rbf_r.py + Copy-Item to SD
4. Hardware test: verify playlist loads, audio switches, title updates from bin

STATUS: SOURCE DONE (2026-06-17). Hardware test revealed playlist.bin undersize
bug - see section 20. Fix applied 2026-06-17. Awaiting re-test.


================================================================================
20. MODULE 3g HARDWARE TEST: playlist.bin UNDERSIZE BUG + FIX (2026-06-17)
================================================================================

HARDWARE TEST LOG: MusicPlayer_20260617_014605.txt
SYMPTOMS:
- No audio (silence throughout).
- Switching to track 2 or 3 in the interact menu: title text disappeared.

ROOT CAUSE (log lines 139-140):
  Target: Read to 0x21000000 from file 0x0000000000 len 0x00000100 bytes
  Target: Error servicing operation. Did you read too far?

playlist_ram.sv always requests target_dataslot_length = MAX_TRACKS*32 = 8*32 =
256 bytes (0x100). But convert_audio.py was generating playlist.bin at only
num_tracks*32 = 3*32 = 96 bytes (0x60). APF rejects any read request that
exceeds the file's size_exact, and never fires target_dataslot_done. Result:
playlist_loaded stays low, audio_streamer stays in BOOT state forever → silence.
Title disappears on track switch because pram_name is all zeros (register file
never populated), filling text_ram with 0x00 → font ROM shows blank pixels.

Note: test_audio.bin (slot 16) loaded correctly - log shows "Total loadsize is
114294880" = 3-track 218-chunk file, 0x6D00000 bytes. The convert_audio.py
concat fix (all 3 tracks) worked. Only playlist.bin was at fault.

FIX (no Quartus recompile required - Python + data.json only):
1. convert_audio.py: after building playlist entries, pad playlist_data with
   zeros to MAX_TRACKS * PLAYLIST_RECORD_SIZE = 8 * 32 = 256 bytes. Unused
   slot entries are zero-filled (chunk_count=0, name=spaces), harmless to FPGA.
   Added MAX_TRACKS=8 and PLAYLIST_RECORD_SIZE=32 as named constants (must match
   playlist_ram.sv MAX_TRACKS parameter).
2. data.json (both source + dist): slot 17 size_exact 0x60 → 0x100 (fixed for
   MAX_TRACKS=8; update_data_json() now always writes 0x100 for slot 17).

KEY LESSON: target_dataslot_length must never exceed the file's declared
size_exact (APF returns "Did you read too far?" and silently skips
target_dataslot_done). Best practice: always pad asset files to exactly the
size the FPGA will request, using zero bytes for unused space.

STATUS: FIX APPLIED (2026-06-17), AWAITING RE-TEST.


================================================================================
21. MODULE 3g SECOND HARDWARE TEST: playlist_ram FSM BUG + FIX (2026-06-17)
================================================================================

HARDWARE TEST LOG: MusicPlayer_20260617_020443.txt
SYMPTOMS: No audio. Title DID change on track switch (playlist data readable).
Both slots loaded correctly: playlist.bin 256 bytes (0x100) - undersize bug fixed.

ROOT CAUSE: playlist_ram.sv FSM did not match the confirmed APF handshake pattern.

The broken FSM held target_dataslot_read=1 continuously until done=1 fired
(in S_REQ), then waited for !done (in S_WAIT_CLEAR) to set loaded=1. This has
only 3 meaningful states (S_REQ/S_WAIT_CLEAR/S_DONE) but the APF handshake
requires 4: REQ (1-clock read pulse) / WAIT_CLEAR (!done) / WAIT_DONE (done) /
DONE. Holding read=1 while waiting for done may prevent APF from completing the
handshake correctly, so loaded never went high → audio_streamer stayed in BOOT.

The title changing DID work because the bridge_wr handler (separate from the
FSM) correctly captured pram[] writes from a previous or partial DMA - but
`loaded` was 0, so audio_streamer never exited BOOT.

FIX (playlist_ram.sv FSM rewritten to match audio_streamer exactly):
- Added default `target_dataslot_read <= 1'b0` at top of always block.
- S_REQ: pulse read for 1 clock, immediately → S_WAIT_CLEAR (no condition).
- S_WAIT_CLEAR: wait for !target_dataslot_done → S_WAIT_DONE.
- S_WAIT_DONE: wait for target_dataslot_done → S_DONE + loaded=1.
- Renamed S_UNUSED → S_WAIT_DONE (proper 4-state enum now).
Quartus recompile required (HDL change).

KEY LESSON: Any module using the APF target_dataslot_* handshake must use the
exact 4-state pattern: REQ (1-clock pulse) → WAIT_CLEAR (!done) → WAIT_DONE
(done) → done. Holding read=1 continuously or using a 3-state FSM breaks it.

STATUS: FIX APPLIED (2026-06-17); TEST 3 CONFIRMED AUDIO PLAYS (FSM fix worked)
but pram[] still zeros — see section 22 for the remaining pram bug and fix.


================================================================================
22. MODULE 3g THIRD HARDWARE TEST: pram[] RESET-GATED BUG + AUTO-ADVANCE FIX
    (HARDWARE-CONFIRMED Test 4, log _153746, 2026-06-17)
================================================================================

HARDWARE TEST LOG: MusicPlayer_20260617_025938.txt
SYMPTOMS (test 3 / log _025938):
- Audio played first song (Boys Like You, ~82 chunks) then continued into
  Cheshire automatically (no silent gap) - screen did NOT update.
- After interact track select: all track changes reset audio to chunk 0 (not
  to the selected track's start). Title disappeared (text_ram filled with zeros).
- Progress bar advanced correctly. audio_streamer FSM works (loaded=1 confirmed).

ROOT CAUSE: pram[] in reset-gated always block; APF fires done without re-DMAing.

The APF boot sequence writes playlist.bin to bridge address 0x21000000 during
the STATIC BOOT LOAD phase (log line 62: "File: Load 0x21000000 with 0x100
bytes from slot name [Playlist]"). This happens BEFORE Reset Exit (0x0011), while
the FPGA's user logic is in reset (reset=1).

In the old playlist_ram.sv, pram[] was in the reset-gated always block:
  always @(posedge clk or posedge reset) begin
    if (reset) pram[k] <= 0  (for all k)
    else ... pram[...] <= bridge_wr_data;
When reset=1, every posedge of clk_74a clears pram[] regardless of bridge_wr.
So the static boot load writes are completely lost.

After Reset Exit (reset=0), playlist_ram FSM enters S_REQ and pulses
target_dataslot_read=1 for slot 17 (playlist.bin). APF sees this request.
HOWEVER: APF fires target_dataslot_done=1 IMMEDIATELY, WITHOUT re-issuing new
bridge_wr writes. APF considers the data already delivered (it was sent during
static boot). No new bridge_wr → pram[] stays all zeros after Reset Exit.

Result of pram[] = all zeros:
- cur_chunks=0 for all tracks → audio_streamer wrap condition never fires
  (needs chunk_idx==65535) → chunk_idx increments forever through concatenated
  file → audio plays Boys Like You, then Cheshire, then Blah Blah Blah in one
  long stream (coincidentally matching the expected behavior, but wrong mechanism)
- cur_start=0 for all tracks → interact track change resets chunk_idx to 0
  (Boys Like You start) regardless of which track is selected
- pram_name=0x00 for all tracks → text_ram filled with 0x00 on track select
  → title disappears (font ROM shows blank for 0x00 ASCII code)

EVIDENCE IN LOG:
- Line 62: APF static boot load wrote playlist.bin to 0x21000000 (before Reset Exit)
- Lines 138-141: NO "Target: New command" for slot 17 (playlist) runtime read;
  APF fires done immediately → pram stays zero
- Lines 391-394: Interact wrote track_sel=1 (Cheshire), but slotoffset=0x0000000000
  (chunk 0) instead of 0x0002900000 (chunk 82 = Cheshire start). Proves cur_start=0.
- Line 315+: chunk_idx > 81 without wrap. Proves cur_chunks=0.

FIX 1: playlist_ram.sv - Split pram[] into non-reset always_ff block.
  OLD: pram[] inside always @(posedge clk or posedge reset); cleared on every
       reset posedge; bridge_wr capture in else branch (skipped during reset).
  NEW: Two separate always_ff blocks:
    (1) always_ff @(posedge clk) { bridge_wr → pram[] }  (NO reset, always captures)
    (2) always_ff @(posedge clk or posedge reset) { FSM only, no pram }
  Static boot order: Test Audio (slot 16) writes test_audio.bin bytes at file
  offset 0x1000000 to bridge 0x21000000 (corrupts pram temporarily), then
  Playlist (slot 17) writes correct playlist.bin 256 bytes to 0x21000000
  (overwrites with correct data). Final pram[] state after boot loads = correct.
  After Reset Exit: loaded=1 via FSM done handshake; pram already correct.

FIX 2: core_top.v - Auto-advance display when track ends naturally.
  When audio_streamer naturally plays through all cur_track_chunks chunks of
  the current track (chunks_played reaches cur_track_chunks-1 on a
  slot_consumed_pulse), core_top now:
  1. Advances track_sel to next track (mod NUM_TRACKS=3) → audio_streamer sees
     track_select change → soft-resets ring → ~40s silence → new track loads.
  2. One cycle later (auto_advance_r): updates text_ram from pram_name (which
     now correctly reflects the new track_sel via pram_read_idx).
  Added: localparam NUM_TRACKS=3, wire next_track_sel, wire auto_advance
         (guards: !bridge_wr, cur_track_chunks!=0, chunks_played==max),
         reg auto_advance_r, two new else-if branches in text_ram always block.

EXPECTED AFTER FIX (Test 4):
- Boys Like You plays (title: "BOYS LIKE YOU   ", audio from chunk 0)
- After ~224s (~82 chunks × 2.73s): ~40s silence while Cheshire ring refills
  → title updates to Cheshire's name → Cheshire plays (chunk 82-150)
- After Cheshire (~188s): ~40s silence → title updates → Blah Blah Blah plays
- After all 3 tracks: wraps to track 0 (Boys Like You)
- Interact menu track select: jumps to correct chunk (not chunk 0) for all tracks
  (pram correctly populated: track 0 start=0, track 1 start=82, track 2 start=151)
- Title updates correctly on both manual and auto track advances

FILES CHANGED:
- playlist_ram.sv: pram[] split into non-reset always_ff block
- core_top.v: NUM_TRACKS=3, next_track_sel, auto_advance, auto_advance_r, two
              new else-if branches in text_ram always block

QUARTUS RECOMPILE REQUIRED (HDL changes to both files).

STATUS: SOURCE DONE (2026-06-17), AWAITING RE-TEST (Test 4).

--------------------------------------------------------------------------------
23. MODULE 3g FOURTH HARDWARE TEST: ALL BUGS CONFIRMED FIXED + PROGRESS BAR FIX
    HARDWARE-CONFIRMED Test 5, log _163602, 2026-06-17
================================================================================

HARDWARE TEST LOG: MusicPlayer_20260617_153746.txt
RESULT (Test 4):
- pram[] fix confirmed: tracks advance automatically with ~3s gap (not ~40s;
  ring already prefilled so no silence wait - this is correct behavior now that
  pram[] populates correctly and chunk_idx wraps at the right boundary).
- Auto-advance confirmed: title updates on natural track end.
- Manual track select via interact menu confirmed: jumps to correct chunk, title
  updates correctly. ~3s silence then correct track plays.
- Progress bar bug observed: bar does NOT fill completely for Cheshire (67 chunks)
  or Blah Blah Blah (69 chunks). About 1/6 bar remaining when track advances on
  Blah Blah Blah.

PROGRESS BAR BUG ROOT CAUSE:
The original formula from Module 3b (section 14) was calibrated for Boys Like You:
  bar_mul = 39 * chunks_played
  bar_fill_x = bar_mul >> 3  →  82 * 39 / 8 = 399 pixels at track end
Comment read: "formula: (chunks * 39) >> 3 => 82*39>>3 = 399. No divider needed."
This only reaches 399px when the track has exactly 82 chunks. With 69 chunks:
  68 * 39 / 8 = 331 px out of 399 = 83% → ~17% (≈1/6) remaining when advancing.
  (Cheshire: 66 * 39 / 8 = 321 px = 80.5% → ~1/5 remaining.)

FIX (core_top.v):
Compute fill width proportionally in the clk_74a domain (where chunks_played and
cur_track_chunks both live), then 2-FF sync into clk_core_12288.

  bar_numer      = chunks_played * 399          (16-bit product)
  bar_div_full   = (cur_track_chunks != 0) ? bar_numer / cur_track_chunks : 0
  bar_fill_x_74a = bar_div_full[9:0]            (0..399 always fits in 9 bits)

2-FF sync: bar_fill_x_74a → bar_fill_x_s1 → bar_fill_x (registered in clk_core_12288).
Removed: chunks_played_s1, chunks_played_s2, bar_mul (old approach).

Quartus synthesizes the integer divider as combinatorial LUT logic. Values change
every ~2.73s (one chunk period), so timing closure is easy.

EXPECTED AFTER FIX (Test 5):
- Progress bar fills to full 399px at end of every track, regardless of chunk count.
- All previous behavior (auto-advance, manual select, title) unchanged.

FILES CHANGED:
- core_top.v: replaced chunks_played_s1/s2 + bar_mul approach with bar_numer,
  bar_div_full, bar_fill_x_74a (clk_74a domain) + bar_fill_x_s1 (2-FF sync).

QUARTUS RECOMPILE REQUIRED (core_top.v changed).

RESULT (Test 5, log _163602, 2026-06-17):
- Progress bar fix confirmed: bar fills to full width for all three tracks before
  auto-advance (Boys Like You 82 chunks, Cheshire 67 chunks, Blah Blah Blah 69 chunks
  all reach 399px). Fix works for any track length as designed.
- All previous behavior unchanged: auto-advance, manual track select, title updates.
- Session started on track 2 (persisted from Test 4); ring buffer cycled continuously
  through the full 3-track file. Clean unload; final persisted track = 1 (Cheshire).
MODULE 3g IS COMPLETE. All bugs fixed and confirmed on hardware.

================================================================================
24. MUSIC LIBRARY TOOL: convert_audio.py --dir / --use-tags (source done 2026-06-17)
================================================================================

GOAL: Replace the 3-track test playlist with the user's real music library,
with NO FPGA recompile needed.

KEY ARCHITECTURE INSIGHT (audio_streamer.sv lines 119-120):
  chunk_idx wraps within each track's range at RUNTIME using cur_start and
  cur_chunks from playlist_ram — there is NO compile-time NUM_TOTAL_CHUNKS.
  Adding/changing tracks only requires updating playlist.bin + test_audio.bin
  on the SD card. No Quartus recompile.

CAPACITY LIMITS (no recompile needed within these):
  - MAX_TRACKS = 8 (playlist_ram.sv parameter). All 8 slots in playlist.bin.
    Increasing this requires FPGA recompile.
  - chunk_idx is 16 bits but slotoffset uses only [12:0], so max 8191 chunks
    = ~22,360s (~6.2 hours) before the file offset overflows. Plenty for any
    real album.

WHAT convert_audio.py NOW DOES:
  --dir ALBUM_DIR:
    Auto-discovers all audio files in ALBUM_DIR (sorted by filename), takes
    first 8. Decodes each via ffmpeg (48kHz/16-bit stereo), pads each to
    CHUNK_BYTES (0x80000) boundary, concatenates into test_audio.bin.
    Generates playlist.bin (8-slot, 256-byte, big-endian per playlist_ram.sv).
    Updates BOTH copies of data.json (slot 16 + 17 size_exact).
    Updates BOTH copies of interact.json (Track menu options list).
  --use-tags:
    Reads title tag from each file via ffprobe for both:
      - Pocket menu name (full title, proper case)
      - OSD display name (16-char uppercase, stored in playlist.bin)
    Falls back to filename-based name if tag absent.
  --concat OUTPUT track0 [track1 ...]:
    Explicit file list instead of auto-discovery. Same outputs.

FILES UPDATED BY TOOL (no FPGA recompile):
  - dist/Assets/musicplayer/common/test_audio.bin  (new audio)
  - dist/Assets/musicplayer/common/playlist.bin    (new playlist)
  - dist/Cores/mhlin.MusicPlayer/data.json         (size_exact updated)
  - open-fpga-core-template-da3a021/data.json      (size_exact updated)
  - dist/Cores/mhlin.MusicPlayer/interact.json     (Track options updated)
  - open-fpga-core-template-da3a021/interact.json  (Track options updated)

USAGE - DIRECTORY MODE:
  py "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer\tools\convert_audio.py" --dir "PATH\TO\ALBUM" --use-tags
  Copy-Item -Recurse -Force "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer\dist\*" E:\

HARDWARE TEST (CHESHIRE album, 2026-06-17, log _173938):
  - 4-track CHESHIRE (2022) album loaded: test_audio.bin 145752064B, playlist.bin 256B
  - Both slots loaded before Reset Exit, interact.json 4 options (Cheshire/Snowy/Freaky/
    Boys Like You) loaded correctly.
  - All 4 tracks manually selectable via interact menu. OSD titles display correctly.
  - Ring buffer streaming continuous and correct (slot offsets match expected ranges).
  - Track switching (via interact) works including track 3 (Boys Like You).
  - Issue found: progress bar falls ~1 chunk short at end of every track (bar never
    reaches pixel 399). Root cause: denominator is cur_track_chunks but numerator max
    is cur_track_chunks-1, so max fill = (n-1)*399/n < 399.
  - Issue found: auto-advance wraps at track 2→0 (hardcoded NUM_TRACKS=3), skipping
    Boys Like You on 4-track album. Not observed during test (manual selection used).
  Log: mhlin.MusicPlayer_20260617_173938.txt

STATUS: HARDWARE-CONFIRMED (2026-06-17). Both bugs now fixed in Section 25.

================================================================================
25. PROGRESS BAR FIX + PAUSE/RESUME + AUTO-ADVANCE FIX (source done 2026-06-17)
================================================================================

GOAL: Fix 3 issues found in Section 24's hardware test:
  1. Progress bar falls ~1 chunk short at end of each track.
  2. auto_advance wraps at wrong track count (hardcoded NUM_TRACKS=3).
  3. (New feature) Pause/resume via A button.

BUG 1 - PROGRESS BAR (core_top.v):
  Old formula: floor(chunks_played * 399 / cur_track_chunks)
    chunks_played max = cur_track_chunks - 1
    → max bar = (n-1)*399/n ≈ 392-393px for typical tracks (never 399)
  Fix: change denominator to (cur_track_chunks - 1)
    → max bar = (n-1)*399/(n-1) = 399 ✓
  Guard: if cur_track_chunks <= 1 use denominator 1 (bar stays 0 for 1-chunk tracks)

BUG 2 - AUTO-ADVANCE (core_top.v + playlist_ram.sv):
  Old: localparam NUM_TRACKS = 3'd3 (hardcoded; must recompile per album)
  Fix: playlist_ram.sv now exports track_count (4-bit, counts pram entries where
       chunk_count != 0). core_top.v uses pram_track_count at runtime:
         last_track_idx = pram_track_count[2:0] - 3'd1 (3-bit arithmetic)
         next_track_sel = (track_sel == last_track_idx) ? 0 : track_sel + 1
       Works for 1-8 tracks without any FPGA recompile.

PAUSE/RESUME (core_top.v):
  - A button (cont1_key[4]) rising-edge toggles `paused` register (clk_74a domain).
  - `paused` synced into audgen_sclk via synch_3 (audio gate) and into clk_core_12288
    via synch_3 (display).
  - When paused: audio_addr stop incrementing, slot_consumed_tog not toggled.
    → ring buffer producer idles (fills up to RING_SLOTS=16, then stops).
    → chunks_played freezes (no slot_consumed_pulse), progress bar freezes.
    → auto_advance cannot fire (depends on slot_consumed_pulse).
  - Bar color: sky blue (#00B4D8) playing, amber (#FFBF00) paused.
  - Track change via interact while paused: audio_addr resets to 0 (via audio_loaded=0
    path when track changes clears initial_fill_done), new track loads, plays from
    start on resume.

FILES CHANGED:
  - open-fpga-core-template-da3a021/src/fpga/core/core_top.v
      lines ~530-535: bar_denom = cur_track_chunks-1 formula
      lines ~553-558: pram_track_count + last_track_idx (replaced NUM_TRACKS localparam)
      lines ~537-541: paused/btn_a_r/paused_s/paused_vid_s declarations
      lines ~630-634: bar fill color gated on paused_vid_s
      lines ~938-943: audio_addr advancement gated on !paused_s
      lines ~965-967: synch_3 s_paused + s_paused_vid
      lines ~991-1001: pause toggle always block
      playlist_ram port: .track_count(pram_track_count)
  - open-fpga-core-template-da3a021/src/fpga/core/playlist_ram.sv
      port: output logic [3:0] track_count
      always_comb: loop counting non-zero-chunk entries

HARDWARE TEST (log _182052, 2026-06-17):
  - Progress bar: reaches pixel 399 at end of each track ✓
  - Auto-advance: Freaky (track 2) → Boys Like You (track 3) confirmed in log
    (offset jump to 0x0006200000 = chunk 196 = Boys Like You start) ✓
  - Pause/resume: A button pauses; track change while paused then resume works ✓
  - Ring buffer continuous, clean unload ✓
  Note: persist track-on-boot doesn't restore selected track (track_sel is
  reset-gated; interact write fires while FPGA is in reset, so it's lost).
  Playback always starts from track 0 on boot. Acceptable behavior.

STATUS: HARDWARE-CONFIRMED (2026-06-17, log _182052). SECTION 25 COMPLETE.

================================================================================
26. D-PAD PREV/NEXT + NOW PLAYING UI (source done 2026-06-17)
================================================================================

GOAL: (1) Navigate tracks with d-pad left/right without opening interact menu.
      (2) "Now playing" visual elements: play/pause icon + track number overlay.
      (3) Test with a different album to confirm music-library tool works.

D-PAD PREV/NEXT (core_top.v):
  - dpad_right (cont1_key[3]) rising-edge = next track (same as auto_advance target).
  - dpad_left  (cont1_key[2]) rising-edge = prev track; wraps 0 → last_track_idx.
  - prev_track_sel = (track_sel == 0) ? last_track_idx : track_sel - 1.
  - btn_right_r, btn_left_r: registered prev values for rising-edge detection,
    added to the existing A-button always block.
  - dpad_advance_r: 1-cycle delay (posedge clk_74a), mirrors auto_advance_r pattern
    so pram_read_idx settles before text_ram is updated from pram_name.
  - Priority in text_ram block: bridge_wr (interact) > dpad > auto_advance.

PLAY/PAUSE ICON (core_top.v):
  - 8x8 pixel art at x=120..127, y=165..172 (same row as 16-char track name).
  - ICON_X=120 has [2:0]=0 so icon_col = visible_x[2:0] (clean subtraction).
  - Playing (▶): right-pointing triangle; rows 0,7=0x80 / 1,6=0xC0 / 2,5=0xE0 / 3,4=0xF0.
  - Paused (▐▐): pause_bmp=0xCC (two 2-px bars with 2-px gap); same for all rows.
  - Uses paused_vid_s (already synced into clk_core_12288) for live switching.
  - Rendered white (24'hFFFFFF) - same as track name text.

TRACK NUMBER OVERLAY (core_top.v):
  - "X / Y" (5 chars, 40px) at x=320..359, y=165..172; second font_rom instance.
  - tnum_char_code mux: char0='0'+track_sel_vid+1, char1=' ', char2='/', char3=' ',
    char4='0'+track_count_vid.
  - track_sel_vid, track_count_vid: 2-FF sync of track_sel/pram_track_count into
    clk_core_12288 (display-safe, momentary glitch on track change acceptable).

FILES CHANGED:
  - open-fpga-core-template-da3a021/src/fpga/core/core_top.v
      lines ~542-551: prev_track_sel, btn_right/left_r, dpad_next/prev, dpad_advance_r,
                      track_sel_s1/vid, track_count_s1/vid declarations
      lines ~580-607: icon + tnum wire declarations, second font_rom (u_font_tnum)
      lines ~616-622: clk_core_12288 reset for sync regs
      lines ~630-636: 2-FF sync for track_sel and pram_track_count into vid domain
      lines ~645-652: icon_lit and tnum_pixel_lit rendering in video gen
      lines ~714-717: second font_rom instantiation (u_font_tnum)
      lines ~783-801: dpad_next/prev and dpad_advance_r cases in text_ram block
      lines ~1088-1107: updated button always block + dpad_advance_r always block

ROADMAP NOTE (no FPGA work now):
  Long-term plan: custom on-screen UI with tabs (Album / Library / Playlists) for
  track selection — replacing the interact menu entirely. When that UI is built,
  the "persist track on boot" question becomes moot (UI will default to first track
  or a saved position). Volume normalization also deferred until player is nearly
  done. Neither of these is in scope for current sessions.

HARDWARE TEST (log _231045, 2026-06-17):
  - D-pad right/left: next/prev track confirmed ✓
  - Play/pause icon (▶/▐▐) confirmed ✓
  - Track number "X / Y" confirmed ✓
  - Different album (274MB, 274202624 bytes) loaded and played correctly ✓
  - Track name still limited to 16 chars (noted: extend to 32 + scrolling ticker later)

STATUS: HARDWARE-CONFIRMED (2026-06-17, log _231045). SECTION 26 COMPLETE.

================================================================================
27. OSCILLOGRAPH "NOW PLAYING" VISUALIZER (source done 2026-06-17)
================================================================================

GOAL: First "Now Playing" visualizer from plans/UI_SPEC.md — Oscillograph variant.
  Fills the currently-empty upper portion of the screen with a live PCM waveform.
  No album art or FFT needed; uses audio_frame[15:8] already available in clk_74a/audgen_sclk.

DESIGN (from plans/Now_Playing_Tab.drawio.png + UI_SPEC.md):
  Oscillograph = live waveform of PCM data + "Song_Title / Album_Name" caption below.
  We already have song title (track name) + progress bar below. This section adds the
  waveform in the upper screen area.

LAYOUT:
  y=26: top border of oscilloscope box (#303050)
  y=27..155: oscilloscope area (129px tall), black background (#000000)
              x=19,380: left/right border (#303050)
  y=91: dim center line at silence level (#1E1E30)
  y=27..155, x=20..379: white waveform (#FFFFFF)
  y=156: bottom border of oscilloscope box (#303050)
  [y=157..164: 8px gap, navy background]
  y=165..172: track name (16 chars), ▶/▐▐ icon, "X/Y" track number (unchanged)
  y=339: separator line
  y=340..349: progress bar (unchanged)

OSCILLOSCOPE CAPTURE (clk_core_12288 domain):
  - 2-FF sync: audio_frame[15:8] → osc_aud_s1 → osc_aud_vid (stable 8-bit PCM)
  - osc_cap_div[7:0]: counts 0..255; write to ring buffer when == 255 → ~48kHz capture
  - osc_buf[0:511] (reg [7:0]): 512-entry ring buffer, 4096 bits, fits in MLABs
  - osc_cap_wr[8:0]: write pointer, natural 9-bit wrap at 512
  - At vsync (x_count==0, y_count==0): osc_cap_wr_snap <= osc_cap_wr
    → consistent snapshot for the whole video frame (no horizontal tearing)

WAVEFORM RENDERING:
  - osc_read_idx = osc_cap_wr_snap + osc_x_off[8:0] (circular, mod-512 via 9-bit wrap)
  - osc_samp = osc_buf[osc_read_idx] (async read); osc_samp_p = osc_buf[idx-1]
  - Convert to y: osc_unb = {~samp[7], samp[6:0]} (signed→unsigned 0..255)
    osc_y = 155 - osc_unb[7:1] → range 155-127=28 to 155-0=155; silence at y=91 ✓
  - Draw osc_at_cur (y == osc_y) plus osc_between (vertical segment to prev sample y)
    → smooth connected waveform even for fast-moving signals

FILES CHANGED:
  - open-fpga-core-template-da3a021/src/fpga/core/core_top.v
      lines ~609-644: oscilloscope declarations (localparam, regs, wires)
      lines ~658-662: reset initialization
      lines ~709-719: capture + vsync snapshot in clk_core_12288 else block
      lines ~731-739: video rendering (black box, border, center line, white waveform)

ROADMAP NOTE:
  16-char track name limit: user notes it should be 32+, with scrolling ticker.
  Defer until custom UI tabs are implemented (ticker applies to album, track, playlist names).

HARDWARE TEST (log _235950, 2026-06-17/18):
  - Black oscilloscope box with dim border visible ✓
  - Dim center line at y=91 (silence level) visible ✓
  - White PCM waveform live from audio_frame[15:8] ✓
  - 8-track album on SD (different from CHESHIRE) — library tool confirmed ✓
  - 16-char track name truncation confirmed still present (expected, deferred)
  - BUG: "Tilted line" across ALL tracks, every frame = untriggered oscilloscope.
    Root cause: each frame snaps the ring buffer at a different audio phase → waveform
    "rolls" at 60fps, appearing as a tilted smear in photos. Fixed in Section 28.

STATUS: HARDWARE-CONFIRMED with instability bug (2026-06-17/18, log _235950).
        Zero-crossing trigger fix implemented in Section 28.

--------------------------------------------------------------------------------
28. SECTION 28: ZERO-CROSSING TRIGGERED OSCILLOSCOPE (source done, awaiting HW test)
--------------------------------------------------------------------------------
CONTEXT/GOAL:
  Section 27 hardware test revealed the oscilloscope waveform is unstable: a
  "tilted line" appears consistently across ALL tracks. Root cause: the ring-buffer
  + vsync-snapshot approach captures samples at whatever phase the audio happens
  to be at when vsync fires — a different phase every frame at 60fps. The waveform
  "rolls" continuously, showing as a diagonal smear or changing tilt in photos.
  This is the classic untriggered oscilloscope problem.

  Fix: classic oscilloscope trigger — detect a consistent reference point in the
  audio signal (rising zero-crossing), then capture exactly 360 samples from that
  point. Each frame starts at the same audio phase → stable, phase-aligned waveform.

DESIGN:
  scope_ram[0:359] (reg [7:0], 360 entries, 2880 bits — fits in MLABs) replaces
  osc_buf[0:511] (4096 bits). Smaller AND stable: only written during FILL state,
  frozen during HOLD.

  FSM (osc_trig_state, 2-bit, in clk_core_12288 domain, inside osc_cap_div==255 block):
    State 0 (ARMED): Watch osc_prev[7] && !osc_aud_vid[7] — sign bit goes 1→0 = rising
                     zero-crossing (negative → non-negative PCM value). On trigger:
                     write sample 0, set scope_fill=1, advance to FILL.
    State 1 (FILL):  Write osc_aud_vid into scope_ram[scope_fill], increment scope_fill.
                     When scope_fill==359, advance to HOLD (360 samples total).
    State 2 (HOLD):  scope_ram is stable. No writes. Wait for vsync re-arm.
  Re-arm: at x_count==0, y_count==0 (vsync), if state==HOLD → back to ARMED.
  This guarantees scope_ram is never written while the video engine reads it.

  osc_prev: latched inside osc_cap_div==255 block (same time as sample capture),
  so prev holds the sample from the PREVIOUS capture tick for zero-crossing compare.

  Display reads now direct: scope_ram[osc_x_off[8:0]] (no ring-index arithmetic).
  All rendering wires (osc_unb, osc_y, osc_at_cur, osc_between, osc_pixel,
  in_osc_border) unchanged — they only depend on osc_samp/osc_samp_p.

FILES CHANGED:
  - open-fpga-core-template-da3a021/src/fpga/core/core_top.v
      lines ~609-627: declarations — scope_ram[0:359], osc_trig_state, osc_prev,
                      scope_fill, osc_x_off, osc_samp/osc_samp_p (direct scope_ram reads)
      lines ~660-665: reset block — osc_trig_state, osc_prev, scope_fill
      lines ~712-738: capture logic — 2-FF sync, FSM, vsync re-arm
      Rendering (lines ~628-646): UNCHANGED

DIAGNOSTIC TREE (for hardware test):
  - Stable, phase-aligned waveform → zero-crossing trigger CONFIRMED.
  - Flat line → scope_ram never filled (signal too quiet for zero-crossings, or
    FSM stuck in ARMED). Check with a loud/dynamic track.
  - Still rolling/chaotic → trigger still not firing within the frame window.
    May need decimation adjustment or a less-strict trigger condition.
  - No waveform at all → regression in Section 27 code path (check osc_samp reads).

HARDWARE TEST rev1 (log _010851, 2026-06-18): NO SOUND, waveform frozen.
  Root cause: scope_ram [0:359] (non-power-of-2) + mixed constant/variable write
  indices (scope_ram[9'd0] in ARMED + scope_ram[scope_fill] in FILL) prevented
  Quartus from inferring MLAB. Forced ~2880 registers instead → routing congestion
  → 133MHz PSRAM test timing failure → psram_test_pass=0 → audio_loaded=0 → silence.
  Waveform frozen: with audio_loaded=0, audio_addr stays at 0 (same PSRAM addr),
  audio_frame is constant → no zero-crossings → trigger never fires → scope_ram stays
  all-zeros → flat center line → appears "not moving."

SECTION 28 rev2 fix (source done, 2026-06-18):
  - scope_ram [0:511] (power-of-2): guarantees Quartus MLAB inference.
  - All scope_ram writes use scope_fill (variable index): ARMED state writes
    scope_ram[scope_fill] where scope_fill=0 (reset by re-arm), then FILL 1..359.
  - Re-arm resets scope_fill=0 alongside osc_trig_state=ARMED.
  - osc_samp_p derived from registered osc_samp (osc_samp_p_r) instead of second
    async RAM read → single read port → cleaner MLAB single-port inference.

HARDWARE TEST rev2 (2026-06-18): AUDIO WORKS, waveform still shows diagonal artifacts.
  Root cause: MLAB has asynchronous reads. Even though both video and capture run on
  clk_core_12288 (same always block), the FILL state writes samples into scope_ram
  while the VGA scanline is actively reading it. Since MLAB reads are combinatorial,
  a write on cycle N is immediately visible to the combinatorial read output — any
  pixel drawn AFTER the write cycle sees the new value, pixels drawn BEFORE it see the
  old value. The "write moment" sweeps diagonally across the frame as scope_fill
  advances (256 cycles per sample × 360 samples = 92,160 cycles = ~180 scanlines),
  creating the characteristic diagonal lines. The artifacts shuffle each frame because
  the trigger fires at a different position within each frame's 204,800-cycle budget.
  Pausing stops audio_addr → audio_frame constant → no zero-crossings → trigger never
  fires → scope_ram never written → front buffer stays stable → lines vanish.

SECTION 28 rev3 fix: PING-PONG DOUBLE BUFFER (source done, 2026-06-18):
  Replace scope_ram [0:511] with two buffers:
    scope_ram_a [0:511]  -- ping-pong buffer A (power-of-2 → MLAB)
    scope_ram_b [0:511]  -- ping-pong buffer B (power-of-2 → MLAB)
    scope_buf_sel         -- 0=A front/B back; 1=B front/A back

  Video reads ONLY from front buffer (scope_buf_sel determines which):
    osc_samp = scope_buf_sel ? scope_ram_b[osc_x_off] : scope_ram_a[osc_x_off]

  Capture writes ONLY to back buffer (opposite of scope_buf_sel):
    ARMED/FILL: if (!scope_buf_sel) scope_ram_b[scope_fill] <= osc_aud_vid;
                else                scope_ram_a[scope_fill] <= osc_aud_vid;

  Swap at vsync (x_count==0, y_count==0) ONLY when HOLD state (complete capture):
    scope_buf_sel <= ~scope_buf_sel;  // old back becomes new front
    osc_trig_state <= ARMED;
    scope_fill <= 0;

  No swap if not HOLD (no complete capture yet): front buffer remains unchanged
  from previous frame (last stable waveform). This ensures:
    - Video always sees a complete, fully-written snapshot (no torn state).
    - Capture is free to write the back buffer at any time without affecting video.
    - 7.5ms fill time << 16.67ms frame → at most 1-frame latency on the display.

  MLAB inference preserved:
    - Each buffer: 512 × 8 = 4096 bits → ~7 MLAB blocks each (14 total vs 7 before).
    - Write index always scope_fill (variable) → Quartus sees variable-address writes.
    - scope_buf_sel condition acts as write-enable → supported MLAB write pattern.
    - 2 MLAB reads (one from each buffer) muxed by scope_buf_sel — no inference risk.

  Awaiting Quartus recompile + hardware test.

HARDWARE TEST rev3 (log _022347, 2026-06-18): CONFIRMED. Audio works, waveform stable,
  no diagonal lines. Ping-pong double buffer eliminates tearing completely. Waveform
  phase-locks to zero-crossing trigger as designed - consistent shape each frame.
  Minor noted bug (not fixed here): core initialises showing "BOYS LIKE YOU" in the
  menu text but plays "motto" - because interact persist loads the previous track index
  at boot. Deferred to Section 29 (startup-silence redesign).

STATUS: HARDWARE-CONFIRMED rev3 (2026-06-18). Section 28 complete.

================================================================================
SECTION 29 - NOW PLAYING REDESIGN + TABS + 64-CHAR TITLE/ARTIST (source done 2026-06-18)
================================================================================

CONTEXT / GOAL:
  Section 28 confirmed the oscilloscope display. Section 29 is a major UI overhaul:
  (a) Expand track title from 16 to 64 chars + add 32-char artist name (separate line).
  (b) Redesign Now Playing layout: taller oscilloscope box, 2× play/pause icon centered,
      2× track title full-width, 1× artist below, progress bar indented to box margins.
  (c) Box border color = progress "empty" color (0x1E1E30) for a clean unified look.
  (d) Tab infrastructure: Shoulder L/R cycles cur_tab (0=NowPlaying, 1=Album, 2=Library,
      3=Playlists). Tab names displayed at top of each screen.
  (e) Library tab: up/down d-pad navigates library cursor; A plays selected track.
  (f) Album + Playlists tabs: "COMING SOON" placeholder for this section.
  Also: startup-silence / wrong-title bug deferred to Section 30.

DATA FORMAT CHANGE (playlist.bin):
  Old: 32 bytes/track × 8 tracks = 256 bytes total.
      [0-1]=start_chunk, [2-3]=chunk_count, [4-19]=name(16), [20-31]=reserved
  New: 128 bytes/track × 8 tracks = 1024 bytes total.
      [0-1]=start_chunk, [2-3]=chunk_count, [4-67]=title(64), [68-99]=artist(32),
      [100-127]=reserved
  IMPORTANT: Must re-run convert_audio.py after FPGA recompile to regenerate playlist.bin.
  Old 256-byte playlist.bin is incompatible with new 128-byte-record playlist_ram.sv.

DISPLAY LAYOUT (400×360 active, clk_core_12288):
  y=0..7   : top margin (8px), background
  y=8      : oscilloscope box border top
  y=9..180 : oscilloscope box interior (172px; silence center at y=95)
  y=181    : oscilloscope box border bottom
  y=182..189: gap (8px)
  y=190..205: play/pause icon 2× scale (16×16px), centered at x=192..207
  y=206..209: gap (4px)
  y=210..225: track title 2× scale (16px tall), x=0..399, first 25 chars of title_ram
  y=226..229: gap (4px)
  y=230..237: artist name 1× scale (8px tall), x=72..327 (32 chars centred for max 32)
  y=238..334: dark background spacer (97px)
  y=335    : thin separator line
  y=336..343: progress bar (8px), x=19..380 (matching box border indent)
  y=344..359: bottom margin (16px)

  Box border color: 0x1E1E30 (matches progress-bar empty colour)
  Tab header "NOW PLAY"/"ALBUM   "/"LIBRARY "/"PLAYLSTS" at y=8..23 (2× scale) for
  non-NowPlaying tabs (replaces oscilloscope area in those tabs).

TAB LAYOUT:
  Tab 0 (NowPlaying): oscilloscope box + icon + title + artist + progress
  Tab 1 (Album):      "ALBUM   " header at top + "COMING SOON" centred
  Tab 2 (Library):    "LIBRARY " header + library cursor title/artist + progress
                       d-pad UP/DN: library_cursor--/++; A: play selected track
  Tab 3 (Playlists):  "PLAYLSTS" header + "COMING SOON" centred

FILES CHANGED:
  - open-fpga-core-template-da3a021/src/fpga/core/playlist_ram.sv
      128-byte records; 512-bit track_title (BE) + 256-bit track_artist (BE);
      lib_idx secondary read port with lib_title_le/lib_artist_le (LE for easy indexing);
      TOTAL_WORDS=256, bridge_addr[9:2], target_dataslot_length=MAX_TRACKS*128.
  - tools/convert_audio.py
      PLAYLIST_RECORD_SIZE=128, get_osd_name returns 64 bytes, new get_artist_name 32 bytes,
      make_playlist_entry: 4+64+32+28=128 bytes.
  - open-fpga-core-template-da3a021/src/fpga/core/core_top.v
      title_ram[0:63] + artist_ram[0:31] replace 16-char text_ram; cur_tab (2-bit) +
      shoulder L/R cycling; list_cursor (3-bit) + up/down browsing + A-select in Library
      tab; redesigned Now Playing (taller osc box y=8..181, 2x icon, 2x ticker title,
      1x artist, progress bar reindented to x=19..380); Library tab reuses the same
      title/artist/progress rendering wires via a lib_mode mux (no ticker there); Album/
      Playlists tabs show a "COMING SOON" placeholder. playlist_ram instantiation updated
      for the new track_title/track_artist/lib_idx/lib_title_le/lib_artist_le ports.

CORRECTION (2026-07-22): the prior session's "SOURCE DONE (2026-06-18)" status below
was WRONG - it hit the weekly usage limit while still reading/planning core_top.v and
never actually wrote the changes (git diff confirmed core_top.v was untouched; only
playlist_ram.sv + convert_audio.py had been done). core_top.v's old playlist_ram
instantiation still referenced the removed track_name port, so the project would not
even elaborate. core_top.v Section 29 changes were implemented from scratch this
session (2026-07-22). Two centering-math bugs were caught during self-review before
handoff: the title/artist "center on screen" x_start formulas were using the full
character-width shift instead of the half-width shift, which made a 25-char title or
a 32-char artist name wrap negative in unsigned 10-bit arithmetic and render as
nothing; also a Library-tab title >25 chars would have hit the same wraparound since
Library never activates the news ticker - fixed by clamping the Library centering
math to 25 chars (title just truncates there, doesn't scroll, matching spec).

STATUS: HARDWARE-CONFIRMED (2026-07-22, debug logs _214227/_230954): playlist.bin
regenerated to the new 128-byte/track format, recompiled, deployed, and tested -
loads correctly, tab structure + Shoulder L/R work, Library A-select plays the
chosen track. Three bugs found in that test - see Section 30 for the fixes
(progress-bar separator width, Library title-not-updating) and new work (Library
track list redesign, Now Playing thumbnail effect).


--------------------------------------------------------------------------------
30. SECTION 30 - HARDWARE-TEST BUG FIXES + LIBRARY TRACK LIST + THUMBNAIL EFFECT
    (source done 2026-07-23)
--------------------------------------------------------------------------------
CONTEXT: user tested Section 29's redesign on hardware (2026-07-22, debug logs
_214227/_230954 - core loads correctly, tab structure and Shoulder L/R confirmed
working) and reported four issues plus a feature request:
  1. A thin line at the progress bar, running from the screen's left edge to its
     right edge.
  2. Library tab only ever shows the single browsed track, not the other tracks;
     wanted a visible effect distinguishing the currently-selected one.
  3. (Not a bug) all non-NowPlaying tabs show "COMING SOON" and the shoulder
     button works perfectly - confirmed working as designed.
  4. Start iterating on additional Now Playing visualizer effects - the
     oscilloscope runs hot on real hardware; wanted a "still and easy" effect for
     longer test sessions, starting with a static album-art thumbnail (with a
     default image when a track has none).
  5. Selecting a track from the Library correctly plays it, but the displayed
     title doesn't update.

--- Bug 1: progress-bar separator line spans the full screen width ---
core_top.v's y=335 separator line (drawn just above the progress bar, both
NowPlaying and Library tabs) had NO x-bound at all: `if (visible_y == 10'd335 &&
...)` with no visible_x check, so it was drawn across the entire active row
(x=0..399) while the bar and oscilloscope box above/below it are indented to
x=19..380. Visually this reads as a stray line reaching the true screen edges
while everything else has a margin. FIX: bounded the same condition to
`visible_x >= BAR_X_START && visible_x < BAR_X_END` (19..380), matching the bar
and box margins.

--- Bug 5: Library A-select doesn't refresh the displayed title/artist ---
ROOT CAUSE: the title_ram/artist_ram bridge-write handler's priority chain (the
`if (bridge_wr...) else if (...) ... else if (lib_select_r) begin track_sel <=
list_cursor; cur_tab <= 2'd0; end` block) had a `lib_select_r` branch that
updates track_sel and jumps to NowPlaying, but - unlike every other branch in
that chain (bridge_wr, dpad_advance_r, auto_advance_r) - it never copied
pram_title/pram_artist into title_ram/artist_ram. The newly-selected track played
correctly (track_sel/audio_streamer/psram path all updated fine) but the on-
screen title/artist simply kept showing whatever was there before.
FIX: added `lib_select_r2`, a 1-cycle-delayed copy of `lib_select_r` (identical
two-stage pattern to the existing `auto_advance`/`auto_advance_r` pair - the
extra cycle lets pram_read_idx catch up to the new track_sel before pram_title/
pram_artist are sampled). A new `else if (lib_select_r2) begin ... refresh
title_ram/artist_ram ... end` branch does the actual refresh, one cycle after
lib_select_r adopted list_cursor into track_sel.

--- Bug 2: Library tab redesigned into a real track list ---
Previously the Library tab reused the exact same single-track title/artist
render area as NowPlaying (just fed from `lib_title_le`/`lib_artist_le` instead
of `title_ram`/`artist_ram` via a `lib_mode` mux) - so it only ever showed ONE
track (whichever the browse cursor pointed at), with no way to see the rest of
the library or visually confirm which one was selected beyond the text itself
changing.
NEW DESIGN: an actual list of all MAX_TRACKS(8) rows, y=28..155 (2x-scale text,
16px/row, packed edge-to-edge), left-aligned, no ticker - `list_row` (derived
from visible_y) drives playlist_ram's `lib_idx` secondary port combinatorially
per-scanline (safe re-addressing per row - playlist_ram's secondary read port is
pure combinational, same trick the title/artist font lookups already rely on).
Trailing bytes in playlist.bin are already space-padded (convert_audio.py's
`.ljust(N, b" ")`), so a shorter title just renders blank past its length - no
length-scan needed for the list (unlike the centered NowPlaying title). The row
matching `list_cursor` gets a solid highlight band (0x00B4D8, the same accent as
the "playing" progress bar) with dark navy text on top for contrast; other rows
show white text on the normal dark background. Rows beyond the live track_count
are left blank (`row_has_track` gates both highlight and text).
The old single-track "browse preview" (title/artist area, y=210-238) is REPURPOSED
rather than removed: it now always shows title_ram/artist_ram - i.e. whatever is
ACTUALLY PLAYING - in both NowPlaying and Library tabs, matching the progress bar's
existing behavior there ("shows whatever is actually playing, independent of the
browse cursor"). So Library now reads: track list up top (browse target
highlighted) + a small "what's actually playing" preview + progress bar at the
bottom - removed the now-dead `lib_title_len_c`/`lib_artist_len_c` combinational
length scanners since the mini preview no longer needs library-specific lengths.
New font_rom instance (`u_font_list`) for the list text - font_rom is a stateless
combinational lookup, so a 5th instance is cheap.

--- Feature 4: Now Playing thumbnail effect (first iteration) ---
GOAL: a much lower-switching-activity Now Playing visualizer than the
oscilloscope, for long hardware test sessions without excess heat, per the
user's report that the oscilloscope "makes the hardware pretty hot." Starting
with a static album-art thumbnail; per-track art extraction (from embedded
cover-art tags) is EXPLICITLY DEFERRED to a future iteration - this pass always
shows one bundled default placeholder image, which also directly satisfies "if
the song does not have an album thumbnail, there should be a default one" (every
track currently falls into that case).
CONTROL: D-pad Up/Down is unused in the NowPlaying tab (only Library uses it, to
browse the list) - repurposed there as an effect toggle (`effect_mode`: 0=
oscilloscope default, 1=thumbnail), reusing the same up/down debounce registers.
NEW FILE core/thumb_ram.sv: combines two already-hardware-confirmed patterns
rather than inventing a new one - ImageViewer's framebuffer_ram.sv storage/read/
write pattern (RGB565, 2px/32-bit-word, byte-reversed write capture, registered
"present the next pixel's address one cycle early" read) + playlist_ram.sv's
4-state one-shot dataslot loader (REQ->WAIT_CLEAR->WAIT_DONE->DONE), with an
added BOOT state gated on an `enable` input (same discipline as
audio_streamer.sv) so its one boot-time dataslot request never collides with
playlist_ram's own. New slot 18 "Default Thumbnail",
BASE_ADDR=0x2200_0000 (non-overlapping with the 0x2000_0000 audio buffer window
and the 0x2100_0000 playlist window), 172x172 RGB565 = 59168 bytes (0xE720) -
chosen to exactly fill the oscilloscope box's interior height (172 rows,
OSC_Y_TOP+1..OSC_Y_BOTBRD-1) with a square image centered horizontally in the
360px-wide box (94px pillarbox each side, filled for free by the box's existing
black background fill). ~462Kbit of M10K - well within the 5CEBA4's 3080Kbit
budget alongside the rest of this otherwise-small core.
DATASLOT ARBITRATION: extended the existing 2-way priority mux (playlist_ram
then audio_streamer) to 3-way (playlist_ram, then thumb_ram, then
audio_streamer) - thumb_ram's BOOT waits for playlist_loaded;
audio_streamer's `enable` changed from `playlist_loaded` to `playlist_loaded &&
thumb_loaded`, so exactly one of the three ever asserts target_dataslot_read at
a time (thumb file is tiny - single-digit ms to load - so this adds negligible
boot latency before audio starts).
POWER: critically, the oscilloscope's CAPTURE FSM itself (osc_cap_div counter,
zero-crossing detect, scope_ram_a/b writes, buffer swap) is now gated behind
`!effect_mode_vid` - not just its on-screen display. Only hiding the waveform
while leaving the ~48kHz capture loop running underneath would NOT have reduced
any switching activity, defeating the whole point of a "cooler" effect. It
simply resumes from wherever it was frozen (typically ARMED or mid-FILL) when
the user flips back. The oscilloscope's box border and black interior fill are
shared unconditionally by both effects (frame stays consistent); only the
waveform-vs-thumbnail pixels are effect_mode-gated.
NEW TOOL tools/make_default_thumb.py: generates the default image entirely
programmatically (no external asset needed) - a simple vinyl-record icon using
the UI's existing palette (0x0D0D1A background, 0x1E1E30 disc, 0x00B4D8 label -
the same accent as the progress bar/list highlight). Packs RGB565 little-endian
exactly like ImageViewer's tools/convert_images.py (`to_rgb565_bytes`, byte_order
="little") - flat, row-major, no header. Already run once this session;
dist/Assets/musicplayer/common/default_thumb.bin exists (59168 bytes, verified
exact match to data.json's size_exact).
FILES CHANGED: core/thumb_ram.sv (new), core/core_top.v (effect_mode reg +
D-pad toggle + synch_3 into video domain, THUMB_* geometry constants,
next_x_count/next_y_count + thumb_rd_addr registered-read addressing, RGB565->
RGB888 conversion, oscilloscope capture gated behind !effect_mode_vid, 3-way
dataslot mux, thumb_ram + updated audio_streamer instantiation), ap_core.qsf
(+thumb_ram.sv), data.json (dev copy + dist copy: +slot 18 "Default Thumbnail"),
tools/make_default_thumb.py (new).

STATUS: HARDWARE-CONFIRMED (2026-07-23, debug log _002804): all three data
slots (Test Audio, Playlist, Default Thumbnail id 18) loaded correctly,
progress-bar separator fix and Library title-refresh fix both confirmed
working, Library list + highlight confirmed working ("selecting worked
perfectly"). Two refinements requested from this test, addressed in Section
31: (1) the static thumbnail should be a "Spinning Vinyl" (album art +
partially-hidden rotating disc, no box) rather than a plain centered square;
(2) cosmetic: data.json's "Default Thumbnail" name (18 chars) exceeds the
platform's 15-char data-slot name limit and was silently truncated to
"Default Thumbna" in the debug log (harmless - only the display label, not
the id/filename/size fields - but renamed to "Default Thumb" for cleanliness).


--------------------------------------------------------------------------------
31. SECTION 31 - SD LOAD SPEED FIX + SPINNING VINYL + LIBRARY FULL-SCREEN LIST +
    TITLE/ARTIST REPOSITION (source done 2026-07-23)
--------------------------------------------------------------------------------
CONTEXT: user hardware-tested Section 30 (debug log _002804, 2026-07-23) and
reported: (1) tracks take ~5 minutes to load, please investigate/fix; (2) the
thumbnail effect showed correctly but should be a "Spinning Vinyl" per
plans/Now_Playing_Tab.drawio.png - album thumbnail + a partially-hidden
rotating vinyl disc (reflection spinning), no box border for this effect; (3)
Library tab doesn't need the "now playing" mini preview - wanted a full-screen
track list instead (selecting itself "worked perfectly"); (4) Now Playing
title/artist should sit centered in the gap between the box and the progress
bar, not immediately below the play/pause icon.

--- Fix 1: ~5 minute SD load time ---
ROOT CAUSE: data.json's "Test Audio" slot declares an "address" (0x20000000)
with size_exact = the ENTIRE concatenated song file (274,202,624 bytes for the
8-track album under test). Per the Analogue openFPGA data.json spec
(https://www.analogue.co/developer/docs/core-definition-files/data-json), ANY
data slot with "address" set gets its FULL file contents auto-loaded/DMA'd by
the Pocket's own boot sequence, BEFORE Reset Exit - independent of the
"required" flag (confirmed against our own debug log: "File: Load 0x20000000
with 0x0010580000 bytes..." happens during the pre-Prerun "Slot: load done"
phase, for a slot marked required:false). This is completely redundant with
audio_streamer.sv's OWN on-demand 0.5MB chunked target_dataslot_read requests
(which specify their own slotoffset/bridgeaddr per chunk and don't depend on
or benefit from the boot preload in any way) - so for a full album-length
file, the boot sequence was eagerly copying the ENTIRE song (hundreds of MB)
over the SD/bridge interface for zero benefit, before the core even started
running. This is what took ~5 minutes; audio_streamer's actual runtime
chunk-by-chunk reads (each ~0.5MB, ~109x timing margin per Module 2c's
analysis) were never the bottleneck.
FIX: added `"deferload": true` to ONLY the "Test Audio" data slot (both the
dev-copy and dist/Cores/mhlin.MusicPlayer/data.json). Per the official field
description: "If true, slot will not be loaded, but its size and ID will
still be communicated to the core, and the core may read/write it with
Target commands." This is the officially-documented mechanism for exactly
our use case (a core that wants to manage its own reads at runtime). The
Playlist and Default Thumbnail slots were deliberately left unchanged (no
deferload) - they're tiny (1KB/59KB) and their own loader modules
(playlist_ram.sv/thumb_ram.sv) rely on the existing "auto-loaded at boot,
then a fast pre-satisfied re-request" pattern (see CLAUDE.md's "APF static
boot load behavior" note) which is already confirmed working and costs
negligible time for files this size - no reason to change something that
isn't broken. This is a data.json-only change - it does NOT require a Quartus
recompile, only a redeploy of dist/ to the SD card, so it can be verified
independently of Section 31's other (HDL) changes.
ALSO FIXED (cosmetic, found while reading the debug log): "Default Thumbnail"
(18 chars) exceeds the data slot name field's 15-char limit and was silently
truncated to "Default Thumbna" in Pocket's own logs - renamed to "Default
Thumb" (13 chars) in both data.json copies. Purely a display-label fix; the
id/filename/size_exact fields were never affected and the slot always worked.

--- Feature 2: Thumbnail effect redesigned into "Spinning Vinyl" ---
Looked at plans/Now_Playing_Tab.drawio.png + plans/UI_SPEC.md (the "long-term
UI vision" reference from prompts/prompt_000.txt) for the authoritative design:
4 planned Now Playing "animations" (Spinning Vinyl, Still Thumbnail, Bar
Chart, Oscillograph - only Oscillograph and now Spinning Vinyl exist so far).
Per UI_SPEC.md: "Spinning Vinyl: album thumbnail rendered as a rotating vinyl
record (continuous rotation while playing; physics-based inertia decay to a
stop when paused)." The mockup image shows: an album-thumbnail square held
STATIONARY on the left, with a black vinyl disc mostly visible to its right
(the thumbnail's right edge hides roughly the disc's left quarter), a colored
center label, and a white wedge-shaped "reflection" at a different angular
position in each of 3 example frames (i.e. the DISC ITSELF doesn't move -
only a highlight/glint sweeps around it - much cheaper to fake convincingly
than a true image-rotation transform, and this session's implementation
follows that reading of the mockup).
LAYOUT: thumb_ram's existing 172x172 album image is now LEFT-aligned
(THUMB_X_START = OSC_X_START, was centered pre-Section 31) instead of
centered, occupying the same vertical span as before (y=9..180). The vinyl
disc is drawn PROCEDURALLY (no new image asset) via simple squared-distance-
from-center circle tests: DISC_CX=236, DISC_CY=95 (matches the thumbnail's
vertical center), DISC_R=80 - chosen so the thumbnail's right edge (x=191)
covers only the disc's left ~22% width, leaving roughly 3/4 visible, per the
mockup. Layers (each drawn after / overriding the previous): black disc ->
two thin groove rings (radii 68/52, drawn in COLOR_BORDER) -> rotating
reflection wedge (white) -> center label circle (radius 28, COLOR_HIGHLIGHT
accent - kept the app's existing teal/blue accent for palette consistency
rather than introducing the mockup's red) -> spindle hole (radius 6,
background navy) -> album thumbnail on top (occludes the disc's left portion
last, so it's always in front).
ROTATION: no true image rotation - instead a "reflection wedge" (a rotating
radial highlight, like a glint sweeping around the disc) using a 16-step
cosine/sine lookup table (22.5 degrees/step, values scaled to +-127) and two
dot-product-style projections: `refl_along = dx*cos + dy*sin` (must be
positive - correct half of the disc) and `refl_perp = dx*sin - dy*cos` (must
be small relative to refl_along - within roughly a 26-degree half-angle wedge
via a >>>1 shift comparison). rot_idx advances once every 16 vsyncs
(ROT_DIV_MAX=15) while the vinyl effect is showing AND playback isn't paused
- full rotation takes ~4.3s. This freezes (doesn't decay/coast) when paused,
a simplification vs. UI_SPEC.md's "physics-based inertia" - flagged as a
reasonable first pass, can add real deceleration later if wanted.
NO BOX: per the request ("There shouldn't be a box when selecting the
spinning vinyl tab"), core_top.v's render block was restructured so
`in_osc_area`/`in_osc_border` (the black box fill + border) are now ONLY
drawn `if (!effect_mode_vid)` (oscilloscope mode) - the vinyl effect draws
directly on the normal dark navy background with no frame at all.
DEFERRED (per the user's own "if it's a temporary one it's fine, we can
improve later"): per-track album art extraction (still shows the one bundled
default image for every track), true image rotation, and the "Still
Thumbnail"/"Bar Chart" animations from the UI_SPEC. Also deferred: the
Buttons table in Now_Playing_Tab.drawio.png documents X=shuffle, Y=repeat
mode, and UP/DN cycling among all 4 (not just 2) animations - none of that
is implemented yet; UP/DN currently only toggles between Oscilloscope and
Spinning Vinyl.

--- Feature 3: Library tab - full-screen track list ---
Removed the "now playing" mini preview (title_ram/artist_ram render area)
from the Library tab entirely - `in_title_area`/`in_artist_area` are now
gated on `cur_tab_vid == 2'd0` only (was `cur_tab_vid == 2'd0 || lib_mode`).
That freed up the whole screen below the "LIBRARY " header for the track
list, which no longer needs to leave room for a preview underneath: row
height grew from 16px (glyph-height, packed edge-to-edge) to 36px
(LIST_ROW_H), so 8 rows now span y=28..316 (288px) instead of y=28..156
(128px) - matches the "full screen of tracks" request. Since 36 isn't a
power of 2, list_row is now computed with real division (`list_y_off /
LIST_ROW_H`) instead of a bit-slice - a trivial cost at the 12.288MHz pixel
clock (this design already does a similar division for the progress bar's
fill width, at the much faster 74.25MHz clk_74a, with no timing issues).
Text (16px, 2x-scale) is vertically centered within each 36px row band via a
new LIST_TEXT_PAD (10px) constant. The highlight band still covers the full
row height. The progress bar itself was NOT removed from Library (still
shows actual playback progress, independent of the browse cursor, per its
existing design) - not explicitly requested to go, and it's a thin,
unobtrusive footer; flag if that should go too.

--- Feature 4: Now Playing title/artist repositioned ---
Moved TITLE_Y_START (210 -> 244) and ARTIST_Y_START (230 -> 264) so the
title+artist block (16+4+8=28px total) is centered in the gap between the
box's bottom border (181) and the progress bar (336): usable gap 182..334
(153px), center start = 182 + (153-28)/2 = 244.5. The play/pause icon was
LEFT AT ITS EXISTING POSITION (y=190..205, unchanged) since only title/artist
were requested to move - this does open a larger gap between the icon and
the (now lower) title than before; flag if the icon should move too once
this is seen on hardware, especially since the Spinning Vinyl effect may
want the icon repositioned/removed anyway as that design matures.

FILES CHANGED: data.json (dev copy + dist copy: +deferload on Test Audio,
renamed Default Thumbnail -> Default Thumb), core_top.v (THUMB_X_START
left-aligned, new vinyl disc rendering block + rotation counter/LUT
functions, render block restructured to gate the box vs. the vinyl disc on
effect_mode_vid, TITLE_Y_START/ARTIST_Y_START moved, in_title_area/
in_artist_area no longer include lib_mode, Library list row height/division
+ text vertical centering).

STATUS: HARDWARE-CONFIRMED (2026-07-23, debug log _013720). The deferload fix
is CONFIRMED: the log now shows "Deferred load. Only update data slot size
BRAM" for the Test Audio slot instead of an actual bulk transfer - the exact
mechanism predicted, not just a theory. Library full-screen list and
title/artist repositioning also came through this same test. Spinning Vinyl
rendered and loaded fine (no crashes/errors in the log) but did NOT match the
user's intended design - shows as a static disc centered in the old
oscilloscope-box area, not the album-thumbnail+partially-hidden-disc layout
intended. Corrected in Section 32 (this was a case of the source being
internally consistent and hardware-correct, just not matching the design
brief - see Section 32 for the full redesign, now understood from
plans/Now_Playing_Tab.drawio.png + plans/UI_SPEC.md's actual "Spinning Vinyl"
description rather than a guess).


--------------------------------------------------------------------------------
32. SECTION 32 - MAX_TRACKS 32 + LIBRARY SCROLLING, PLAYBACK BEHAVIOR FIXES,
    NOW PLAYING EFFECTS REWORK, DEFAULT ICON REDESIGN (source done 2026-07-23)
--------------------------------------------------------------------------------
CONTEXT: user hardware-tested Section 31 (log _013720 - deferload fix
confirmed, Library list + title/artist reposition confirmed) and gave a large
follow-up batch: library needs to scale to more tracks with scrolling;
correction that Section 30's ORIGINAL centered static thumbnail was actually
the "Still Thumbnail" effect and should come back (with a larger play/pause
icon per their draft), with "Spinning Vinyl" as a SEPARATE additional effect
(not a replacement) needing several proportion/alignment fixes; Library rows
should show a small per-track thumbnail icon; default thumbnail should be a
music-note icon, not the vinyl-record graphic; no track should auto-play at
boot; selecting a track should always start it playing even if something else
was paused; a multi-second load delay when switching tracks should be
investigated; more test tracks/albums should be added; vinyl label/groove
colors need adjusting. Also asked for a full Album tab (deferred - see below).

--- MAX_TRACKS 8 -> 32 + Library scrolling ---
playlist_ram.sv's MAX_TRACKS parameter (and TOTAL_WORDS/pram[] sizing) raised
from 8 to 32. This required widening every "track index" signal in
core_top.v from 3 bits to 5 bits (track_sel, list_cursor, prev/next_track_sel,
last_track_idx, pram_read_idx, track_sel_r_core, track_sel_s1/vid/vid_prev,
and playlist_ram's track_idx/lib_idx ports + its 4-bit->6-bit track_count
output) - a wide-reaching but mechanical change, checked carefully with
iverilog after each pass (see VERIFICATION below). playlist_ram.sv's bridge-
write address-range check was ALSO widened (it hardcoded a 10-bit/1KB window
matching the old MAX_TRACKS=8 size; for MAX_TRACKS=32 the window is 4KB and
the old hardcoded compare would have silently dropped writes to the upper 3KB
- caught during this pass, not yet hit on hardware, since no test with >8
populated tracks had been tried before).
Library now shows an 8-row VISIBLE WINDOW that scrolls over up to 32 tracks:
new list_scroll register (top-of-screen track index) tracks list_cursor,
adjusting by the minimum amount needed to keep the cursor on-screen (mirrors
a typical "keep selection visible" list widget), reset to match on
wraparound (cursor wrapping to the first/last track also resets scroll to
the first/last page). list_row (0..7, which visible row) + list_scroll gives
list_track_idx, the actual playlist index a given row displays - this is
what now drives playlist_ram's lib_idx port (previously list_row was used
directly, which only worked because there were never more than 8 tracks).

--- Playback behavior fixes ---
No autoplay at boot: `paused` now resets to 1 (was 0). Root cause of the
unwanted autoplay: Pocket's own interact-persistence mechanism restores the
last-used "Track" value automatically every boot (confirmed happening in
every debug log's Prerun section: "Interact: writing control value of
'Track' into core") - since `paused` previously defaulted to 0 (playing),
whatever track that persisted value pointed to would start playing with NO
user action this session. Now it stays silent until an explicit selection.
Always-play-on-select: Library's A-select handler (lib_select_r) now also
sets `paused <= 1'b0` - previously selecting a track while something else
was paused left `paused` untouched, so the newly-selected track would load
but stay silent until a separate A-press in NowPlaying. Both fixes are in
the same always block (the A-button handler, core_top.v) since that's where
`paused` was already being managed.

--- Track-switch load delay: investigation + fix ---
SYMPTOM: user reported tracks take a few seconds to start playing after
selection, and suspected (correctly) that this is a "how many chunks does it
wait for" issue rather than raw SD throughput, since SD read speed should be
consistent.
INVESTIGATION: traced audio_streamer.sv's `initial_fill_done` signal, which
gates `audio_loaded` (and therefore the I2S output). It was asserting only
once `chunks_written` reached `RING_SLOTS - 1` = 15 - i.e. the code was
waiting for the ENTIRE 16-slot ring buffer (16 x 0.5MB = 8MB) to fill before
allowing ANY sound, on every track change (the WAIT_DONE case resets
initial_fill_done to 0 whenever track_select changes, in the REQ state's
track-change branch). At the confirmed ~20-24MB/s sustained throughput
(Module 2b), 8MB alone is only ~350-400ms - the fact the user perceives
multiple seconds strongly suggests each chunk request also carries fixed
per-request protocol overhead (APF bridge round-trip: Request Write command,
wait-for-clear, wait-for-done - see the debug log's per-chunk "Target: New
command [0180]" / "Target: Read to..." pairs), which is paid 16 times over
before the FIRST sample plays, even though only the first chunk or two are
actually needed before playback can safely start (the ring buffer's whole
job is to stay AHEAD of playback, not to start full).
FIX: added a new `INITIAL_FILL_CHUNKS` parameter to audio_streamer.sv
(default 2, instantiated explicitly in core_top.v), and changed the
fill-done condition to `chunks_written == INITIAL_FILL_CHUNKS - 1` instead
of the hardcoded `RING_SLOTS - 1`. Playback now starts after just 2 chunks
(1MB) land - REQ keeps requesting further chunks up to RING_SLOTS in the
background exactly as before, so steady-state buffering margin (the ~109x
timing margin from Module 2c's original analysis) is unchanged; only the
one-time startup wait shrinks roughly 8x. This applies to every track
switch (Library select, D-pad next/prev, auto-advance), not just boot, since
it's the same FSM path for all of them.
NOT YET HARDWARE-VERIFIED - this is a real, well-understood mechanism (the
FSM logic is straightforward, self-reviewed and iverilog-checked) but the
actual perceived latency reduction can only be confirmed by testing on
hardware. If 2 chunks still isn't fast enough (unlikely given the analysis
above) or introduces glitches (also unlikely - steady-state margin is
unaffected), INITIAL_FILL_CHUNKS is a single easily-tunable parameter.

--- Now Playing effects reworked: 3 effects, Still Thumbnail restored ---
Section 31 had (incorrectly) repurposed Section 30's original centered static
thumbnail INTO the Spinning Vinyl effect, per a misreading of the plans - the
user clarified the original centered-thumbnail effect was already correct as
"Still Thumbnail" (one of 4 planned animations per plans/UI_SPEC.md) and
should come back as its own effect, with Spinning Vinyl as a third, separate
one. effect_mode widened from 1 bit (toggle) to 2 bits (3-way cycle:
0=Oscilloscope, 1=Still Thumbnail, 2=Spinning Vinyl via D-pad Up/Down in
NowPlaying) - this ALSO required widening the synch_3 instance that crosses
effect_mode into the video clock domain (synch_3's default WIDTH=1 would
have silently truncated a 2-bit signal to its LSB - caught during self-review
before it became a real bug).
Still Thumbnail: centered 172x172 album art (thumb_x_start_eff =
THUMB_X_STILL = 114, centers the image alone in the 360px art area) + a NEW
large play/pause icon (32x32, 4x scale - "a larger play and pause icon" per
the user's draft) below it, reusing the same play/pause bitmap shapes as the
small icon just at a bigger scale. The existing small 2x-scale icon is now
suppressed specifically in Still Thumbnail mode (in_icon excludes
EFFECT_STILL_THUMB) so the two don't overlap.
Spinning Vinyl geometry fixes:
  - "About 1/2 hidden" (was ~1/4 hidden aiming for "3/4 visible"): disc center
    (DISC_CX) now sits EXACTLY at the thumbnail's right edge
    (THUMB_X_SPINNING + 172) - since any line through a circle's center
    always bisects it into two equal halves, this hides exactly half the
    disc's area by construction, no approximation needed.
  - "Whole thumbnail and vinyl aligned in the middle" (was left-aligned):
    THUMB_X_SPINNING is now centered accounting for the combined shape's
    width (thumbnail 172px + visible disc half 80px = 252px), giving
    THUMB_X_SPINNING = OSC_X_START + (360-252)/2 = OSC_X_START+54 = 74, and
    DISC_CX = 74+172 = 246 - verified symmetric (both margins work out to
    54px from the 360px art area's edges).
  - Two reflections on opposite sides (was one): added a second wedge test
    using rot_idx+8 (wraps automatically in 4-bit arithmetic - exactly 180
    degrees in the 16-step/22.5-degree table), reusing the same rot_cos_f/
    rot_sin_f lookup functions.
  - Groove rings redesigned to match tools/make_default_thumb.py's original
    vinyl-icon styling (3 thin rings at radii 68/54/40, not 2 thicker ones)
    but colored close to the disc's own black (COLOR_GROOVE = 0x14141C,
    barely distinguishable from the 0x000000 base) instead of the much
    brighter COLOR_BORDER, which read as a flat gray ring rather than a
    subtle groove texture - "colors remaining the black main color" per the
    request. Band half-width also thinned (200 -> 130 squared-distance
    units).
  - Label color: no true per-album color extraction exists yet (that needs
    real per-track art, which is deferred - see below), so as an honest
    placeholder, the label uses a new COLOR_LABEL (0xFA3C64) chosen to MATCH
    the redesigned default thumbnail's own accent color (see next section) -
    "matches the album cover" is trivially true right now since every track
    shares the same default cover, but the two are now at least
    intentionally coordinated rather than arbitrary (previously used the
    site-wide teal COLOR_HIGHLIGHT, unrelated to the thumbnail at all).
  - thumb_ram's single registered read port is now shared THREE ways (Still
    Thumbnail display, Spinning Vinyl's thumbnail portion, and the new
    Library per-row icon below) via a priority mux on next_in_thumb /
    next_in_list_icon - safe because NowPlaying and Library are never the
    active tab simultaneously.

--- Library per-row thumbnail icon ---
Each visible row now shows a 30x30 icon (same shared default image for every
row, for now - see "deferred" below) to the left of the title text.
Downscaled from the 172x172 source via nearest-neighbor (integer
multiply-divide: src = (dst * 172) / 30 - cheap at the 12.288MHz pixel clock,
same reasoning already applied to the row-height division). Text now starts
at x=56 (LIST_X_START) instead of x=28 to make room for the icon + a small
gap; LIST_CHARS trimmed from 22 to 19 visible characters accordingly.

--- Default thumbnail redesigned: music-note icon (was vinyl-record) ---
tools/make_default_thumb.py rewritten: instead of the vinyl-record-styled
placeholder (whose ring/label style is now reused for the Spinning Vinyl
disc itself, see above), the DEFAULT THUMBNAIL is now a simple Apple-Music-
style icon - a vertical pink gradient background (0xFF6E8C top -> 0xFA3C64
bottom) with a white eighth-note glyph (notehead + stem + flag, drawn with
plain PIL primitives, no external assets) centered on it. Regenerated
dist/Assets/musicplayer/common/default_thumb.bin (59168 bytes, verified
against data.json's size_exact, matches exactly as before - format
unchanged, only the pixel content differs).

--- Test library expanded: 26 tracks, 2 artists, 5 albums ---
tools/convert_audio.py gained a `--dirs` (plural) mode: scans MULTIPLE
directories in the given order (each sorted by filename internally) and
concatenates all their tracks into one combined playlist/audio blob, capped
at MAX_TRACKS=32 total. Also fixed a real bug hit while running this:
Windows' console codepage (cp950 in this environment) can't print/decode
non-ASCII filenames (one source file has a Korean featured-artist credit in
its name) - added a `sys.stdout/stderr.reconfigure(encoding="utf-8",
errors="replace")` at the top of the script so any Unicode filename prints
safely regardless of the console's codepage, instead of crashing the whole
conversion mid-run.
Generated from ITZY/CHESHIRE (2022) + ITZY/Girls Will Be Girls (2025) +
ITZY/ITZY - GOLD (2024) + NewJeans/OMG (2023) + NewJeans/Supernatural (2024)
= 26 tracks total (20 ITZY + 6 NewJeans), via
  py tools/convert_audio.py --dirs "source_musics/ITZY/CHESHIRE (2022)" "source_musics/ITZY/Girls Will Be Girls (2025)" "source_musics/ITZY/ITZY - GOLD (2024)" "source_musics/NewJeans/OMG (2023)" "source_musics/NewJeans/Supernatural (2024)" --use-tags
test_audio.bin is now 880MB (922,746,880 bytes, 1760 chunks) - data.json's
Test Audio size_exact updated automatically to 0x37000000. One track's
featured-artist name contains Korean characters ("VAY (Feat. 창빈 of Stray
Kids)") - the 64-char ASCII-only OSD title correctly falls back to "??" for
those two characters (font_rom.v only has ASCII glyphs, so this is the
correct/expected behavior, not a bug), while the Pocket's own interact menu
(which supports Unicode) keeps the real characters. Good test case for
verifying title truncation/fallback behavior.

--- Album tab: EXPLICITLY DEFERRED ---
The user asked for a full Album tab implementation (two-screen drill-down -
album list with thumbnail+artist/title, then A to enter and see the album's
songs - per plans/Album_List_Tab.drawio.png and plans/UI_SPEC.md's "Album
List Tab" section) in the same message as everything else above. This is
comparable in scope to the ENTIRE Library tab redesign from Section 30 on
its own (new list rendering, a second "screen" with its own navigation
state, thumbnail integration, back-navigation). Given the size of everything
else already in this one batch, and given each hardware-test cycle is slow
(Quartus recompile + SD copy + a real test on the device), implementing it
now - untested alongside a dozen other simultaneous changes - was judged too
risky to do well. NOT STARTED. Recommend its own dedicated session/test
cycle once Section 32's changes are confirmed working.

FILES CHANGED: playlist_ram.sv (MAX_TRACKS 8->32, track_idx/lib_idx/
track_count widened, bridge-write address window widened 10->12 bits),
audio_streamer.sv (track_select/track_sel_r widened, new
INITIAL_FILL_CHUNKS parameter), core_top.v (extensive - track-index
widening throughout, list_scroll + scrolling logic, effect_mode widened to
2 bits + 3-way cycle, Still Thumbnail/Spinning Vinyl geometry rework, dual
reflection, groove/label colors, Library per-row icon, paused reset value +
lib_select_r-clears-paused, synch_3 WIDTH fix), tools/make_default_thumb.py
(rewritten for the note icon), tools/convert_audio.py (MAX_TRACKS 32,
--dirs mode, UTF-8 stdout fix), data.json (dev+dist: Test Audio/Playlist
size_exact updated for the new test content).

VERIFICATION: entire source tree (core_top.v + all core/*.v,*.sv + apf/
common.v) elaborates cleanly with `iverilog -g2012 -Wall -tnull` after every
major edit pass in this section - zero new errors or warnings beyond the 2
expected pre-existing missing-megafunction-IP errors (mf_datatable/
mf_pllbase), same as every prior section's verification.

STATUS: SOURCE DONE (2026-07-23), self-reviewed + iverilog-checked (not
compiled - Claude cannot run Quartus). Needs a full recompile + SD deploy
before hardware testing (test_audio.bin is now 880MB - the SD copy step
itself will take noticeably longer than previous rounds). See NEXT_STEPS.txt.
UPDATE: user's first compile attempt FAILED to fit the device - see Section
33 for the diagnosis and fix (playlist_ram.sv memory layout).


--------------------------------------------------------------------------------
33. SECTION 33 - FITTER FAILURE: playlist_ram.sv MEMORY LAYOUT REDESIGN
    (source done 2026-07-23)
--------------------------------------------------------------------------------
CONTEXT: user attempted the Section 32 Quartus compile and it FAILED to fit
the device (screenshot of Quartus Prime Lite's Compilation Report): "170012
Fitter requires 2256 LABs to implement the design, but the device contains
only 1848 LABs" / "11802 Can't fit design in device" / Logic utilization
22,132 / 18,480 ALMs (120%). This is the FIRST time this project has hit a
device-capacity wall - every prior section fit comfortably.

DIAGNOSIS: playlist_ram.sv's pram[] was a FLAT 32-bit-wide word array
(TOTAL_WORDS = MAX_TRACKS*32), and both read ports reconstructed a track's
fields by reading ~25 DIFFERENT WORD ADDRESSES SIMULTANEOUSLY every cycle
(one direct `pram[{track_idx, 5'dN}]` read per title/artist word, for N=0..24,
times 2 ports = ~50 simultaneous different-address reads total). A block RAM
port (M10K on this Cyclone V part) can only present ONE address per cycle -
this access pattern is not a template Quartus's memory inference recognizes,
so instead of mapping pram[] to dedicated M10K blocks, Quartus was very likely
building it as distributed registers plus a large per-field multiplexer/
decode network. That scales directly with MAX_TRACKS (more rows = wider
muxes) - fine at the old MAX_TRACKS=8, but blew the budget once Section 32
raised it to 32 (4x the rows). This was caught independently while trying to
verify the file with iverilog: `iverilog -g2012 -tnull core/playlist_ram.sv`
produced repeated "sorry: constant selects in always_* processes are not
currently supported" and, after an intermediate fix attempt, hard errors
("All but the final index in a chain of indices must be a single value, not
a range") - iverilog struggling to even simulate this pattern cleanly was a
strong independent signal that the RTL idiom itself was unusual/expensive,
consistent with the Quartus fitter's finding.

FIX: restructured pram[] from a flat word array into ONE WIDE ROW PER TRACK
(`logic [1023:0] pram [0:MAX_TRACKS-1]` - each row is a track's whole 128-byte
record). Now each read port does exactly ONE address lookup (`pram[track_idx]`
/ `pram[lib_idx]`), and the individual fields (start_chunk, chunk_count,
title, artist) are extracted by bit-slicing that single already-fetched wide
value - free wire routing, not additional memory reads. Word N of a track's
record is always at bits [N*32 +: 32] of its row, matching the existing write
side (bridge writes decode a flat word index into row + word-within-row, then
write `pram[row][word*32 +: 32] <= bridge_wr_data`, which is a normal word-
enabled write to a wide row - a standard, cheap pattern, unlike the read side).
Also replaced track_count's old per-cycle 32-address scan (`for (i=0;
i<MAX_TRACKS;i++) if (pram[i*32][15:0]!=0) ...`, the same "many simultaneous
addresses" cost applied to a THIRD access pattern) with an INCREMENTAL counter
that watches the write stream directly: any word-0 (header) write with a
nonzero chunk_count bumps a register once, during the one-shot boot load -
zero extra memory reads needed, since the value being counted (chunk_count)
is already in hand as bridge_wr_data at write time.
Fixed the resulting iverilog chain-of-indices errors by introducing named
intermediate signals (track_header_word, lib_word) instead of chaining two
part-selects on the same expression (`row[a+:b][c:d]`) directly - iverilog
(and likely Quartus's parser) wants a chain's non-final indices to be a
single value, not a range.

NOT YET HARDWARE-VERIFIED - this is a well-reasoned, textbook fix for a
well-understood class of synthesis problem (multi-address-per-port memory
reads defeat block-RAM inference), and it now elaborates cleanly with
iverilog (previously it did not even simulate cleanly), but the actual ALM/
LAB usage after this fix can only be confirmed by re-running the Quartus
fitter. If it's still over budget, the compilation report's exact utilization
numbers will show how much closer this got and whether anything else needs
attention.

FILES CHANGED: playlist_ram.sv (memory layout redesign, described above).

UPDATE (2026-07-24): the round-1 fix made things WORSE, not better - re-run
showed 26,173/18,480 ALMs (142%, up from 120%) and a NEW error type ("Design
contains 44446 blocks of type combinational node. However, the device
contains only 36960 blocks" - 36960 = 18480 ALMs x 2 ALUTs/ALM, so this is
the same class of overflow, just measured in LUTs instead of LABs). Since
ONLY playlist_ram.sv changed between the two attempts, this increase is
directly attributable to that change.
ROUND 2 DIAGNOSIS: the round-1 WRITE side wrote directly into a
variable-bit-offset slice of a pram[] ARRAY ELEMENT
(`pram[wr_row][wr_word*32 +: 32] <= bridge_wr_data`). That combination -
an indexed array element PLUS a runtime-variable sub-word offset within it -
is not a standard block-RAM write template either (block RAM write ports
expect a full-width write or static/fixed-lane byte-enables, not an address
that shifts by a variable amount) - so pram[] was very likely STILL being
built as raw registers despite the read-side fix, and the read side now had
to mux a full 1024-bit row every read instead of the ~800 bits actually used
by the old per-field reads - a net increase, matching the observed result.
ROUND 2 FIX: stage each track's words 0..30 into a plain (non-array) 992-bit
register as they stream in (a variable-offset write into a lone register is
ordinary datapath logic - no memory-inference ambiguity, since it's not an
indexed array access at all), then commit the ENTIRE 1024-bit row to pram[]
in ONE single full-width write when the last word (31) arrives. This is the
simplest, most standard block-RAM write pattern possible (one address, one
full-width write) - relies on bridge writes landing in strictly ascending
word order within each track, true for this one-shot sequential file load.
Also added an explicit `(* ramstyle = "M10K" *)` attribute to pram[] (matches
thumb_ram.sv's existing convention) as a hint, though the write-pattern fix
should matter more than the attribute alone.
STILL NOT HARDWARE/FITTER-VERIFIED - elaborates cleanly with iverilog, and
this is now the standard textbook pattern for streaming-write block RAM, but
given round 1 was ALSO reasoned through carefully and still made things
worse, this round 2 result should be treated as "best current understanding,
not a guarantee" until the Fitter actually confirms it.

STATUS: SOURCE DONE (2026-07-24), self-reviewed + iverilog-checked (not
compiled - Claude cannot run Quartus). Please re-run the Quartus compile and
report the new Fitter result - specifically the ALM/LAB/ALUT utilization
percentages either way (pass or fail), since that number is what tells us
whether this round actually helped. See NEXT_STEPS.txt.

ROUND 2 RESULT (2026-07-24): improved but still failing. 21,525/18,480 ALMs
(116%, better than both the original 120% AND round 1's 142%) - "Fitter
requires 2178 LABs but the device contains only 1848 LABs" (down from 2256).
Round 2's write-side fix genuinely helped. But: "Total block memory bits" =
481,536/3,153,920 (15%) - and this exact number is IDENTICAL across every
single attempt (original, round 1, round 2). That was the key clue picked up
on for Section 34 below: if pram[]'s storage were actually landing in block
RAM in any of these attempts, that figure would have moved. It never did -
meaning `pram[]` had never once become real block RAM, in any version,
regardless of read/write pattern cleanliness.

================================================================================
34. SECTION 34 - FITTER FAILURE ROOT CAUSE FOUND: COMBINATIONAL READS NEVER
    BLOCK-RAM-ELIGIBLE (source done 2026-07-24)
--------------------------------------------------------------------------------
CONTEXT: Section 33's round 2 fix (staged write + single full-width commit)
measurably helped (142%->116% ALM) but the design still didn't fit, and
"Total block memory bits" hadn't moved by even one bit across all three
attempts (see above). That was the tell.

ROOT CAUSE: `track_row`/`lib_row` were plain COMBINATIONAL reads
(`wire [1023:0] track_row = pram[track_idx];`) - no clock involved at all.
Cyclone V M10K block RAM primitives ONLY have SYNCHRONOUS (registered) read
ports - you present an address on a clock edge and the data appears the
FOLLOWING cycle. A bare combinational array read is an unconditional signal
to Quartus's memory inference that the array can't be mapped to block RAM,
no matter how clean the addressing or write pattern is - so despite two
rounds of read/write-pattern fixes, `pram[]` was still being built entirely
out of raw registers + a 32:1 mux per port (two independent ports = two full-
width muxes), which is exactly what a ~32,768-bit register array packed for a
1848-LAB budget looks like when it doesn't fit.

FIX: registered both reads in playlist_ram.sv:
  logic [RECORD_BITS-1:0] track_row;
  always_ff @(posedge clk) track_row <= pram[track_idx];
(and the same for lib_row). This is the textbook fix, but it adds 1 cycle of
read latency, which is NOT free from the outside - two different consumers
needed different treatment:

  - lib_idx (Library list display): list_track_idx only changes at row-height
    boundaries (every 36 scanlines), and Y always increments during
    horizontal blanking - hundreds of cycles of margin before the next row's
    first visible pixel is drawn. The 1-cycle latency settles invisibly; no
    retiming needed here at all.

  - track_idx (audio path: title_ram/artist_ram refresh AND audio_streamer's
    chunk_idx seed on track switch): several places in core_top.v assumed
    pram_title/pram_artist/pram_start/pram_chunks were valid the SAME cycle
    pram_read_idx reflected a new value (true under the old combinational
    read). Registering the read breaks that assumption for FOUR separate
    track-changing events (interact.json Track menu, D-pad prev/next,
    auto_advance, Library A-select) and for audio_streamer's
    `track_select != track_sel_r` chunk_idx seed.

    Rather than retime every consumer (risky - audio_streamer's chunk_idx
    seed in particular is playback-correctness-critical, not cosmetic), used
    a PREDICTIVE ADDRESSING trick: feed playlist_ram's track_idx a NEW signal,
    pram_read_idx_next, that computes what track_sel is ABOUT TO BECOME one
    cycle before it actually changes (same 4-branch priority mux that
    decides track_sel's next value: bridge Track-menu write > D-pad prev/next
    > auto_advance > Library A-select > else unchanged). This means the
    registered read has ALREADY fetched the new row by the exact cycle
    track_sel/pram_read_idx visibly changes - i.e., pram_title/pram_artist/
    pram_start/pram_chunks become valid at EXACTLY the same relative cycle
    external consumers already expected, matching the existing two-stage
    "_r" delayed-echo pattern (auto_advance/auto_advance_r,
    lib_select_r/lib_select_r2) with zero timing change needed in any of
    them. Verified by hand-tracing all 4 track-changing paths plus
    audio_streamer's chunk_idx seed against this new timing - all align.
    The ONE path that previously had no "_r" echo (the interact.json Track-
    menu bridge write, which used to copy title/artist SAME-cycle relying on
    zero-latency combinational reads) needed a NEW one-cycle-delayed pulse,
    `track_menu_r`, added to the same title/artist-refresh priority chain.

FILES CHANGED:
  - playlist_ram.sv: track_row/lib_row changed from combinational wires to
    registered (`always_ff @(posedge clk) ... <= pram[...]`).
  - core_top.v: pram_read_idx replaced with pram_read_idx_next (predictive,
    4-branch mux mirroring track_sel's own next-value logic); playlist_ram's
    track_idx port now fed pram_read_idx_next; new track_menu_r register +
    title/artist-refresh branch added to the priority chain (mirrors
    auto_advance_r/lib_select_r2/dpad_advance_r); several now-stale comments
    describing the old combinational-read timing updated to match.

Also added the general lesson to root CLAUDE.md's platform reference: block
RAM inference requires REGISTERED reads, not just single-address-per-port
combinational reads - this is a DIFFERENT requirement from the read/write
addressing-pattern fixes in Section 33, and either one alone is not enough.

NOT YET HARDWARE/FITTER-VERIFIED - elaborates cleanly with iverilog (zero new
errors/warnings beyond the 2 expected pre-existing missing-IP ones), and the
predictive-addressing timing was hand-verified against all 5 consumer paths,
but the actual ALM/LAB/block-memory-bits usage can only be confirmed by
re-running the Quartus fitter. If "Total block memory bits" finally moves up
from 481,536, that alone will confirm pram[] is finally landing in real M10K
blocks. Please report the exact utilization numbers (ALMs, LABs, AND total
block memory bits) either way. See NEXT_STEPS.txt.

STATUS: SOURCE DONE (2026-07-24), self-reviewed + iverilog-checked, awaiting
Quartus recompile.


================================================================================
35. SECTION 35 - SECTION 34 HARDWARE-CONFIRMED; PER-TRACK ALBUM ART + BLURRED
    BACKGROUND, ICON UNIFICATION, LAYOUT/BUG FIXES (source done 2026-08-03)
================================================================================
CONTEXT: user hardware-tested Section 34's registered-read fix (debug log
_221319, 2026-08-03) - it compiled/fit successfully this time (the log shows
"Deferred load. Only update data slot size BRAM" for Test Audio, a full boot
sequence, and an extended playback session with zero errors and a clean
"Unload complete" at the end). NOTE: the user did not report the specific
Quartus utilization numbers (ALMs/LABs/total block memory bits) NEXT_STEPS.txt
asked for - still worth getting next round to fully close out Section 34's
open question, though the successful hardware run already confirms it fits.
Separately, the user gave a large new batch of feedback (prompts/prompt_002.txt):
(1) asked to make sure git is up to date; (2) library loading feels slow,
suggested a PC-generated lookup table; (3) Now Playing effects have no gap to
the screen top; (4) album thumbnails never show (always the default); (5)
wants a dimmed/blurred version of the thumbnail as the Spinning Vinyl/Still
Thumbnail background; (6) after the last track auto-advances to the first,
track info shows blank, and "next" afterwards seems stuck repeating the first
track while "previous" correctly walks back through the library; (7) the
default thumbnail's note glyph's flag looks like a rectangle, not a triangle;
(8) the play/pause icon differs in size across the three NowPlaying effects
and looks low-res.

--- Git housekeeping ---
Six sessions' worth of confirmed/source-done work (Sections 29-34) had
accumulated uncommitted (per the user's own standing instruction to commit
after hardware confirmation, which had been missed across a multi-week gap
between the 2026-07-23/24 and 2026-08-03 sessions). Committed as one
checkpoint (commit a60481d) covering Sections 29-34 plus today's Section 34
hardware confirmation, before starting any of this session's new work - so
the "confirmed working" boundary in git history matches what was actually
on the SD card for the _221319 test, and this section's new changes are
cleanly separated on top of it.

--- Library loading: investigated, likely NOT fixable from our side ---
The user's proposed fix - "make a look-up list for the library when
generating the whole tracks file, including title/trackname/location...
moving all complicated work onto the PC" - is EXACTLY what playlist.bin/
playlist_ram.sv have done since Section 29: a small (4KB for 32 tracks)
precomputed table with each track's title, artist, start_chunk, and
chunk_count, generated once by tools/convert_audio.py and loaded in full at
boot. The FPGA never scans or parses test_audio.bin's actual audio bytes to
learn track metadata - that mechanism already doesn't exist to be slow.
Today's own debug log confirms the boot sequence completes in a handful of
log lines with the "Deferred load" line for Test Audio (the one large file)
and instant "Slot: load done" for Playlist/Track Thumbs - nothing in our own
core's boot path scans hundreds of megabytes.
Given that, the most likely explanation for a loading bar that "runs the
full loading bar over several times and doesn't come to an end" is the
Analogue Pocket OS's OWN pre-Prerun asset-verification step - locating/
confirming an ~880MB file's existence and size on the SD card - which
"deferload" cannot help with (deferload only skips copying the file's
CONTENT at boot; the platform still has to find the file on the filesystem
first, and that lookup cost scales with the file's size/fragmentation on
the SD card independent of anything our data.json flags declare). This is
outside this core's control if true. NOT CONFIRMED - please clarify next
round exactly when the slow bar appears (the Pocket's OWN boot screen
before our UI ever appears, vs. something after the core starts, e.g.
opening the Library tab) - these would have very different fixes (the
former likely isn't fixable by us at all; the latter would point at
something in our own RTL we could actually change).

--- RESOLVED (2026-08-05): it was never a loading bar at all ---
Follow-up conversation (same day) pinned this all the way down through a
few rounds of clarifying questions: the "loading bar... runs several
times, never comes to an end" was the ORDINARY PLAYBACK PROGRESS BAR,
which Section 31 deliberately kept visible as a thin footer at the bottom
of the Library tab ("shows actual playback progress, independent of the
browse cursor... flag if that should go too"). It behaves completely
correctly (fills once per track, cycles as tracks naturally advance, turns
amber when paused) - there was never a bug here, at any point, in any
version. The user was looking at the Library tab specifically, watching
that bar cycle through consecutive tracks during normal playback, and
reasonably read a bar that keeps refilling and never permanently finishes
as a stuck "loading" indicator, especially having no other reason to
expect a footer-sized bar there to mean "now playing progress" rather than
"library is loading." The playlist.bin lookup-table explanation from
earlier in this section was correct on its own terms (that mechanism truly
isn't slow) but was answering a question that didn't describe what was
actually being observed.
FIX: the progress bar (and its separator line above it) is no longer shown
on the Library tab at all - see "Library tab: progress bar removed" below.
This is the actual, complete fix for the entire original complaint; no
further investigation needed on the "boot vs. Pocket OS" angle above.

--- Now Playing layout: top gap widened, icon repositioned ---
OSC_Y_TOP (top margin before the oscilloscope box / thumbnail / vinyl,
previously a flush 8px) widened to 24px - the borderless Still Thumbnail/
Spinning Vinyl effects in particular had nothing to visually indicate an
intentional top margin, reading as accidentally cut off. OSC_Y_BOTBRD/
OSC_Y_BOT/DISC_CY - previously all independent hardcoded constants that
happened to be consistent with OSC_Y_TOP=8 - are now expressions derived
FROM OSC_Y_TOP, so this and any future top-gap retune can't silently
desync the waveform baseline or the vinyl disc's vertical center from the
box/thumbnail position again (this session's own investigation had to
manually re-derive that relationship before it was safe to change - not
something to redo by hand next time).
The freed-up vertical space (previously an oversized, unstructured gap
between the box and the progress bar) is now deliberately split three ways
alongside the play/pause icon's new position: 26px gap -> 32px icon -> 26px
gap -> title/artist block (28px) -> 26px gap -> progress bar. This also
resolves a gap Section 31 explicitly flagged and deferred ("this does open
a larger gap between the icon and the (now lower) title... flag if the icon
should move too") - the icon is now positioned relative to the same layout
recalculation, not left at its old Section 29 position.

--- Play/pause icon: unified to one size, doubled bitmap resolution ---
Previously Still Thumbnail alone got a large 4x-scale (32x32) icon while
Oscilloscope/Spinning Vinyl showed a separate, smaller 2x-scale (16x16) one
- both scaled from the SAME 8x8 source bitmap. Per the request that all
three effects use the larger icon, the small-icon path (in_icon/ICON_X_2X/
ICON_Y_2X/play_bmp/pause_bmp at 8x8) is retired entirely; in_big_icon is no
longer gated to EFFECT_STILL_THUMB, so it now renders in all three.
Separately addressed "the play icon looks very low-res" (a fair complaint -
blowing up an 8x8 source 4x for a 32x32 icon means only 8 discrete steps
across the triangle's diagonal edge): the source bitmap resolution is
doubled to 16x16, rendered at 2x scale instead of 4x for the SAME 32x32
final footprint - the triangle's diagonal now has 16 steps instead of 8,
at no visual size cost. play_bmp_row() computes the triangle's per-row lit
width as a function (1..8, mirrored) instead of a 4-way case, since there
are now 16 rows to cover instead of 8; PAUSE_BMP is a single 16-bit constant
(two 4-column bars with a 4-column gap, same on every row).

--- Default thumbnail note icon: flag redrawn as an actual triangle ---
tools/make_default_thumb.py's eighth-note flag was a 4-point polygon (two
points on the stem's edge, two bulging out) that read as a rectangle at the
top per the report, not a triangle. Replaced with a clean 3-point polygon
(attached to the stem at top and bottom, tapering to one tip on the right) -
regenerated and visually confirmed (see track 26/default-fallback preview
during this session's testing - clean triangular flag, no more rectangular
lobe).

--- Track wraparound / "next" stuck bug: one confirmed fix, root cause of
    the main symptom NOT conclusively identified ---
Traced the full track-change chain end to end: pram_read_idx_next's
predictive-addressing mux (Section 34), the track_sel priority chain,
next_track_sel/prev_track_sel/last_track_idx's wraparound arithmetic,
chunks_played's track-change reset, playlist_ram's track_count incremental
counter, and dpad_next/dpad_prev's edge-detect registers. For the current
26-track library, every one of these traces out consistent and correct by
hand - I could not reproduce the reported "next always lands back on track
0" behavior from the RTL's logic alone.
ONE confirmed, real bug found and fixed regardless: last_track_idx was
computed as `pram_track_count[4:0] - 1` - truncating the 6-bit live track
count to 5 bits BEFORE subtracting, which is a no-op for any count under 32
(the dropped bit is always 0) but silently produces last_track_idx=0 at
exactly MAX_TRACKS=32 tracks. Not the active cause today (26 != 32), but a
real latent bug the first time the library grows to exactly 32 - fixed now
(subtract at full 6-bit width, truncate the RESULT instead).
Re-examined today's actual debug log (_221319) for direct evidence: the
"Target: Read to ... from file 0x0000000000" pattern (the ring buffer
restarting from track 0's first chunk) recurs dozens of times through the
log, including a few back-to-back repeats with literally zero chunks
progressed in between (e.g. three consecutive "read chunk 0" lines with
nothing else around them) - and separately, several jumps to OTHER
non-adjacent tracks' start chunks (e.g. tracks 20, 22, 24's start offsets
appearing directly, not via a gradual climb/descent). Both patterns are
consistent with the user actively probing this exact issue by hand (via
D-pad and/or Library A-select) during the session, which - given this
design's "interrupt-and-restart the ring buffer immediately on ANY track
change" behavior - would itself look chaotic in the log regardless of
whether the underlying next/prev logic has a bug, since rapid repeated
changes never let one selection's audio become audible before the next
interrupts it. This is a plausible, hardware-log-consistent explanation for
what was seen, but it is NOT the same as confirming next_track_sel's
formula is correct in the exact scenario the user hit - the trace above
shows it SHOULD be, not that it definitely IS on real hardware.
NEEDS a precise repro to pin down further: next round, please describe the
exact button sequence (which tab, which button, single taps vs. rapid/
held) that produces "next repeats the first track" reliably, ideally
starting from a fresh boot rather than after other navigation. Given how
much log noise a plausible innocent explanation (rapid manual testing)
could account for, guessing at a speculative RTL fix here risked spending a
whole hardware cycle confirming a fix for the wrong problem.

--- Per-track album art + blurred/dimmed background (major new feature) ---
GOAL: replace the single shared default thumbnail (Section 30) with real
per-track album art extracted from each file's own embedded cover art, plus
a soft blurred/dimmed backdrop behind Still Thumbnail/Spinning Vinyl
(previously flat navy) - both explicitly requested, with the user's own
fallback guidance ("if it's difficult on hardware, just make the PC do the
work") shaping the design below.
BRAM BUDGET DROVE THE ARCHITECTURE: 32 tracks x 172x172 RGB565 (59168 bytes
each) would be ~1.85MB (14.8Mbit) if every track's art were resident in
block RAM at once - many times the Cyclone V 5CEBA4's ~3.08Mbit budget,
which Sections 33/34 already fought hard to fit into even without this.
So art is loaded ON DEMAND, one track's worth at a time (reloaded whenever
track_sel changes) - the SAME BRAM footprint as the old single-default
design (~462Kbit for one 172x172 image), not 32x it.
DATASLOT ARBITRATION - the harder problem: the APF data-slot protocol only
supports ONE outstanding target_dataslot_read at a time SYSTEM-WIDE
(target_dataslot_done is a single shared completion pulse, not tagged per
request) - core_top.v's existing 3-way mux only stayed safe because
playlist_ram/thumb_ram each requested exactly ONCE at boot and then sat
permanently idle, leaving audio_streamer as the only requester for the rest
of the session. Per-track art needs to be RE-fetched every track change -
a second requester active for the WHOLE session, which would have raced
against audio_streamer's continuous chunk requests with no existing
mechanism to prevent two overlapping in-flight requests from corrupting
each other's completion detection. Rather than build new cross-module
arbitration (real risk of a subtle protocol-level bug in the hardest-to-
debug class - silent data corruption - in the most safety-critical file in
this project), art fetching is instead folded into audio_streamer.sv's OWN
single state machine as a new LOWEST-PRIORITY filler task: on every track
change it now also sets img_pending; REQ only starts an image fetch once
there is no audio chunk work to do this cycle (chunks_in_flight >=
RING_SLOTS) - so audio chunk fetching's priority/timing is completely
unchanged (existing states/branches are untouched, only new states and one
new terminal `else if` branch were added), and art loading simply happens
in the idle gaps, which are frequent given RING_SLOTS' comfortable margin.
No new arbitration logic needed anywhere - there is still exactly one
requester, exactly as before.
NEW FILE core/track_thumb_ram.sv: replaces thumb_ram.sv entirely. Purely
passive storage now (no target_dataslot_read/loader FSM of its own) - two
buffers (172x172 sharp image, 50x45 background), each with the same
write-capture + registered-read pattern as the old thumb_ram.sv/
ImageViewer's framebuffer_ram.sv. audio_streamer.sv's new states write into
it via the ordinary shared bridge_wr/bridge_addr broadcast (same mechanism
psram_audio_buffer/playlist_ram already use) - track_thumb_ram never needs
to know who requested the transfer.
audio_streamer.sv new states/params: IMG_WAIT_CLEAR/IMG_WAIT_DONE/
BG_WAIT_CLEAR/BG_WAIT_DONE (state_t stayed within its existing 3-bit width -
8 states total fits exactly). New IMG_SLOT_ID(19)/IMG_BASE_ADDR(0x2300_0000)/
BG_BASE_ADDR(0x2301_0000)/IMG_BYTES(59168)/BG_BYTES(4500) parameters.
img_slotoffset = track_sel_r * (IMG_BYTES+BG_BYTES) - a track's two images
sit back-to-back at a fixed, computable offset, no lookup table needed on
the hardware side (all per convert_audio.py always populating every one of
the 32 slots, real or padding, with a real image). All new states replicate
the existing WAIT_CLEAR/WAIT_DONE states' do_consume/chunks_in_flight
bookkeeping - playback keeps draining the ring via the I2S/PSRAM read side
regardless of what this producer FSM is fetching, so that accounting must
stay correct through the new states too, not just the audio ones.
core_top.v: dataslot mux simplified from 3-way back to 2-way (playlist_ram,
audio_streamer - track_thumb_ram has no dataslot ports at all); new
bg_rd_addr/bg_pixel/bg_rgb888 (50x45 -> 400x360 nearest-neighbor upscale,
a plain >>3 shift since 400/50=360/45=8 exactly, cheaper than the Library
icon's non-power-of-2 multiply/divide); bg_rgb888 now drawn first (before
the disc/thumbnail layers) in both the Spinning Vinyl and Still Thumbnail
branches, replacing the flat 0x0D0D1A fill there (including the vinyl
disc's spindle hole, which now shows the background "through" the disc's
center instead of flat navy).
LIBRARY PER-ROW ICON CAVEAT: track_thumb_ram only ever holds ONE track's
art (whichever is currently loaded/playing), but the Library list shows up
to 8 DIFFERENT tracks per screen - there is no way to show every row's own
unique art without either 8x the image buffers or a genuinely different
architecture. Rather than show stale/wrong art on 7 of 8 rows (or revert
the per-row icon feature entirely), the icon is now only drawn on the ONE
row that matches the currently-loaded track (row_is_loaded); other rows
are text-only, same as before Section 32 added icons at all. This is an
honest simplification, not a hidden regression - flagging in case a real
per-row art cache is wanted later (comparable in scope to its own session,
similar to the deferred Album tab).
tools/convert_audio.py: extract_cover_art() pulls embedded cover art via
`ffmpeg -an -i <file> -vcodec copy` (works for ID3 APIC/FLAC picture blocks
without re-encoding); make_track_thumb_bytes()/make_track_bg_bytes() square-
crop+resize to 172x172, and separately downscale+Gaussian-blur+dim to
50x45, falling back to tools/make_default_thumb.py's make_image() (now
imported as a library function, not just a standalone script) when a track
has no usable embedded art. Every one of the 32 slots (real tracks AND
padding beyond the real track count) gets a real image either way - same
"PC does the complex work, hardware just reads" pattern as playlist.bin.
New file track_thumbs.bin, new data.json slot 19 "Track Thumbs"
(deferload:true, same reasoning as Test Audio - the on-demand per-offset
access pattern gets no benefit from a boot-time full-file copy). Slot 18
"Default Thumb" and its file (default_thumb.bin) are retired along with
thumb_ram.sv.
TESTED THIS SESSION (PC-side only): re-ran the full 26-track/5-album
conversion - all 26/26 tracks had embedded art successfully extracted
(verified by decoding track_thumbs.bin's RGB565 bytes back to PNG and
visually inspecting several: real album covers came through correctly, no
color-channel/byte-order corruption; the default-fallback slot showed the
corrected triangular note-flag; background images were visibly blurred and
proportionately dimmed versus their sharp counterparts). track_thumbs.bin
came out to exactly 2,037,376 bytes (32 * (59168+4500)), matching
data.json's size_exact with no manual hex arithmetic mismatch.
NOT YET HARDWARE-VERIFIED - this is the single largest and most novel
change in this batch (a new dataslot-arbitration approach, not just a
worked example of an existing pattern). Specifically needs checking on
hardware: (1) audio must not glitch/stutter when a track change triggers
image fetching - the priority design should make this a non-issue, but it
is genuinely new territory for this project; (2) images must correctly
update on every track-change path (D-pad next/prev, Library A-select,
interact.json Track menu, auto-advance) - only track_sel drives
img_pending, so all four should behave identically, but only one has ever
been exercised (none, yet) for image loading specifically; (3) visual check
that Library's single-icon-only-on-the-loaded-row behavior reads sensibly
rather than confusingly.

--- Library tab: progress bar removed (2026-08-05) ---
Direct fix for the "library loading slowly" saga, now that its actual cause
is understood (see the RESOLVED note earlier in this section): `in_bar_area`
and its separator line above it are no longer drawn when `cur_tab_vid ==
2'd2` (Library) - both are now `cur_tab_vid == 2'd0` (NowPlaying) only.
Library is now track-list-only, full stop. Pinning this down took several
rounds of clarifying questions in conversation (initial hypothesis was a
Pocket-OS-level asset-verification cost, which was wrong; then a suspected
progress-bar/chunks_played bug from pause not gating something correctly,
which was ALSO wrong on inspection - audio_addr/slot_consumed_pulse are
correctly gated behind `!paused_s`, already confirmed by re-reading that
logic - the bar's own behavior was correct the whole time) before the user
directly identified it as the ordinary progress bar being misread as a
loading indicator. Worth remembering for next time a "something feels
broken/slow" report doesn't match what the RTL says should be happening:
ask what's literally on screen before assuming the mechanism under
suspicion is actually the right one.

FILES CHANGED: core_top.v (OSC_Y_TOP/OSC_Y_BOTBRD/OSC_Y_BOT/TITLE_Y_START/
ARTIST_Y_START/BIGICON_Y_4X relayout, DISC_CY derived from THUMB_Y_START,
small-icon path retired, 16x16 icon bitmaps + unified in_big_icon gating,
last_track_idx full-width subtract, 2-way dataslot mux, bg_rd_addr/bg_pixel/
bg_rgb888 + render integration, row_is_loaded gating on the Library icon,
track_thumb_ram/audio_streamer instantiations updated, in_bar_area + its
separator line restricted to NowPlaying only), audio_streamer.sv
(IMG_WAIT_CLEAR/IMG_WAIT_DONE/BG_WAIT_CLEAR/BG_WAIT_DONE states, img_pending,
new IMG_*/BG_* parameters), core/track_thumb_ram.sv (new, replaces
thumb_ram.sv which is deleted), ap_core.qsf (thumb_ram.sv -> track_thumb_ram.sv),
tools/convert_audio.py (art extraction/packing, generic update_data_json,
track_thumbs.bin output), tools/make_default_thumb.py (triangular flag fix,
docstring updated for its new role as an imported fallback-art source),
data.json (dev+dist: slot 18 "Default Thumb" -> slot 19 "Track Thumbs",
deferload:true), dist/Assets (regenerated test_audio.bin/playlist.bin/
track_thumbs.bin for the same 26-track/5-album library, default_thumb.bin
removed).

VERIFICATION: `iverilog -g2012 -Wall -tnull core/core_top.v
core/audio_streamer.sv core/playlist_ram.sv core/track_thumb_ram.sv
core/psram_audio_buffer.sv core/psram.sv core/font_rom.v
core/core_bridge_cmd.v core/mf_pllbase.v apf/common.v` elaborates with
exactly the same 2 pre-existing missing-megafunction-IP errors this project
has always had (mf_datatable/mf_pllbase_0002) - zero new errors or
warnings from any changed or new file. Re-verified after the Library
progress-bar removal (2026-08-05) - still clean.

STATUS: SOURCE DONE (2026-08-05), self-reviewed + iverilog-checked + PC-side
art-extraction tested (not compiled - Claude cannot run Quartus). Needs a
full recompile + SD deploy before hardware testing. See NEXT_STEPS.txt.

================================================================================
36. SECTION 36 - SECTION 35 HARDWARE-TESTED: LIBRARY-BLANK ROOT CAUSE FOUND,
    WRAPAROUND BUG FIXED, OSCILLOSCOPE REMOVED, REPEAT/SHUFFLE ADDED,
    THUMBNAIL-DELAY FIX, ICON REDESIGN (source done 2026-08-06)
================================================================================
CONTEXT: user compiled and hardware-tested all of Section 35 for the first
time and reported a large new batch of feedback (prompts/prompt_003.txt):
(1) play/pause icon shifts position between play and pause; (2) album
thumbnail takes ~10s to update after a track change; (3) progress line
should be white (like the icon), staying yellow only when paused; (4)
Spinning Vinyl reflection too thick, wants it ~half the angle; (5) Library
tab totally blank - only the "LIBRARY" header shows, no track list at all;
(6) Oscilloscope effect isn't a good look, wants it deleted from the app
(history kept in these notes); (7) FPGA temperature rising fast, suspects
the oscilloscope; (8) after the last track wraps to the first, title/
thumbnail show blank and "next" repeats without progressing, with a very
precise numbered repro (1,2,3,4,5,1,1,1,1... forward, then
...,1,1,1,1,1,1,5,4,3,2... backward) - a toggle for "repeat all / stop
after all tracks played" and a shuffle on/off toggle were requested,
shown as an icon/flag on the Now Playing tab; (9) default thumbnail needs
redesigning to match a user-supplied reference icon
(plans/Music_Player_Icon.png), colored white note on grey background;
(10) positive feedback that changing tracks via the interact.json core
setting works well; (11) asked whether there's a maximum track count.

--- Root cause #1: Library tab totally blank (item 5) ---
playlist_ram.sv's `track_count` register (added in Section 33's memory
redesign) was accidentally async-reset-gated:
    always_ff @(posedge clk or posedge reset) begin
        if (reset) track_count <= 6'd0;
        else if (...) track_count <= track_count + 6'd1;
    end
This is exactly the pitfall CLAUDE.md's "APF static boot load behavior" rule
already documents: the Playlist slot's real bridge_wr writes all land BEFORE
Reset Exit, i.e. while `reset` is still asserted (confirmed in every debug
log: "Slot: load done" always precedes "Reset Exit"). Because `reset` is in
the async sensitivity list, the `if (reset)` branch re-fires on every
clk_74a edge for as long as reset stays high, re-forcing track_count to 0
THROUGHOUT the entire boot-time load - so every real increment during that
window was immediately wiped out. By the time reset deasserts, the one-shot
load has already finished and never repeats (no re-DMA per the same
CLAUDE.md rule), so track_count was stuck at 0 forever, on every boot, since
whenever this register was introduced. `row_has_track = list_track_idx <
track_count` is then false for every row -> a totally blank list, with the
"LIBRARY " header still showing fine since that's just a static string
unrelated to track_count. FIX: removed the reset gating entirely (matches
this same file's pram[]/stage_reg, which were already correctly NOT
reset-gated for the identical reason) - track_count now just relies on the
FPGA's normal power-on-cleared register state, same assumption already
relied on elsewhere in this file.

This also fully explains item 8 (wraparound bug), which had resisted two
separate investigation rounds (Section 35 and earlier): with track_count
stuck at 0, `last_track_idx = pram_track_count - 1` computed as 6'd0 - 6'd1
= 63, truncated to 5 bits = 31 - NOT the real last track index (e.g. 25 for
the 26-track test library). So the wraparound math
(`next_track_sel = (track_sel==last_track_idx) ? 0 : track_sel+1`) never
actually triggered at the REAL last track - instead, leaving the real last
track advanced track_sel into indices 26..31, which were never populated by
convert_audio.py (only 26 real tracks were loaded) and read back as all-zero
records: blank title (a screen-full of NUL bytes, not spaces, so the title-
length scan and ticker both treat it as "long non-blank text" - explains the
blank title with no visible characters), track_chunks=0 (which auto_advance
explicitly guards against, so playback effectively stalls, matching "next
just replays" - it's not literally replaying, it's stuck advancing through
several visually-identical BLANK phantom slots 26..31 that all look the same
to the user), and a default/garbage thumbnail (the per-track art fetch reads
whatever offset track_sel*PER_TRACK_IMG_BYTES lands on in track_thumbs.bin,
which is only sized for 26 real tracks). This also explains the reported
"previous" sequence: several presses walking back DOWN through those same
indistinguishable blank slots 31..26 (all read as "stuck") before finally
reaching a real track (25) and correctly continuing 25,24,23,22... Fixing
track_count fixes last_track_idx, which eliminates the phantom-slot range
entirely - both directions should now wrap immediately and correctly at the
real last/first track. NOT yet hardware-confirmed - this was static-analysis
reasoning from re-reading playlist_ram.sv + core_top.v's track-select chain
line by line, not a live trace, so please re-test the exact repro from
NEXT_STEPS.txt/prompt_003.txt after the next compile.

While in this code, also found and fixed a related latent bug noticed during
the same investigation: `cur_track_chunks`/`chunks_played` in core_top.v were
only 7 bits (`pram_chunks[6:0]`), silently truncating any track's real chunk
count (a full 16-bit playlist_ram field) at 127 chunks (~5.5 minutes at
CHUNK_BYTES=512KB). convert_audio.py doesn't cap chunk_count, so any track
over ~5:47 would have hit this. Widened both to 16 bits (and the progress-bar
math's intermediate widths to 32 bits to avoid overflow at the new range) -
not confirmed as an ACTIVE bug in the current 26-track library (would need a
track that long), but a real one, so fixed while already in this exact logic.

--- Repeat-all/stop-at-end + shuffle (item 8's feature request) ---
plans/UI_SPEC.md already specified this (X=shuffle on/off, Y=cycle repeat
mode, 2 indicator dots below the effect) from before Section 30 - never
implemented until now. Implemented a reduced version matching exactly what
was asked: Y toggles repeat_all (default ON, matching the prior always-loop
behavior so existing playback is unaffected unless the user opts in) between
"repeat all" and "stop after all tracks played" (2 states, not the spec's
3-state all/single/off - "repeat single" is not implemented, deferred). X
toggles shuffle_on (default OFF). Two 8x8 indicator dots (bright white = on,
dim gray = off) added in the 26px gap between the big play/pause icon and
the title, shown in both remaining effects (not just Still Thumbnail per the
original spec) to match Section 35's "same UI in every effect" pattern.
Implementation: a free-running 16-bit Galois LFSR (taps 16/14/13/11,
advances every clk_74a cycle regardless of anything else) reduced via
modulo pram_track_count for a shuffle pick; `next_track_eff` resolves to
that pick when shuffle is on, else the ordinary sequential/wraparound track
(D-pad Left/previous is deliberately NOT shuffle-aware - always sequential
backward, since a shuffled "previous" would need a history stack). "Stop
after all tracks played" only gates the natural auto-advance-at-the-real-
last-track case (shuffle keeps looping continuously regardless of
repeat_all - combining shuffle with stop-at-end isn't implemented, a
documented simplification, not an oversight). Care was taken NOT to give
`paused` two drivers: the stop-at-end pulse (`auto_advance &&
auto_advance_would_stop`) is handled inside the SAME always block that
already owns `paused` (the A-button handler), not the track_sel block.

--- Oscilloscope removed entirely (items 6, 7) ---
Deleted per user request: the EFFECT_OSCILLOSCOPE mode, its zero-crossing
capture FSM (osc_trig_state/scope_fill/scope_buf_sel), its two 512-entry
ping-pong scope_ram buffers, and its render branch are all gone from
core_top.v - not just hidden behind a flag. effect_mode is now a single bit
(Still Thumbnail / Spinning Vinyl only, toggled by either D-pad Up or Down
since there's no third state to cycle through). The removed source is
preserved here in these notes (see Section 28 above) and in git history, not
carried forward in the app itself, per the user's explicit request.
This is also the most likely explanation for item 7 (temperature): the
oscilloscope was BOTH the default boot-time effect AND the only one of the
three effects with genuinely continuous high-frequency switching activity -
its capture FSM ran a ~48kHz-driven state machine plus per-pixel waveform
math on every frame, indefinitely, the moment the core booted, unless the
user manually switched away. Still Thumbnail/Spinning Vinyl are comparatively
static (Spinning Vinyl's rotation update is a few-Hz counter, not a
continuous per-sample capture loop). Claude cannot measure real FPGA power/
temperature, so this can't be proven directly - but it's the clearest,
most plausible source of sustained extra switching activity unique to this
project's recent history, and removing it (which the user wanted anyway for
looks) directly removes that source. Please confirm on hardware whether the
temperature rise is actually gone now that it's default-mode-inactive by
construction (the code no longer exists at all, so this isn't a "did the
user remember to switch away" question anymore).

--- Thumbnail ~10s load delay (item 2) ---
audio_streamer.sv's per-track art fetch (Section 35) was gated behind
`chunks_in_flight >= RING_SLOTS` (the ring COMPLETELY full, all 16 chunks) -
far more conservative than necessary. Every track change resets the ring to
empty, and the REQ state greedily re-fills it via the SD-card dataslot-read
path before ever considering art - at roughly 2.73s of playback content per
chunk and (per the reported ~10s delay) an SD-read time per chunk on that
same rough order, filling all 16 chunks from scratch plausibly costs close
to that ~10s directly. FIX: lowered the threshold to `chunks_in_flight >=
INITIAL_FILL_CHUNKS` (2) - the SAME margin that already gates
`initial_fill_done` (i.e. the same moment audio itself becomes safe to
start playing). Diverting one bus turn for the ~63KB image+background fetch
at that point costs only a small, one-time delay to reaching a fully-topped-
up 16-chunk ring afterward; audio chunk-fetch priority is otherwise
completely unchanged (still strictly first below that margin, so this can't
delay the CRITICAL first chunks that gate playback start). Album art should
now appear at roughly the same time playback becomes audible, not ~10s
later. Not hardware-confirmed yet.

--- Play/pause icon centering (item 1) ---
play_bmp_row()'s right-pointing triangle was anchored with its flat edge at
column 0, so its bounding box (columns 0..7 at max width) only filled the
LEFT HALF of the 16-wide icon bitmap - clearly off-center from PAUSE_BMP's
bars (columns 2..13, centered on column 7.5). Fixed with a trailing `>>4`
shift so the triangle's bounding box becomes columns 4..11 at max width,
centered on column 7.5 to match PAUSE_BMP exactly - eliminates the visible
jump when toggling play/pause.

--- Progress bar color (item 3) ---
Playing-state fill color changed from sky blue (0x00B4D8) to white
(0xFFFFFF), matching the play/pause icon as requested. Paused stays amber/
yellow (0xFFBF00, unchanged).

--- Spinning Vinyl reflection thinner (item 4) ---
Halved the reflection wedge's half-angle by changing both wedges'
`refl_along >>> 1` (~26 degrees) to `refl_along >>> 2` (~14 degrees, almost
exactly half) in the refl_wedge/refl_wedge2 conditions.

--- Default thumbnail redesign (item 9) ---
tools/make_default_thumb.py's glyph replaced: was a single eighth-note
(notehead+stem+flag), now a paired-eighth-note "beamed notes" glyph (two
noteheads at different heights connected by stems to a shared beam),
matching the composition of the user-supplied plans/Music_Player_Icon.png,
but recolored to their explicit spec (white note, grey gradient background:
0x6B707A top to 0x4A4E57 bottom) rather than the reference's own orange-on-
pale-blue colors. core_top.v's COLOR_LABEL (Spinning Vinyl disc label
placeholder, meant to match the default thumbnail's accent per its own
comment) updated from the old pink 0xFA3C64 to the new grey 0x4A4E57 to
match. Regenerated track_thumbs.bin/test_audio.bin/playlist.bin via the same
convert_audio.py --dirs invocation as before (source_musics unchanged) to
confirm the pipeline still runs cleanly end-to-end - output confirms all
26/26 tracks still have embedded art, so the new default glyph currently has
ZERO visible effect on this test library (it's simply never selected); it
will only become visible once/if a track without embedded cover art is
added. Visually spot-checked by rendering make_image() to a PNG and viewing
it directly - reads clearly as two connected notes, not a rectangle.

--- Max tracks question (item 11) ---
Hard cap is 32 tracks, baked into two places: playlist_ram.sv's
MAX_TRACKS=32 parameter (5-bit track_idx/track_sel/list_cursor throughout
core_top.v) and playlist.bin's fixed 32*128=4096-byte format (matches
data.json's "Enforcing exact size check of 4096 bytes" in every debug log).
Adding/changing/reordering tracks WITHIN that cap needs no FPGA recompile -
just re-run convert_audio.py. Going past 32 needs a source change (widen the
track-index fields, e.g. to 6 bits for up to 64) plus a full Quartus
recompile; nothing in this session touched that cap. In practice, SD card/
PSRAM storage for the concatenated audio file would likely become the
limiting factor well before 32 tracks in most real libraries anyway.

FILES CHANGED: open-fpga-core-template-da3a021/src/fpga/core/playlist_ram.sv
(track_count reset-gating fix), core/core_top.v (last_track_idx now correct
as a side effect; cur_track_chunks/chunks_played widened to 16 bits;
play_bmp_row centering; progress bar color; vinyl reflection angle;
Oscilloscope fully removed - effect_mode now 1 bit; repeat_all/shuffle_on/
lfsr + indicator dots added; COLOR_LABEL updated), core/audio_streamer.sv
(image-fetch priority threshold lowered), tools/make_default_thumb.py (new
glyph + grey colors), dist/ + open-fpga-core-template-da3a021's
data.json/interact.json/test_audio.bin/playlist.bin/track_thumbs.bin
(regenerated via convert_audio.py, same source library - confirms the PC
pipeline still works unchanged).

VERIFICATION: `iverilog -g2012 -Wall -tnull core/core_top.v
core/audio_streamer.sv core/playlist_ram.sv core/track_thumb_ram.sv
core/psram_audio_buffer.sv core/psram.sv core/font_rom.v
core/core_bridge_cmd.v core/mf_pllbase.v apf/common.v` - same 2 pre-existing
missing-IP errors as always (mf_datatable/mf_pllbase_0002), zero new errors,
re-checked after every batch of edits in this section.

STATUS: SOURCE DONE (2026-08-06), self-reviewed + iverilog-checked + PC-side
icon/asset regeneration tested. NOT yet compiled/hardware-tested (Claude
cannot run Quartus). This is a big batch - please recompile and retest all
of NEXT_STEPS.txt's checklist, especially the Library list (should now show
tracks) and the wraparound repro (should now wrap correctly at the real
first/last track instead of drifting into blank phantom slots).

================================================================================
37. SECTION 37 - SECTION 36 HARDWARE-TESTED: SHUFFLE TITLE/ART CORRUPTION
    (TIMING CLOSURE), LIBRARY THUMBNAIL POSITION BUG (MISSING CDC SYNC),
    BLUR/LAYOUT TWEAKS (source done 2026-08-06)
================================================================================
CONTEXT: user hardware-tested Section 36 and confirmed the big fixes worked:
Library list now shows tracks, wraparound works as expected, album art loads
fast now, and the vinyl center color change was noticed and liked. New
feedback (prompts/prompt_004.txt): (1)-(4) shuffle mode sometimes shows
blank/wrong/left-shifted title+artist, self-corrects after turning shuffle
off, and the marquee ticker sometimes engages (with a multi-second blank
gap) specifically on shuffled tracks; (5) ticker correctly doesn't engage
for normal playback (title short enough) - not a bug, just confirmed
expected behavior; (6)-(7) Library thumbnails only show for the currently-
loaded track's row (known/documented limitation) AND sometimes bleed as a
half-visible thumbnail at the top/bottom of the list, specifically when the
loaded track is near the middle of the visible page (positions 4-5),
clearing once scrolled away from the middle; (8) wraparound confirmed
working; (9) album art load speed confirmed fast enough now; (10) noticed
the vinyl center color changed, likes it; (11) temperature still rises
25->45C over 5-10 minutes even with the Oscilloscope removed, but "I think
it's fine"; (12) requested a blurrier Now Playing background; (13)
requested the repeat/shuffle indicator dots be repositioned to flank the
play/pause icon at ~1/6 and 5/6 of the screen width; (14) shuffle mode
sometimes skips to the next track before the current one finishes playing.

--- Root cause: shuffle title/artist corruption + early track skip (items 1-4, 14) ---
`shuffle_pick` (Section 36) was a bare combinational wire: `lfsr %
pram_track_count`, a VARIABLE-divisor modulo - a meaningfully deep
combinational divider, unlike next_track_seq's simple compare-and-add-1.
Because `lfsr` advances on EVERY clk_74a cycle (by design, so shuffle looks
random), that divider had to fully settle within a single ~13.4ns clk_74a
period on EVERY cycle - a real timing-closure risk. iverilog's zero-delay
simulation cannot model gate delay at all, so this passed "iverilog-clean"
every time despite being a live hardware bug - a good reminder that
iverilog verification here only proves RTL logical correctness, not timing
closure, and a newly-added variable-width divide/modulo op is exactly the
kind of change that needs to be treated with suspicion even after a clean
sim run. Worse, `next_track_eff` (built from `shuffle_pick`) fans out to TWO
separate destination registers in two different modules at the same clock
edge: `track_sel` here in core_top.v, and playlist_ram's registered
`track_row` read (via `pram_read_idx_next`). If the shared combinational
path was marginal, the two destinations could each latch a DIFFERENT
resolved value depending on their individual routing delay from the
divider - meaning track_sel could end up pointing at one track while
title_ram/artist_ram (and cur_track_chunks, used by auto_advance's
end-of-track detection) got fetched for a DIFFERENT track. This single
mechanism explains all of: blank/wrong/shifted title+artist (mismatched
fetch), the ticker briefly engaging with a blank gap (a corrupted title can
look artificially "long", spuriously enabling ticker mode until the next
real update overwrites it), and "skipped to next track early" (a MISMATCHED
cur_track_chunks reflecting the wrong track could satisfy auto_advance's
"last chunk" check far too soon). And it's consistent with "goes back to
correct after turning shuffle off" - next_track_seq's simple arithmetic on
stable registers doesn't have anything like this deep, constantly-changing
combinational path. FIX: `shuffle_pick` is now a REGISTERED value
(`always @(posedge clk_74a)`, computed once per cycle alongside lfsr's own
update, in the same always block), not a bare wire off the raw lfsr - this
gives the divider a full clock period to settle at one single point (its
own register) before ANYTHING reads it, so both destinations sample the
SAME already-stable value. The extra cycle of "staleness" on the random
pick itself is irrelevant for a shuffle feature. NOT yet hardware-confirmed
- please retest shuffle mode specifically for title/artist correctness and
listen for early skips across several track changes.

--- Root cause (hypothesis): Library thumbnail at top/bottom of page (item 7) ---
`list_scroll`/`list_cursor` (both clk_74a-domain registers, changing on every
scroll button press) were used COMPLETELY RAW/unsynchronized in the
clk_core_12288-domain video renderer (`list_track_idx = list_scroll +
list_row`, `row_selected = (list_track_idx == list_cursor)`) - the ONLY two
cross-domain signals in this entire file with NO synchronizer at all; every
other one (track_sel_vid, cur_tab_vid, effect_mode_vid, paused_vid_s,
repeat_all_vid, shuffle_on_vid) gets at least a 2/3-flip-flop sync first.
An unsynchronized multi-bit register read can transiently glitch to a wrong
value for a cycle or two right at the moment it changes (a genuine
metastability/CDC hazard, not just a style nit) - if that transient value
momentarily made `list_track_idx` equal `track_sel_vid` for the WRONG row
(e.g. row 0 or 7 - "top/bottom of the page"), the per-row icon (a solid,
easily-noticeable 30x30 block) would flash at that wrong position for a
frame or two. This is consistent with list_scroll changing far more often
than track_sel (every scroll button press vs. occasional track changes),
and with the report correlating to the loaded track's on-screen row
position (which only matters when it's actually visible, i.e. list_scroll
puts it somewhere in the current 8-row page). FIX: added proper
`synch_3`-based synchronizers for list_scroll/list_cursor into the video
domain (`list_scroll_vid`/`list_cursor_vid`), matching this file's existing
convention, and switched list_track_idx/row_selected to use them. Framed as
a hypothesis, not a certainty: `synch_3` (like the rest of this file's
synchronizers) is N independent per-bit 3-FF chains - it removes
metastability-propagation risk but doesn't fully solve "torn multi-bit
value" in a formal sense (same residual risk this file already accepts for
track_sel_vid/cur_tab_vid). Still a strict improvement over zero
synchronization, and directly explains the reported symptom, so worth
retesting specifically: browse the Library with a track playing at various
scroll positions (including exactly the "playing track at position 4/5"
repro) and confirm the icon stays only on its own row.

Separately, item 6 (icon only shows on the currently-loaded row, not all 8
visible rows) is the ALREADY-DOCUMENTED Section 35 simplification (see that
section) - not new, and the user is now flagging it as worth revisiting
("we might need to figure out a way around this"). Noted as a roadmap item
below with a concrete design direction, not implemented this round (kept
this batch scoped to the reported bugs).

--- Now Playing background blur increased (item 12) ---
tools/convert_audio.py's make_track_bg_bytes(): GaussianBlur radius 2 -> 4.
Regenerated track_thumbs.bin (same source library) to pick up the change.

--- Indicator dots repositioned (item 13) ---
Moved from below the play/pause icon (in the icon-to-title gap) to flank it
horizontally: x-centered at 1/6 and 5/6 of the 400px screen width (~67/333),
vertically centered on the icon itself (y=236, was y=265).

--- Not changed this round ---
- Temperature (item 11): still elevated after removing the Oscilloscope.
  User said "I think it's fine" - no further action taken, but noting for
  the record that the Oscilloscope removal alone did not fully explain the
  rise. No further culprit identified; sustained PSRAM streaming (~20-24MB/s)
  and general FPGA switching activity under continuous audio playback are
  plausible baseline contributors, but this is speculation, not a finding -
  Claude has no way to measure real FPGA power/temperature.
- Vinyl center color (item 10): confirmed intentional - this is Section 36's
  COLOR_LABEL change (pink 0xFA3C64 -> grey 0x4A4E57) to match the redesigned
  default thumbnail's grey background.
- Ticker for normal (non-shuffled) playback not engaging (item 5): confirmed
  expected - title_len_eff <=25 chars for this library's normal playback path,
  so active_ticker correctly stays off. Not a bug.

FILES CHANGED: core/core_top.v (shuffle_pick registered; list_scroll_vid/
list_cursor_vid synchronizers added and wired in; indicator dot position),
tools/convert_audio.py (background blur radius), dist/Assets/musicplayer/
common/track_thumbs.bin (regenerated with the new blur, same source library).

VERIFICATION: same iverilog command as Section 36 - identical 2 pre-existing
missing-IP errors, zero new ones, re-checked after every edit.

STATUS: SOURCE DONE (2026-08-06), self-reviewed + iverilog-checked + PC-side
asset regeneration tested. NOT yet compiled/hardware-tested. The shuffle fix
in particular addresses a genuine TIMING issue (not just RTL logic), so it's
worth watching closely on the next hardware test - if title/artist
corruption persists, the divider may need pipelining across more than one
extra cycle, or track_count's range may need padding/registering further.

**Roadmap addition**: a real per-row art cache for the Library tab (item 6) -
concrete direction if picked up later: rather than caching all 8 visible
rows' FULL 172x172 sharp images (far too much BRAM, ~473KB for 8 rows), add
a THIRD, separate small icon-sized (e.g. 30x30) image per track in
track_thumbs.bin, and fetch up to 8 of those (only ~1.8KB each) whenever the
Library tab is active and list_scroll changes - small enough to plausibly
buffer all 8 visible rows at once, unlike the full sharp image.

================================================================================
38. SECTION 38 - SECTION 37 HARDWARE-TESTED: REAL ROOT CAUSE OF THE LIBRARY
    THUMBNAIL BUG FOUND (Section 37's CDC-sync fix was wrong), BACKGROUND
    RESOLUTION DOUBLED, UI POLISH (source done 2026-08-06)
================================================================================
CONTEXT: user hardware-tested Section 37 and reported (prompts/prompt_005.txt):
(1) Now Playing background still shows visible "color blocks", not smooth;
(2) indicator dots are great, but should only show in Spinning Vinyl (keep
Still Thumbnail clean); (3) the Library thumbnail bug is STILL HAPPENING
after Section 37's fix, captured via phone photos in debug/ - crucially,
the photos show the icon bleeding into the TAB HEADER text area (top) and
into the dead space below the list (bottom), not just "the wrong row"; (4)
asked why MAX_TRACKS is capped at 32 and whether it can be raised; (5) asked
whether the Library could show ALL rows' thumbnails, not just the currently-
loaded one; (6) Library icon-to-title gap looks too dense; (7) the paused
progress bar can also be white now, since the play/pause icon itself already
shows play/pause state.

--- Library thumbnail bug: ACTUAL root cause found (item 3) ---
Section 37's hypothesis (missing list_scroll/list_cursor synchronizers) was
WRONG, or at least insufficient - the bug persisted after that fix. The
user's phone photos (debug/IMG_696{0,1,2,4,5}.HEIC, converted to PNG/JPG for
inspection this session) were the key: they show the per-row icon bleeding
into the TAB HEADER text row (y=8..23, e.g. overlapping "LIBRARY") and into
the empty margin below the last list row (y>316) - both COMPLETELY OUTSIDE
the list's own y=28..316 range. That ruled out a rare metastability flash
(which Section 37 was solving for) in favor of a deterministic addressing
bug, since the photos show it reliably, tied to specific (scroll, loaded-
track) combinations, not randomly.

Root cause: `in_list_icon` computed `list_y_local` (via `list_y_off =
visible_y - LIST_Y_START`) WITHOUT ever checking that `visible_y` was
actually within the list's range first - unlike every other list condition
(list_pixel_lit, list_highlight_on), which are built from `in_list_row_band`
and DO check `visible_y >= LIST_Y_START && visible_y < LIST_Y_START +
8*ROW_H` before doing anything else. When visible_y < LIST_Y_START (the
header area), the subtraction UNDERFLOWS in unsigned arithmetic to a huge
wrapped value; list_row_full's division-by-36 then reduces that huge value
back down to some IN-RANGE-LOOKING (0-7) row number by sheer modular
coincidence - so list_track_idx (= list_scroll + that bogus row) could
spuriously equal track_sel_vid (the loaded track) for specific scroll
positions, making row_is_loaded true and painting the icon somewhere that
was never really "row N" at all, just a pixel whose wrapped arithmetic
happened to alias to row N. This explains why the bug tracked (scroll
position, loaded track position) so precisely - it's fully deterministic,
not a timing glitch. FIX: `in_list_icon` now ANDs with `in_list_row_band`
(the same correctly-bounded condition list_pixel_lit/list_highlight_on
already use) instead of re-deriving its own unbounded check. The Section 37
list_scroll_vid/list_cursor_vid synchronizers are KEPT (still a real,
independent CDC gap worth having closed, per every other cross-domain
signal in this file), just weren't the actual fix for this specific bug.
Lesson for next time: when a reported bug's exact geometry is available (the
phone photos showing WHERE on screen, not just "sometimes wrong"), use it
directly to narrow the hypothesis space before reaching for the nearest
plausible-sounding mechanism (CDC/metastability) - the two rounds here
would have converged faster starting from "where exactly does it appear"
instead of "what's different about this code path". NOT yet hardware-
confirmed - please retest specifically watching the header and below-list
margins, not just row positions.

--- Now Playing background still blocky (item 1) ---
Section 36/37 only tuned blur radius (2->4); the dominant problem was
actually the UPSCALE, not the blur: the background is a small PC-generated
image, nearest-neighbor-upscaled by the FPGA to fill the screen (zero
interpolation - hardware only ever does a plain blit, per this project's
"let the PC do the work" philosophy). At 50x45 source resolution with an 8x
upscale, each source pixel became a highly visible 8x8 hard-edged block;
blur only softens the color TRANSITION between blocks, not the hard block
boundary itself. FIX: doubled the background resolution to 100x90 (4x
upscale instead of 8x, still power-of-2/shift-friendly - no multiply/divide
added), plus a matching blur radius bump (4->6) since the same absolute
blur radius covers proportionally less of a now-larger image. Deliberately
NOT a full-resolution background (would need ~9MB total across 32 tracks
and a much bigger BRAM buffer) given this device's known-tight BRAM budget
from Section 33/34's Fitter saga - this is a real trade-off, worth watching
the next Fitter report specifically for this buffer's impact (bg_mem in
track_thumb_ram.sv: 4500 bytes/track -> 18000 bytes/track).

--- Indicator dots restricted to Spinning Vinyl (item 2) ---
`in_repeat_ind`/`in_shuffle_ind` now also require `effect_mode_vid ==
EFFECT_SPINNING_VINYL`, so Still Thumbnail stays clean/simple as requested.

--- Library icon-to-title gap widened (item 6) ---
LIST_X_START's gap past the icon widened from 7px to 16px.

--- Paused progress bar now white too (item 7) ---
Removed the paused-vs-playing color distinction entirely - the bar is now
always white when filled (previously amber/yellow while paused). The
play/pause icon already communicates that state, per the user's own
reasoning.

--- Answered, no code change (items 4, 5) ---
- **Why MAX_TRACKS=32, and what raising it involves**: the cap comes from
  two places working together: (a) every track-index field in the design
  (track_sel, list_cursor, list_scroll, last_track_idx, shuffle_pick, the
  playlist_ram track_idx/lib_idx ports) is a 5-bit value (2^5=32), and (b)
  playlist.bin's own file format is a fixed MAX_TRACKS*128-byte table
  (matches data.json's "Enforcing exact size check of 4096 bytes" seen in
  every debug log - 32*128=4096). Raising it means widening every one of
  those 5-bit fields to 6 bits (up to 64) throughout core_top.v AND
  playlist_ram.sv's MAX_TRACKS parameter (which already derives its
  internal address widths generically via $clog2(MAX_TRACKS), so THAT file
  needs no logic changes, just the parameter value) AND regenerating
  playlist.bin/interact.json's Track menu to match, plus a full Quartus
  recompile. This is mechanical but touches the exact track-selection logic
  that took 3 rounds (Sections 36-38) to get right - deliberately NOT
  attempted this round without hardware confirmation that the current fixes
  are solid first, and without a concrete target track count from the user.
  Worth a dedicated round once requested with a specific number in mind.
- **Can the Library show all rows' thumbnails, not just the current one**:
  yes, plausible, NOT attempted this round (scope). See the roadmap item
  already added in Section 37 above for the concrete direction (a separate,
  much smaller ~30x30 per-track icon image, up to 8 fetched at once for the
  visible page) - a real feature, not a small tweak, needs its own session.

FILES CHANGED: core/core_top.v (in_list_icon y-bound fix; bg resolution
100x90 + address width; indicator dots vinyl-only; Library gap; progress
bar always white), tools/convert_audio.py (BG_W/BG_H 100x90, blur radius 6),
dist/Assets/musicplayer/common/track_thumbs.bin (regenerated).

VERIFICATION: same iverilog command as previous sections - identical 2
pre-existing missing-IP errors, zero new ones.

STATUS: SOURCE DONE (2026-08-06), self-reviewed + iverilog-checked + PC-side
asset regeneration tested + background visually spot-checked (decoded +
simulated hardware upscale). NOT yet compiled/hardware-tested. The Library
icon fix in particular is now grounded in an exact mechanism matching the
phone-photo evidence (not a hypothesis), so it's the one to watch closest
on the next test.

================================================================================
39. SECTION 39 - SECTION 38 MOSTLY CONFIRMED (VINYL + SHUFFLE GOOD); FILM-GRAIN
    BACKGROUND DITHER, BOOT TITLE MISMATCH FIX, REAL PER-ROW LIBRARY
    THUMBNAILS, MAX_TRACKS DECISION DEFERRED (source done 2026-08-07)
================================================================================
CONTEXT: user hardware-tested Section 38 (prompts/prompt_006.txt). Good news
first: "the vinyl page worked as expected and the shuffle is fine" - Section
38's Spinning Vinyl (indicator dots, reflection angle) and Section 37's
shuffle timing fix both check out on real hardware, no further action
needed on either. New feedback: (1) background still shows visible "color
blocks"/banding even after Section 38's resolution bump - the user consulted
Gemini and brought back a concrete suggestion (keep 100x90/blur/dimming,
add film-grain noise before RGB565 packing, "dithering" to mask the
blockiness) with an explicit constraint: do NOT raise resolution further,
this device's BRAM budget is too tight (correctly recalling Sections
33/34/38's history); (2) on first boot, Now Playing showed "Boys Like You"
in the title but was actually playing "Cheshire" - a real display/playback
mismatch; (3) asked about going to 128 or 256 tracks, or alternatively
running multiple separate cores each with their own up-to-32-track library;
(4) explicit green light to build the "mini library thumbnail" feature
(showing every visible row's own real art, not just the currently-loaded
track's) that's been on the roadmap since Section 37.

--- Background film-grain dither (item 1) ---
Implemented almost exactly as specified: tools/convert_audio.py's
make_track_bg_bytes() keeps the 100x90 resize/blur/dimming pipeline
unchanged, then applies per-pixel Gaussian noise (numpy, stddev=8,
BG_GRAIN_STDDEV constant) independently to each RGB channel, clips back to
0-255, and only THEN packs to RGB565 - so the noise survives quantization
instead of being rounded away. A fixed RNG seed (0) keeps output
byte-for-byte reproducible across re-runs with no other input changes
(avoids spurious diffs). Resolution was NOT changed (100x90 stays, per the
user's explicit constraint) - this is a pure PC-side dithering trick, zero
FPGA/BRAM cost. Visually spot-checked by decoding a couple of the
regenerated backgrounds - grain is clearly visible and should help mask the
remaining block edges. NOT yet hardware-confirmed whether it's enough; the
user separately floated PC actually SCALING DOWN resolution again later if
this alone proves sufficient - worth revisiting after this round's test.

--- Boot-time title/artist mismatch (item 2) ---
Root cause: title_ram/artist_ram's reset value was a hardcoded placeholder
string ("BOYS LIKE YOU" / "ITZY", leftover early-development text - see the
literal ASCII byte assignments in the reset block), and NOTHING ever
refreshed it from real data until the first actual track-change EVENT
(dpad next/prev, auto-advance, Library select, or the interact.json Track
menu's persisted-value bridge write) - which could be much later than boot,
or coincide awkwardly with the persisted-Track restore that also happens
early in boot, explaining the mismatch the user saw. This exact gap was
already flagged in an old code comment ("known boot-text gap... deferred to
Section 30") but never actually fixed until now. FIX: a new one-shot
`boot_refresh_r` pulse fires exactly once, the cycle after reset exit, and
refreshes title_ram/artist_ram from track_sel's real playlist_ram data (same
copy-from-pram_title/pram_artist pattern as every other refresh branch).
No extra settling delay was needed (unlike those other branches, which wait
one cycle for playlist_ram's registered read to catch up): track_sel is
held at its reset value (0) by the SAME always block for the entire static
boot-load window (reset_n stays low that whole time), so
pram_read_idx_next's fallback has already been continuously targeting
pram[0] for thousands of cycles by the time reset_n actually goes high -
pram_title/pram_artist are already fully settled, not freshly requested.
NOT yet hardware-confirmed.

--- Real per-row Library thumbnails (item 4, "mini library thumbnail") ---
The roadmap direction sketched in Sections 37/38 was implemented close to
as designed: added a THIRD small (30x30, sharp/no-blur) icon per track to
track_thumbs.bin, positioned right after the existing sharp thumbnail (172x
172) and background (100x90) in each track's slot -
PER_TRACK_IMG_BYTES is now 78968 bytes (was 77168), track_thumbs.bin total
2,526,976 bytes for 32 tracks (was 2,469,376).
  - tools/convert_audio.py: new make_track_row_icon_bytes() (square-crop +
    LANCZOS resize to 30x30, same sharp treatment as the full thumbnail,
    no blur - this is a crisp small icon, not a soft backdrop), called
    alongside the existing thumb/bg generation for both real tracks and
    padding slots.
  - track_thumb_ram.sv: new row_icon_mem, sized for ROW_SLOTS(8) icons at
    once (8*900 pixels = 14400 bytes total) - genuinely caches ALL 8
    visible rows simultaneously, unlike img_mem/bg_mem which only ever hold
    ONE track's art. New dedicated read port (row_icon_rd_addr/
    row_icon_rd_data), same registered-read/byte-reversal-write pattern as
    the existing two buffers.
  - audio_streamer.sv: new lowest-priority REQ branch (below the existing
    single-track img/bg fetch) - while lib_mode is asserted, continuously
    round-robins a small 1800-byte fetch through all 8 row slots
    (row_fetch_idx, free-running 0..7), keyed off list_scroll. No explicit
    "did the page change" detection needed - it just keeps re-fetching
    forever while the tab is open, so any scroll change "catches up" within
    at most 8 fetch cycles. New lib_mode/list_scroll inputs (both already
    clk_74a-domain, no new CDC concerns). A defensive bound
    (row_track_idx > 31 skips the fetch that cycle rather than issuing it)
    guards against an out-of-range dataslot read ever hanging
    target_dataslot_done forever - verified by hand that the existing
    scroll-clamping logic in core_top.v already keeps list_scroll+row<=31
    by construction, but this is exactly the kind of failure (this FSM is
    the system's ONLY dataslot requester) worth a belt-and-suspenders check
    regardless of how solid the proof looks on paper.
  - core_top.v: `in_list_icon` no longer requires `row_is_loaded` (every
    row with a track now shows its own icon, not just the currently-playing
    one) - kept built from `in_list_row_band` per Section 38's fix, not
    regressed. Replaced the OLD single-shared-icon downscale mechanism
    (next_in_list_icon/list_icon_rd_addr/list_icon_src_x/y, which
    downscaled from the one buffered track's full 172x172 image via
    non-power-of-2 division) with a DIRECT 1:1 lookup into the new 8-slot
    cache - no scaling math needed at all now, since the source image is
    already pre-scaled to exactly LIST_ICON_SIZE on the PC. This also
    simplified thumb_rd_addr back to NowPlaying-only (no more muxing
    between NowPlaying-thumb and Library-icon uses of the same port, since
    they're now on entirely separate ports).
  NOT yet hardware-confirmed - this is the largest, least-proven change in
  this batch (new BRAM buffer, new FSM states, new addressing scheme).
  Specifically needs checking: all 8 visible rows show correct art (not
  swapped/stale), scrolling doesn't glitch other rows' icons, and no
  playback disruption from the new lowest-priority fetch competing for the
  bus (should be negligible given the existing priority ordering, but this
  is genuinely new machinery).

--- MAX_TRACKS 128/256 (item 3): deferred, user's choice ---
Explained the mechanism and cost (5-bit index fields throughout -> 7/8 bits;
playlist_ram's pram[] BRAM usage grows ~4x/~8x, the real risk given this
device's tight M10K history) and the zero-RTL-risk alternative (separate
cores, each with its own up-to-32-track library, per CLAUDE.md's existing
multi-project platform_id rules) via AskUserQuestion. User chose to wait
until this round (Sections 36-39) is hardware-confirmed before attempting
either path - matches this project's own prior judgment call
(MUSICPLAYER_NOTES.txt/memory already said as much before this question was
even asked). No code changes made for this item.

FILES CHANGED: tools/convert_audio.py (film-grain dither, row-icon
generation), open-fpga-core-template-da3a021/src/fpga/core/core_top.v
(boot_refresh_r; per-row icon cache wiring, old downscale mechanism
removed), core/audio_streamer.sv (row-icon round-robin fetch), core/
track_thumb_ram.sv (row_icon_mem + port), dist/Assets/musicplayer/common/
track_thumbs.bin (regenerated, new size).

VERIFICATION: same iverilog command as previous sections - identical 2
pre-existing missing-IP errors, zero new ones, re-checked after every batch
of edits. track_thumbs.bin's new per-track layout spot-checked by decoding
several row icons and backgrounds back to PNG and visually inspecting -
row icons show sharp, correctly-cropped album art; grain is visible in
backgrounds.

STATUS: SOURCE DONE (2026-08-07), self-reviewed + iverilog-checked + PC-side
asset regeneration and visual spot-check. NOT yet compiled/hardware-tested.
The per-row Library thumbnail feature is the biggest unproven piece of this
batch - budget real attention to it specifically on the next test round.

================================================================================
40. SECTION 40 - ALBUM/PLAYLISTS TABS REMOVED, REAL BILINEAR BACKGROUND
    UPSCALE (film-grain reverted), LIBRARY SELECTED-ROW TICKER, PROGRESS BAR
    BLACK/WHITE (source done 2026-08-07)
================================================================================
CONTEXT: user feedback (prompts/prompt_007.txt) after Section 39: (1) remove
Album/Playlists tabs from the app entirely (keep history in notes only); (2)
the Section 39 film-grain noise "looks too colored, very strange, try
another way"; (3) Library tab confirmed looking great, no complaints, plus a
reminder that the row-icon cache's addressing will need updating whenever
MAX_TRACKS is eventually raised; (4) add a marquee/ticker effect to the
Library's SELECTED row when its title is too long, with a specific
behavior: hold ~3s, scroll left one character at a time, hold ~3s again once
fully off-screen, repeat; (5) progress bar should be black/white instead of
grey/white; (6) asked specifically about bilinear interpolation as a
resource-free fix for the background blockiness, referencing another Gemini
suggestion.

--- Album/Playlists tabs removed (item 1) ---
Neither ever had more than a "COMING SOON" placeholder behind them (deferred
since Section 32) - Shoulder L/R now just toggles between NowPlaying (0) and
Library (2); the ALBUM/PLAYLSTS tab_header_char cases and the entire
"COMING SOON" rendering path (coming_soon_char function, in_coming_soon and
all its CS_*/cs_* wires, the u_font_comingsoon font_rom instance) were
deleted outright, same "not just hidden, actually removed, history stays in
these notes" treatment as the Oscilloscope's Section 36 removal. cur_tab
itself stays 2 bits (not shrunk to 1) - purely cosmetic simplification with
no functional upside, not worth the risk of missing a stray comparison
somewhere.

--- Film-grain noise reverted (item 2) ---
tools/convert_audio.py's make_track_bg_bytes() is back to the plain Section
38 pipeline (resize/blur/dim, no noise stage) - see that function's updated
docstring for a root-cause note on WHY the noise looked wrong: it applied
INDEPENDENT Gaussian noise to each R/G/B channel separately, which is
CHROMATIC noise (random hue shifts - a grey pixel could pick up a random
reddish/greenish tint), not the LUMINANCE-only grain real photographic film
actually has (same random offset shared across all 3 channels, only varying
brightness). A real, identifiable bug in that attempt - worth remembering if
"add noise/grain" ever comes up again - but the user had already moved on to
wanting bilinear by the time this was reported, so a corrected retry wasn't
attempted.

--- Real bilinear background upscale (item 6) - biggest/riskiest change ---
Replaces the nearest-neighbor blit entirely. Resolution stays 100x90 (BG_W/
BG_H unchanged) per the user's explicit "without using more resources"
constraint - the fix is purely in HOW the FPGA upscales it, not in adding
more source data.

Mechanism: bilinear needs the 4 pixels surrounding each output position (2
source rows x 2 columns) available simultaneously, which a single-address
M10K port can't provide in one cycle. Two small ROW BUFFERS
(bg_buf_top/bg_buf_bot, 100 entries x 16 bits = 1600 bits each,
`(* ramstyle = "logic" *)`-tagged to force plain registers/LUTRAM instead of
M10K) hold one full source row apiece; register arrays give unlimited
combinational read "ports" for free (unlike M10K), so reading buf[x] AND
buf[x+1] in the same cycle for horizontal blending needs no addressing
tricks once a row is buffered. Whenever the on-screen row-group changes
(every 4 scanlines - bg_row_now = visible_y>>2 - this naturally handles the
frame-wrap from row 89 back to row 0 too, no special-casing needed since the
trigger only cares that the value changed), both buffers reload fresh from
track_thumb_ram's bg_mem port: row_now (~101 cycles), then row_now+1
(clamped at the image's last row - standard edge-clamp) (~101 more). A
group lasts ~2048 clk_core_12288 cycles, so the ~202-cycle reload has ~90%
margin. Per-pixel blend: extract R5/G6/B5 from all 4 corner samples, weight
each by the 1/4-step fractional x/y position (weights always sum to
exactly 16, so a plain >>4 exactly normalizes with no rounding logic
needed), sum, repack.

KNOWN, DELIBERATELY ACCEPTED TRADE-OFF: bg_buf_top is being actively
overwritten while ALSO being read for display during its own ~101-cycle
reload window (and bg_buf_bot still holds 2-groups-old data until its own
reload right after) - so roughly the first ~40% of the FIRST scanline of
EVERY 4-line band may blend from an inconsistent mix of old/new row data.
Because the timing is deterministic, this could show as a faint but
CONSISTENT (not random) horizontal seam/banding pattern repeating every 4
scanlines, not just a one-time startup blip - please specifically check for
this on the next hardware test. A cleaner double-buffered design (fill a
fully separate "back" pair one whole group ahead, swap a single front/back
select bit at the group boundary instead of overwriting the displayed
buffer) was sketched out but NOT implemented: getting its reset/bootstrap
edge case right by hand, with zero ability to simulate pixel-level timing,
was judged a real risk of trading this known/bounded imperfection for a
worse, less-understood bug. Revisit as its own focused round if the seam
turns out to actually be visible.

VERIFIED (beyond iverilog): the exact blend algorithm (weight computation,
4-corner sampling, >>4 normalization) was reimplemented byte-for-byte in
Python against the real regenerated track_thumbs.bin data and rendered to a
PNG for visual inspection - confirms the math is correct and genuinely
smooths out the 4x4 block edges that nearest-neighbor left behind (compared
side-by-side against a plain nearest-neighbor render of the same source
data). This does NOT verify the FSM timing/hardware behavior (see the
trade-off above) - only that the interpolation arithmetic itself is sound.

--- Library selected-row ticker (item 4) ---
New, separate mechanism from the existing NowPlaying title ticker (not a
modification of it) - only applies to the Library list's highlighted/
selected row, and only when that row's title actually exceeds LIST_CHARS
(19 visible characters). Behavior exactly as specified: HOLD at the start
for ~3s (180 vsyncs), then SCROLL one character every ~32 vsyncs (same pace
as the NowPlaying ticker) until the whole title has scrolled off-screen,
then loop back to HOLD. Implementation notes: `sel_title_len` is a latched
register (playlist_ram's lib_title_le secondary port only reflects ONE row
at a time - whichever the scan position currently addresses - so the
selected row's length has to be captured opportunistically at the moment
it's actually being scanned, not read fresh elsewhere); the render-side
character-slot math mirrors the NowPlaying ticker's title_slot-vs-
title_rd_idx split (list_slot = which on-screen slot, ticker-independent,
gates visibility; list_char_idx = list_slot+ticker_offset, which title
character to fetch) - getting this backwards was the actual near-bug caught
during implementation: using the ticker-offset-INCLUSIVE index for the
"am I in the visible window" check would have made the row's text vanish
almost immediately after scrolling started, instead of sliding smoothly.

--- Progress bar black/white (item 5) ---
COLOR_BORDER (the bar's unfilled-track and separator-line color) changed
from dark navy-grey (0x1E1E30) to pure black (0x000000). This constant is
now purely progress-bar-scoped (its other historical use, the Oscilloscope
box border, is long gone since Section 36).

--- Noted for later (item 3) ---
User flagged that the Library row-icon cache's addressing (audio_streamer.sv's
row_track_idx, currently a defensively-bounded 0..31 check) will need
updating whenever MAX_TRACKS is eventually raised past 32 - correct, already
implicitly true of most 5-bit-track-index code in this project; no action
needed now since MAX_TRACKS expansion itself remains deferred (see Section
39's AskUserQuestion decision).

FILES CHANGED: core/core_top.v (tabs removed; bilinear background upscale
replacing nearest-neighbor; Library ticker; COLOR_BORDER), tools/
convert_audio.py (film-grain reverted, numpy import removed), dist/Assets/
musicplayer/common/track_thumbs.bin (regenerated, noise-free).

VERIFICATION: same iverilog command as previous sections - identical 2
pre-existing missing-IP errors, zero new ones, re-checked after every batch
of edits. Bilinear blend algorithm additionally cross-checked in Python
against real track data (see above).

STATUS: SOURCE DONE (2026-08-07), self-reviewed + iverilog-checked + PC-side
asset regeneration + bilinear algorithm cross-verified in Python. NOT yet
compiled/hardware-tested. The bilinear background upscale is this round's
highest-risk item (new FSM, new register-array buffers, a known/documented
possible seam artifact) - please test it specifically and report back
whether the "color blocks" complaint is actually resolved and whether any
horizontal banding is visible.

================================================================================
41. SECTION 41 - SECTION 40 HARDWARE-CONFIRMED; PLAY/PAUSE ICON SWAP + TICKER
    HOLD/STOP REDESIGN; MAX_TRACKS 32 -> 512 EXPANSION (source done 2026-08-23)
================================================================================
CONTEXT: user hardware-tested Section 40 (prompts/prompt_008.txt, log
_040809 - 17.7MB, zero "error" mentions, SD-dumped bitstream hash confirmed
identical to the Section 40 build): "This version works pretty well" - no
specific complaints about the tabs removal, bilinear background, ticker, or
progress bar, so all four of Section 40's changes are HARDWARE-CONFIRMED.

New feedback in the same prompt: (1) the play/pause icon was backwards from
every other player's convention; (2) both tickers (NowPlaying title,
Library selected-row) should STOP once the title's last character reaches
the right edge, instead of continuing to scroll it fully off-screen; (3) the
3-second hold before a ticker starts felt too long, wanted 1 second instead;
(4) the big one - expand the track library toward 512+ tracks using the real
music now in source_musics/ (Aespa/ITZY/IU/NewJeans).

--- Play/pause icon swap (item 1) ---
core_top.v's big_icon_lit ternary had the branches backwards: showed the
pause bars while PLAYING and the play triangle while PAUSED - opposite of
the "icon shows the action a tap will perform" convention every other
player uses. One-line fix (swap the two branches).

--- Ticker hold/stop redesign (items 2, 3) ---
Both tickers (the pre-existing NowPlaying title ticker and Section 40's new
Library selected-row ticker) were rebuilt onto the same 3-state
HOLD_START -> SCROLL -> HOLD_END shape, replacing the NowPlaying ticker's old
"just free-scroll forever, wrap via register overflow" behavior and the
Library ticker's old "scroll until offset >= full title length" (which
scrolled the text completely off-screen before looping, matching the user's
complaint). SCROLL now stops as soon as the title's LAST character reaches
the rightmost visible slot (max_offset = title_len - visible_chars), holds
there, then resets to offset 0 and holds again. Hold duration for both is a
single shared TICKER_HOLD_VSYNCS localparam, changed 180 (~3s) -> 60 (~1s).
User confirmed via AskUserQuestion that this reading of "reset after last
char shown at the very right, wait 1 sec" was correct before implementing.

--- MAX_TRACKS 32 -> 512 (item 4) ---
By far the largest MAX_TRACKS jump attempted (16x, vs. the previous largest
of 4x which took two extra hardware-debug rounds - Sections 33/34).
Investigated the resource risk before touching anything: playlist_ram.sv's
block-RAM-inference fixes from Sections 33/34 are already generic (derive
every address width from $clog2(MAX_TRACKS)), and track_thumb_ram.sv is
already track-count-INDEPENDENT (only caches the one playing track's art +
8 visible Library rows, refilled on demand) - so this jump does not
reintroduce either of those bug classes. Live Fitter numbers from the
Section 40 compile (36% ALM, 25% block memory bits) leave huge headroom:
playlist_ram's pram[] grows by ~491,520 bits (32->512 rows of 1024 bits
each) to ~40% block memory bits total: comfortably inside budget.

Real work this round was mechanical, not architectural: every track/list
index hardcoded to 5 bits throughout core_top.v (~20 signals - track_sel,
list_cursor, list_scroll, prev/next_track_sel, shuffle_pick, last_track_idx,
pram_read_idx_next, etc., plus their _s1/_vid/_vid_prev cross-domain
copies), 6 bits for the live track_count (pram_track_count - already
latently buggy past 63 tracks even before this round) - all widened to 9
and 10 bits respectively, following the exact "subtract at full width, THEN
truncate the result" pattern already used for last_track_idx (the project's
own precedent for avoiding exactly this truncation-bug class). Also widened:
playlist_ram.sv's track_idx/lib_idx/track_count ports; audio_streamer.sv's
track_select/list_scroll/track_sel_r/row_track_idx, plus its hardcoded
`row_track_idx <= 31` bound replaced with a proper MAX_TRACKS parameter
(matching playlist_ram's) per Section 40's own "will need updating" note.

User decisions (via AskUserQuestion before implementing): (a) set
MAX_TRACKS=512 now for headroom, but only populate the ~356 real tracks
that exist in source_musics/ today (44 albums across 4 artists - short of
512) - unused slots stay zeroed, same as today's 26-of-32; (b) keep
uncompressed 48kHz/16-bit PCM (no on-FPGA decoder work), accepting the
~880MB -> ~13GB jump in the audio blob's SD-card footprint.

tools/convert_audio.py: MAX_TRACKS constant 32 -> 512. Added a new
--artist-dirs mode (expands each given artist directory into its sorted
album subdirectories, then reuses the existing --dirs combine-and-convert
path unchanged) so the user doesn't have to hand-list all 44 album paths.
update_data_json()/update_interact_json() already compute real byte sizes
and regenerate the Track menu from whatever was actually processed - no
manual data.json/interact.json edits needed, same mechanism that made
content-only changes "no recompile needed" since Section 32.

Ran: `py tools/convert_audio.py --artist-dirs "source_musics/Aespa"
"source_musics/ITZY" "source_musics/IU" "source_musics/NewJeans" --use-tags`
(background, ~356 tracks - expect a long run; ffmpeg decode+resample+pad per
track plus per-track thumbnail/background/row-icon generation via PIL).

FILES CHANGED: core/core_top.v (icon swap; both tickers rebuilt onto the
shared hold-scroll-hold shape; MAX_TRACKS-driven index widening throughout,
~20 signals 5->9 bits, track_count 6->10 bits; .MAX_TRACKS(512) at both
playlist_ram/audio_streamer instantiations), core/playlist_ram.sv
(track_idx/lib_idx/track_count port widths only - internals already
MAX_TRACKS-generic), core/audio_streamer.sv (track_select/list_scroll/
track_sel_r/row_track_idx widened; new MAX_TRACKS parameter replacing the
hardcoded row_track_idx bound), tools/convert_audio.py (MAX_TRACKS=512,
new --artist-dirs mode).

VERIFICATION: `iverilog -g2012 -Wall -tnull core/core_top.v
core/audio_streamer.sv core/playlist_ram.sv core/track_thumb_ram.sv
core/psram_audio_buffer.sv core/psram.sv core/font_rom.v
core/core_bridge_cmd.v core/mf_pllbase.v apf/common.v` - same 2
pre-existing missing-IP errors as always, zero new ones, re-checked after
the full widening pass. Grepped core_top.v afterward for every
track/list-index identifier to confirm no stray 5-bit/6-bit literal was
missed (same check used in Section 32).

convert_audio.py's asset regeneration finished cleanly: 356 real tracks
found (352 with real embedded cover art, 4 fall back to the default
graphic), 26,223 total chunks (well under the 65,535-chunk/16-bit ceiling -
confirms the earlier resource-risk estimate that typical K-pop track
lengths wouldn't come close to that limit even at 512 tracks). data.json's
three size_exact values match the plan's hand-computed numbers exactly:
Test Audio 0x333780000 (~13.1GB), Playlist 0x10000 (512*128), Track Thumbs
0x268F000 (512*78968 - exactly 16x Section 40's 0x268F00, a good
cross-check that PER_TRACK_IMG_BYTES math didn't drift). interact.json's
Track menu now has 356 entries (0..355).

STATUS: SOURCE DONE (2026-08-23), self-reviewed + iverilog-checked + PC-side
asset regeneration completed and spot-checked against hand-computed
numbers. Icon swap and ticker redesign are small, low-risk changes.
MAX_TRACKS=512 is NOT yet compiled/hardware-tested - that's the user's next
step (Quartus recompile, expected ~40% block memory bits / modest ALM
increase per the resource analysis above - please report the actual Fitter
numbers to confirm). See NEXT_STEPS.txt for the exact recompile/deploy
commands; note the SD card copy this round is ~13.2GB vs. the previous
~900MB, so budget more time for it.

--- HARDWARE TEST RESULT (prompt_009.txt, log _020344/_020456) ---
FAILED to boot: "Load error in 'interact', General error" + "Error in core
setup". Both logs stop dead right after "Opening
/Cores/mhlin.MusicPlayer/interact.json" - no further core-load steps at all
(not even "Interact: Added element..."), i.e. this fails BEFORE the
bitstream is even loaded, independent of whether the Quartus recompile
itself would have fit. Confirmed the file itself was NOT the bug: valid
JSON (re-parsed cleanly), pure ASCII (all non-ASCII track-name characters
already \uXXXX-escaped, same as every prior working round). The only thing
that changed is scale: the Settings-menu "Track" list variable jumped from
26 options (tested fine for months) to 356 options (~49KB) - first time
this project has ever pushed that mechanism anywhere near this size, and
very likely hit an undocumented Pocket-firmware limit on interact.json list
size (exact limit unknown - not worth guessing at further since the fix
below sidesteps the whole question).

FIX: per user's explicit choice (AskUserQuestion - "drop it entirely" over
"cap it at a small number"), removed the Track list variable from
interact.json altogether rather than guessing a safe smaller count. This
picker was always a Settings-menu convenience layered on top of - and
entirely independent of - the in-core Library tab (which reads D-pad input
directly in core_top.v and never touches interact.json), so dropping it has
ZERO effect on the actual player: full browsing/selection of all 356 tracks
still works the same way it always has, through the Library tab.
tools/convert_audio.py's update_interact_json() now REMOVES the id=1 Track
variable from both interact.json copies (instead of populating its
options), restoring the exact `{"variables": [], "messages": []}` shape
this project had before the feature was ever added (pre-Section 29). Also
removed the now-truly-dead HDL that only ever fired from this variable's
bridge write (0xF3000010): core_top.v's track_sel priority-chain branch,
the track_menu_r 1-cycle-delay register + its always block, and the
matching branch in pram_read_idx_next's chain - same "not just hidden,
actually removed" treatment as the Album/Playlists tabs and Oscilloscope
before it, now that nothing will ever write to that address again.
get_menu_name() in convert_audio.py (its only consumer) was also removed -
it cost a real per-track ffprobe subprocess call that's now pure waste.

Re-verified: iverilog same 2 pre-existing missing-IP errors, zero new ones.
Directly re-ran just update_interact_json() (no need to redo the full ~356-
track audio conversion) - both interact.json copies now read
`{"interact": {"magic": "APF_VER_1", "variables": [], "messages": []}}`.

STATUS: interact.json fix is a data-only change, verified and ready
immediately - no recompile needed for it by itself. The HDL cleanup
(removing the dead bridge-write branch) DOES require a fresh Quartus
recompile, but the MAX_TRACKS=512 widening already required one anyway, so
this doesn't cost an extra round-trip - just do the recompile once with
both sets of changes included. Still NOT yet hardware-tested past this
boot-blocking bug - next test should get past interact.json loading and
reach the actual bitstream/Fitter-fit question for the first time.

================================================================================
42. SECTION 42 - MULTI-BANK AUDIO FIX FOR THE 4GB SINGLE-SLOT CEILING;
    LIBRARY LAYOUT GAP REBALANCE (source done 2026-08-27)
================================================================================
CONTEXT: user hardware-tested Section 41 (prompts/prompt_010.txt). The
interact.json fix worked - core boots now. Icon swap, ticker redesign, and
Library scrolling all confirmed working ("worked as expect" for all three).
But real playback was badly broken: selecting a Library track played the
wrong track from partway through, not the start; shuffle kept landing on
wrong/mid-track audio; landing on an Aespa track always "started from the
beginning and played normally"; and the user precisely isolated where
sequential playback first broke: "After playing Gold from ITZY, the next
track is Imaginary Friend, but it was playing an aespa track from the
middle (supernova), all tracks didn't work normally after this track."

--- Root cause (fully traced, not guessed) ---
APF's target_dataslot_slotoffset field is 32 bits. audio_streamer.sv
requests an audio chunk via `{chunk_idx[12:0], 19'b0}` - a 13-bit chunk
index shifted left 19 bits (CHUNK_BYTES=512KB=2^19) - and 13+19 exactly
fills 32 bits. This was never an arbitrary truncation bug - it's the
maximum ANY 32-bit offset can express at this chunk size: exactly 8,192
chunks = 4GB of audio, per data slot, full stop. This project's own history
already flagged this once (an old NEXT_STEPS-era note: "chunk_idx is 16
bits but slotoffset uses only [12:0], so max 8191 chunks = ~6.2 hours")
back when the whole library was a few hundred MB and the limit was purely
theoretical - nobody had to revisit it because nothing ever got close.
MAX_TRACKS=512's real ~13.1GB library blew through it for the first time.

Verified against the real conversion log data (not just theory): track 117
("GOLD", start chunk 8147, 69 chunks -> range 8147-8215) is the FIRST track
whose range crosses chunk 8192 - exactly where the user's report says
things broke. Every track past that point silently aliases to the wrong
file offset (mod 4GB) - explains every symptom: Aespa + early ITZY (all
under 8192) always worked, shuffle "recovered" whenever it landed back in
that safe range, and everything from track 117 onward was permanently wrong
(chunk 8216 aliases to chunk 24, which falls inside Supernova's own 0-65
chunk range - literally "an aespa track from the middle (supernova)").

--- Fix: split audio into multiple "Audio Bank N" data slots ---
Per user's explicit choice (AskUserQuestion - "proper fix: multi-slot
audio" over "cap the library for now"): rather than reduce track count or
audio quality, the single ~13.1GB test_audio.bin is now split into several
banks, each capped at CHUNKS_PER_BANK=8000 chunks (~3.9GB, ~192-chunk
margin below the hard 8192 wall) - no track ever spans two banks. Full
design/investigation is in plans/ (validated-wibbling-wall.md at the time)
but the key insight: the per-chunk request math itself
(`{chunk_idx[12:0], 19'b0}`) was NEVER the bug and needed NO changes - only
WHICH data slot a request targets needed to become per-track instead of a
fixed constant, since chunk_idx is now bank-LOCAL (already under 8192 by
construction) instead of a global cross-library offset.

Changes:
- tools/convert_audio.py: new per-track bank assignment during the existing
  track loop (running `bank_chunks_used` counter, start a new bank before a
  track would push it over budget). playlist.bin's per-track record gains a
  new `audio_bank` byte (byte offset 100, previously all-zero reserved
  space - see make_playlist_entry's updated docstring); `start_chunk`'s
  on-disk MEANING changes from global to bank-local (bit position/width
  unchanged). Writes `test_audio_bankN.bin` per bank instead of one
  `test_audio.bin`. update_data_json() extended to ADD/REMOVE dynamic
  "Audio Bank N" slot entries (ids 20+N) instead of only updating sizes of
  slots that already exist - bank count varies run to run with library
  size, and the old fixed `id: 16` single-file "Test Audio" slot is
  retired/removed.
- playlist_ram.sv: new `track_audio_bank` output port (4 bits), extracted
  from the new reserved byte via the same free bit-slicing-of-track_row
  technique every other field already uses - no new memory access, no
  inference risk, no logic changes beyond the port and the extraction line.
- audio_streamer.sv: `AUDIO_SLOT_ID` (fixed constant) becomes
  `AUDIO_SLOT_ID_BASE` (=20) + a new `cur_audio_bank` input, latched into a
  new `audio_bank_r` register at the EXACT same moment `track_sel_r`/
  `chunk_idx` already reseed on a track change - piggybacks on the existing,
  already-hardware-proven reseed timing, no new race window introduced.
- core_top.v: new `pram_audio_bank` wire connecting playlist_ram's new
  output to audio_streamer's new input; `.AUDIO_SLOT_ID(16'd16)` ->
  `.AUDIO_SLOT_ID_BASE(16'd20)`.
- Confirmed independent/unaffected: psram_audio_buffer.sv (the PSRAM ring
  buffer) only cares about which bridge-address window bytes land in,
  completely agnostic to which data slot/bank they came from; chunks_played/
  progress-bar math was already track-relative, never globally cumulative.

Re-ran the full conversion (`py tools/convert_audio.py --artist-dirs
"source_musics/Aespa" "source_musics/ITZY" "source_musics/IU"
"source_musics/NewJeans" --use-tags`) to regenerate everything against the
new bank-splitting logic - same 356 real tracks, same total 26,223 chunks/
13,748,404,224 bytes, just repackaged into 4 banks: bank0 4,162,846,720B
(~7940 chunks), bank1 4,183,818,240B (~7980 chunks), bank2 4,147,118,080B
(~7912 chunks), bank3 1,254,621,184B (~2393 chunks, leftover) - every bank
comfortably under the 8000-chunk budget and the 8192-chunk hard ceiling.
Confirmed the previously-broken transition now lands safely: track 117
("GOLD") is bank=1, LOCAL start=207 (was global 8147 before this fix) and
track 118 ("Imaginary Friend") is bank=1, start=276 - both tiny local
offsets nowhere near any boundary, confirming the split landed well before
this pair (between tracks ~113-114) rather than after. data.json verified:
old `id: 16` entry gone, four new entries id 20-23 "Audio Bank 0..3" with
matching size_exact values, Playlist/Track Thumbs unchanged. Deleted the
now-superseded single `test_audio.bin` (13.1GB, git-tracked from the old
32-track era) from dist/ - it's fully replaced by the 4 bank files and was
no longer referenced by anything; freed ~13GB of disk (was down to 66GB
free / 97% used).

--- Library tab layout gap rebalance (small, folded into this round per
    user's own "not a big change, no additional round needed") ---
User noticed a blank band at the bottom of the Library list (screen is
360px tall; 8 rows * 36px = 288px doesn't fill it, leaving 44px unused
below row 8, against only a 4px gap under the "LIBRARY" header) and asked
to split that leftover space roughly evenly instead of dumping nearly all
of it at the bottom. Same row count/size (8 rows, 36px each) - just moved
LIST_Y_START from 28 to 48, giving a clean 24px gap above AND below the
list (48-24=24 under the header, 360-(48+288)=24 at the bottom). One
localparam change; every row/highlight/icon position already derives from
LIST_Y_START, so nothing else needed to move.

--- Future ideas noted for later planning (not started, no urgency) ---
Per user's own framing ("not urgent... we can do this later, just note it
and also we can plan it through these rounds"):
  1. A third NowPlaying effect mode: full-screen album art (no icon/text
     overlay), possibly larger than today's 172x172 sharp thumbnail if
     resources allow, otherwise same size.
  2. A screensaver/dim/blank-screen mode, both for battery life and to
     reduce FPGA switching activity/heat (same motivation that led to
     removing the Oscilloscope effect in Section 36).
  3. Additional Display Mode / scaler entries beyond the current single
     "CRT Trinitron" - user wants some of the Pocket's other classic CRT-
     style options available too (see CLAUDE.md's Display Mode menu
     reference, video.json's display_modes array, ImageViewer's IDs.xlsx
     for valid IDs/names - same menu mechanism already used there).

FILES CHANGED: tools/convert_audio.py (multi-bank splitting, audio_bank
playlist field, update_data_json rewritten to manage dynamic bank slots),
core/playlist_ram.sv (track_audio_bank port), core/audio_streamer.sv
(AUDIO_SLOT_ID_BASE + cur_audio_bank/audio_bank_r), core/core_top.v
(pram_audio_bank wiring, LIST_Y_START 28->48).

VERIFICATION: iverilog same 2 pre-existing missing-IP errors, zero new
ones, re-checked after the HDL changes and again after the layout tweak.

STATUS: HARDWARE-CONFIRMED (2026-08-28, prompts/prompt_011.txt: "No bug
found through this round, everything worked perfectly"). Multi-bank audio
fix, all Section 41 UI changes (icon swap, ticker redesign, MAX_TRACKS=512),
and the Library layout gap rebalance are all confirmed working together on
real hardware, across the full 356-track library including the
previously-broken track 117 region and beyond. Debug logs (3 new sessions,
_052434/_225228/_051530) show zero "error" mentions. This closes out the
Section 40-42 MAX_TRACKS=512 expansion arc.

================================================================================
43. SECTION 43 - NEW PROJECT ICON, LIBRARY HIGHLIGHT COLOR + LONG-PRESS
    SCROLL, CRT DISPLAY MODES, FULL ART EFFECT + SCREENSAVER (source done
    2026-08-28)
================================================================================
CONTEXT: prompt_011.txt, after Section 42's clean hardware confirmation.
User provided a new project icon (plans/PocketPlayer_icon.drawio, exported
to .png + a rounded variant) to use as both the default album-art fallback
AND the whole project's icon; asked to start the 3 "future ideas" noted in
Section 42 (full-art NowPlaying mode, screensaver, more CRT display modes);
asked to check prior notes/prompts for anything else missed; asked for the
Library selection color to match the icon's background blue, and a
long-press Up/Down fast-scroll in the Library tab (~5 tracks/sec).

--- New project icon (item: default thumbnail + "whole project" icon) ---
The icon is a simple geometric mark (a few rectangles/parallelograms + a
grey drop-shadow bevel) on a #4C7AA3 steel-blue background - confirmed
exact colors straight from the .drawio XML (fillColor=#4C7AA3/#FFFFFF/
#686868), not guessed from the rendered PNG. Since the user already
exported ready-made PNGs (plans/PocketPlayer_icon.drawio.png plain-square,
plans/PocketPlayer_icon_rounded.drawio.png rounded-corner), there was no
need to reconstruct the geometry in PIL - both generators just do a
high-quality LANCZOS resize of the real exported artwork:
- tools/make_default_thumb.py's make_image() replaced entirely (was
  procedurally drawing the old beamed-notes glyph) - now loads and resizes
  the plain-square export to 172x172. This is convert_audio.py's fallback
  source for any track without embedded art AND all padding slots beyond
  the real 356 tracks, so a full re-run of convert_audio.py was needed to
  bake it into track_thumbs.bin (same 356-track/26,223-chunk/4-bank numbers
  as Section 42 - confirmed unchanged, this only touched image bytes).
- New tools/make_icon.py generates dist/Cores/mhlin.MusicPlayer/icon.bin
  (36x36 RGB565, 2592 bytes - confirmed format via POCKET_CORE_NOTES.txt's
  documented size) from the ROUNDED export, since this is displayed as a
  rounded-corner app icon in openFPGA's core list (unlike the plain-square
  thumbnail context). Old plans/Music_Player_Icon.png (Section 35's
  reference for the beamed-notes design) deleted, superseded.
- NOT touched: dist/Platforms/_images/musicplayer.bin (the platform-browser
  banner image, 171930 bytes, different purpose/dimensions than icon.bin) -
  the user asked for "the icon", which most naturally means icon.bin; flag
  if the platform banner should also be updated.

--- Library highlight color + long-press scroll ---
COLOR_HIGHLIGHT (core_top.v) changed from the old cyan accent (0x00B4D8) to
the icon's own background blue (0x4C7AA3), tying the UI palette to the new
branding. Library tab Up/Down gained auto-repeat while held: a new
26-bit `updn_hold_ctr` (counts clk_74a cycles - this always block runs on
clk_74a, 74.25MHz) crosses `UPDN_INITIAL_DELAY` (~500ms) for the first
repeat, then `UPDN_REPEAT_INTERVAL` (~200ms = 5 steps/sec) for every
subsequent one while still held; new `do_step_up`/`do_step_down` wires are
true on EITHER the original press edge (unchanged single-step behavior) OR
a repeat tick, feeding the exact same cursor-move logic either way (no
duplicated wraparound/scroll-adjust code).

--- Additional CRT-style Display Mode entries (data-only, zero HDL risk) ---
video.json (dev + dist) previously had no `display_modes` array at all -
the Pocket's own OS was silently applying a "Normal + CRT Trinitron"
baseline the core never explicitly asked for, which is what the user saw
as "now only CRT Trinitron". Added an explicit `display_modes` list -
reused ImageViewer's own already-proven set of 11 IDs verbatim (0x10, 0x22,
0x31, 0x32, 0x41, 0x42, 0xE0, 0xE1, 0x20, 0x30, 0x40 - looked up against
ImageViewer/IDs.xlsx: CRT Trinitron, Original GBP, Original GBC LCD(+),
Original GBA LCD/SP101, Pinball Neon Matrix, Vacuum Fluorescent, Grayscale/
Reflective/Backlit Color LCD) rather than picking a fresh subset - this
exact list is already confirmed working on the same platform/template.
No FPGA recompile needed for this one (pure SD-card JSON), but it's
deployed alongside everything else in this round's recompile regardless.

--- Missed-ideas check (explicit user request) ---
Searched all of MUSICPLAYER_NOTES.txt + every prompts/*.txt for previously
raised ideas that were never implemented or explicitly closed out. Found 5:
  1. Bar-Chart/spectrum VU-meter NowPlaying effect (prompt_000/UI_SPEC's
     4-animation plan) - never built (Oscilloscope was a different effect
     and got removed; Vinyl/Thumbnail/now Full Art exist, Bar Chart doesn't).
  2. Real physics-based vinyl-pause deceleration (prompt_000 asked for
     smooth slowdown; Section 33 shipped a hard freeze instead, explicitly
     flagged as "can add real deceleration later if wanted" - never revisited).
  3. Real image rotation for the Spinning Vinyl disc (Section 33 used a
     "reflection wedge" trick instead of an actual rotate transform,
     explicitly deferred - never revisited).
  4. "Repeat single" mode (UI_SPEC specified a 3-state repeat cycle
     all/single/off; only the 2-state all/stop-at-end version was ever
     built, "repeat single... deferred" - never revisited).
  5. On-device "Favorites" tagging via a persistent favorites.bin
     (prompt_000's Section 5 stretch goal) - zero mentions anywhere after
     the original prompt, never implemented or discussed again.
  (Compressed-audio decoding, prompt_000's OTHER stretch goal, was always
  framed as a distant "once baseline is robust" goal, not a concrete ask -
  not counted as "missed", just not yet reached.)
Reporting these back to the user for prioritization, not implementing any
of them this round.

--- Full Art NowPlaying effect (3rd mode) ---
`effect_mode` widened 1->2 bits (0=Still Thumbnail, 1=Spinning Vinyl,
2=Full Art new EFFECT_FULL_ART), Up/Down now cycles 0->1->2->0 instead of
toggling. Per user's explicit ask ("just simply ^2 the pixel size not the
resolution"), Full Art reuses the EXACT SAME 172x172 img_mem (already
loaded per-track, zero new storage) at 2x NEAREST-NEIGHBOR pixel-doubling,
displayed at 344x344 centered on the 400x360 screen (28px side margins,
8px top/bottom). `thumb_x_start_eff`/new `thumb_y_start_eff`/`thumb_w_eff`/
`thumb_h_eff` extend the existing Still-vs-Vinyl ternary with a Full Art
case; `thumb_rd_addr`'s address math now computes local x/y first, then
right-shifts by 1 ONLY in Full Art mode before the same row*172+col lookup
- every 2x2 screen block reads one source pixel. This is the only real
per-pixel logic change; everything else is address-range plumbing, which
is why this stays cheap resource-wise as the user hoped. Per user's
confirmed choice (AskUserQuestion), the existing blurred-background
rendering is NOT suppressed in the thin margin - it shows through exactly
like it already does around the smaller Still Thumbnail/Vinyl art today.
Per "no icon/text overlay", added `&& (effect_mode_vid != EFFECT_FULL_ART)`
to in_big_icon/in_title_area/in_artist_area/in_bar_area/the progress-bar
separator line; the Spinning Vinyl disc/reflection/label/indicator-dot
wires were already gated on EFFECT_SPINNING_VINYL specifically, so they
needed no changes.

--- Select-button screensaver (full black blank) ---
New `screensaver_on` (clk_74a) toggled by `cont1_key[14]` (Select) - same
edge-triggered-toggle pattern as X/Y/shoulder buttons, and NOT gated by
cur_tab (works from either tab). cont1_key[14]=Select is a confirmed
mapping on this exact platform/template - ImageViewer's own history
(POCKET_CORE_NOTES.txt) already moved a debug toggle to this exact bit
successfully. Synced into the video domain via `synch_3 s_screensaver_vid`
like every other cross-domain flag here. Per user's confirmed choice
(full blank over dimmed), the entire per-pixel render block is wrapped in
`if (!screensaver_vid) ... else vidout_rgb <= 24'h0;` - single override
point, highest priority. Deliberately did NOT wrap the background-image
row-group load trigger (bg_disp_row_prev/bg_row_changed) in this condition
- that keeps running unconditionally so the background stays fresh/correct
for the instant the screensaver turns back off, rather than risking a
stale-image glitch. Also froze the two purely-cosmetic per-vsync counters
(NowPlaying + Library ticker state machines, Spinning Vinyl's rotation
div/idx) while screensaver_vid is true - a genuine but modest reduction in
ongoing switching activity, explicitly NOT touching audio/chunk-streaming/
background-loading logic, which all keep running completely normally so
music keeps playing uninterrupted. Being upfront (see also NEXT_STEPS.txt):
this is NOT real clock-gating - the video timing generator itself can't be
paused without breaking sync - so the realistic win is "screen goes fully
black" (the actual battery-relevant part on a backlit display) plus two
frozen counters, not a deep FPGA power reduction.

FILES CHANGED: core/core_top.v (COLOR_HIGHLIGHT; long-press Up/Down repeat;
effect_mode 1->2 bits + Full Art geometry/addressing + overlay exclusions;
screensaver toggle/sync/render-wrap/counter-freezes), tools/
make_default_thumb.py (loads the new icon PNG instead of drawing),
tools/make_icon.py (new - generates icon.bin), dist/Cores/mhlin.MusicPlayer/
icon.bin (regenerated), dist/.../track_thumbs.bin (regenerated via full
convert_audio.py re-run), video.json (dev+dist, new display_modes array),
plans/ (new icon source files, old Music_Player_Icon.png removed).

VERIFICATION: iverilog same 2 pre-existing missing-IP errors, zero new
ones, re-checked after every batch of edits. Grepped for every remaining
`effect_mode`/`effect_mode_vid` comparison after the 1->2 bit widening to
confirm none were missed (same audit style as the MAX_TRACKS index
widening). Both new PC-side icon generators smoke-tested standalone
(correct byte counts: 59168 for the thumbnail, 2592 for icon.bin) and
visually spot-checked by converting their output back to PNG.

STATUS: HARDWARE-CONFIRMED (2026-08-28, prompts/prompt_012.txt) with one
bug found and fixed in the same round - see Section 44. User ran a ~1.5-2
hour continuous shuffle stress test across the full library: "things
worked great, the temperature is about 49 celcius and does not rise,
perfect" - icon swap, highlight color, long-press scroll, CRT display
modes, Full Art mode, and the screensaver all confirmed working with no
thermal or stability concerns. Debug logs (_072609, _173550 - the latter
spanning the full stress test) show zero "error" mentions. The one bug:
NowPlaying Up/Down both advanced the effect cycle in the same direction
regardless of which was pressed - fixed in Section 44.

================================================================================
44. SECTION 44 - EFFECT-CYCLE DIRECTION BUG FIX; BUTTON LOCK (START);
    FUTURE-IDEAS LIST TRIMMED; BEGINNING PROJECT WRAP-UP (source done
    2026-08-28)
================================================================================
CONTEXT: prompt_012.txt, immediately after Section 43's near-clean hardware
confirmation. Bug report: NowPlaying Up/Down both cycled the effect
forward regardless of which was pressed ("123123123" instead of proper
bidirectional "1232321"). New feature: a Start-button lock to prevent
accidental presses, with a transient "LOCKED"/"UNLOCKED" corner banner,
hooked into the existing screensaver so the two share one mutual-exclusion
mechanism. Also: user decided to drop 2 of the 5 previously-found "missed
ideas" entirely and demote the other 3 to a future-version backlog (not
this release) - "I think we can drop the previously mentioned 5 ideas...
since I would like the player to be as simple and easy to use as possible."
User has now decided the player is feature-complete enough for a v1
release and wants to move into publishing/documentation work (see below).

--- Effect-cycle direction bug fix ---
Root cause: both branches of the Up/Down handler called the SAME forward-
increment expression (`(effect_mode == EFFECT_FULL_ART) ? EFFECT_STILL_THUMB
: effect_mode + 2'd1`), so Down was accidentally wired to do exactly what Up
did - a leftover from when Up/Down were still a single OR'd condition (fine
for Section 43's 3-way FORWARD-ONLY cycle, but never updated when the
review should have made it directional). Fixed: Up keeps the forward step
(wraps Full Art -> Still), Down now gets the mirrored backward step (wraps
Still -> Full Art), as two separate `if`/`else if` branches instead of one
OR'd condition.

--- Button lock (Start button) ---
New `lock_on` (clk_74a), toggled by `cont1_key[15]` (Start) - confirmed
mapping on this platform/template via ImageViewer's own Start-button-menu
history. Designed to interlock cleanly with the existing screensaver
(Select) per the user's explicit spec ("hooked to the blank screensaver"):
  - `input_locked = lock_on || screensaver_on` gates every OTHER button
    (D-pad in both tabs including the long-press repeat, A, X, Y, L/R) -
    added `&& !input_locked` at each of their existing trigger conditions
    (dpad_next/dpad_prev, do_step_up/do_step_down, the NowPlaying
    effect-cycle branch, shoulder L/R tab switch, A/lib_select, X/Y
    shuffle/repeat toggles).
  - Select's own toggle gained a `&& !lock_on` guard (can't enter/exit the
    screensaver while explicitly locked) and Start's toggle gained a
    `&& !screensaver_on` guard (can't lock/unlock while the screensaver is
    active) - this makes the two states mutually exclusive BY CONSTRUCTION
    (each has exactly one working "escape" button while active: Start for
    lock_on, Select for screensaver_on), exactly matching the spec's
    "disable all buttons instead of volume and select [during screensaver]"
    / "instead volume up/dn and start [during lock]" - no separate
    screensaver-specific lock flag was needed, `input_locked` already
    covers both cases correctly since they can never overlap.
  - "LOCKED"/"UNLOCKED" banner: top-left corner, 2x scale, shown for ~1s
    (reused TICKER_HOLD_VSYNCS=60 vsyncs) after every Start-triggered
    toggle - new `lock_on_vid` sync + a timer in the existing vsync-boundary
    block (same pattern as the ticker/vinyl-rotation timers), a new
    `lock_msg_char()` function (same fixed-width-string technique as
    `tab_header_char()`), and a 5th font_rom instance (`u_font_lock`).
    Deliberately NOT suppressed by Full Art mode (unlike the other text
    overlays) - this is a safety notification the user needs to see
    regardless of what's on screen, not decoration.
  - Volume up/down aren't part of cont1_key at all (handled at the Pocket
    OS/hardware level, never reach the core), so no core-side change was
    needed to keep them working during lock/screensaver - the spec's
    "instead volume" carve-out is automatic.

--- Future-ideas list trimmed ---
Per user's explicit call ("I think we can drop the previously mentioned 5
ideas... since I would like the player to be as simple and easy to use as
possible"): the 5 items found in Section 43's missed-ideas check are now
split into DROPPED (no longer planned at all) and BACKLOG (kept as a
future-version note, not this release):
  DROPPED: real physics-based vinyl-pause deceleration; real image rotation
    for the Spinning Vinyl disc (the "reflection wedge" trick stays as the
    permanent design, not a placeholder for a future fix).
  BACKLOG (future version, not v1): Bar-Chart/VU-meter NowPlaying effect;
    "repeat single" mode; on-device Favorites tagging via a persistent
    data slot.

--- Beginning project wrap-up (not started yet, this session) ---
User has declared the player feature-complete enough for a v1 release and
wants to: publish the project on GitHub; write an end-user guide (loading
music through playing/using every feature); write a separate developer
guide (filesystem layout, build/dev workflow, contribution info) for a
"totally open sourced" release; write a condensed reference for OTHER AI
agents/assistants picking up openFPGA core development on this project
(derived from this CLAUDE.md's platform-reference sections, so non-coders
can direct an AI to keep improving it); rename the core from "MusicPlayer"
to "PocketPlayer" (the name shown in the Pocket's core-selection menu,
i.e. core.json's metadata.name/shortname - same class of rename as the
2026-06-15 "Analogue MusicPlayer" -> "MusicPlayer" rename, see this file's
early sections and CLAUDE.md for that precedent and its gotchas); and
confirmed no example/copyrighted tracks may ship with the public release
("There will be no example tracks since there are laws against this").
None of this is implemented yet - real open questions exist (repo scope:
just this core vs. the whole multi-core Cores workspace; whether git
history itself needs cleaning before a public push, since old commits
still contain now-gitignored large audio blobs; and that track_thumbs.bin
currently ships REAL extracted album-art images from the user's copyrighted
library, which needs the same legal treatment as the audio before any
public push) - see NEXT_STEPS.txt for what's being asked before proceeding.

FILES CHANGED: core/core_top.v (effect-cycle direction fix; lock_on/
btn_start_r/input_locked; Select/Start mutual-exclusion guards; lock
message timer/render/font_rom instance).

VERIFICATION: iverilog same 2 pre-existing missing-IP errors, zero new
ones. Grepped every remaining `cont1_key[` usage after adding the lock
gating to confirm every user-facing button (not just the ones explicitly
mentioned in the spec) is actually covered by `input_locked`.

--- MusicPlayer -> PocketPlayer rename (same round, once the wrap-up
    questions above were answered) ---
Confirmed via AskUserQuestion before touching anything: rename EVERYTHING
(core-facing name, SD folder, platform_id/asset paths, AND the local
working folder), a new separate repo just for this project (not the whole
Cores workspace) for the GitHub publish, fresh git history for that public
repo, and real album art/track metadata excluded from the public release
(same treatment as the already-gitignored raw audio). This note covers
ONLY the in-place rename - repo creation and the 3 documentation files
(user guide, developer guide, AI-agent notes) are a separate follow-up,
not done in this round.

Investigated first: this rename needed NO Quartus recompile. Every .sv/.v
file only ever referenced "MusicPlayer" in prose comments (mostly pointing
at this notes file by name) - never as a functional string, on-screen
text, or module/parameter name. The whole rename is OS-level config
(core.json's shortname/platform_ids, the Platform banner JSON, and the
`mhlin.<shortname>` / `Assets/<platform_id>/` folder-naming convention
this file's CLAUDE.md counterpart documents as load-bearing) plus doc/
comment consistency.

Changes: `core.json` (both dist and the dev-tree copy - the LATTER turned
out to have never been customized at all, still the literal stock
"Core Template" stub, an existing gap fixed here) got `platform_ids:
["musicplayer"]` -> `["pocketplayer"]`, `shortname: "MusicPlayer"` ->
`"PocketPlayer"`, and a real description/version("1.0.0")/date_release
replacing text that had never been touched since the very first Module 2a
build. `dist/Platforms/musicplayer.json` -> `pocketplayer.json` (content:
`"name": "MusicPlayer (WIP)"` -> `"PocketPlayer"`, dropping "(WIP)" per
ImageViewer's own finished-platform precedent), `_images/musicplayer.bin`
-> `pocketplayer.bin`. Folder renames (plain renames, not delete+
regenerate - the ~13.7GB of already-generated audio banks moved intact,
confirmed by size after): `dist/Cores/mhlin.MusicPlayer/` ->
`mhlin.PocketPlayer/`, `dist/Assets/musicplayer/` -> `Assets/pocketplayer/`.
Updated the hardcoded path constants in `tools/convert_audio.py`/
`make_default_thumb.py`/`make_icon.py` to match. Renamed this file itself
(MUSICPLAYER_NOTES.txt -> POCKETPLAYER_NOTES.txt, matching this project's
own precedent from the FIRST rename) and updated every cross-reference to
it in CLAUDE.md and the HDL doc-comments that named it - historical PROSE
inside this file itself was deliberately left alone (past sections
correctly say "MusicPlayer" because that was the real name at the time;
rewriting history to match the current name would make the chronology
read as if the earlier name never existed). CLAUDE.md's own project-status
paragraph was rewritten to describe both renames and the actual current
(v1, feature-complete) status instead of stale Module 2a/2b text nobody
had revisited since 2026-06-16. The one step NOT done: the working
directory itself (`MusicPlayer/` -> `PocketPlayer/`). Renaming the active
Claude Code session's own working folder mid-session risks breaking tool
access afterward (this session's shell resets its cwd back to the fixed
`.../Cores/MusicPlayer` path after every command - if that path stopped
existing, every subsequent command could fail). Flagged to the user via
AskUserQuestion rather than gambling with it - user chose to do this one
rename themselves, whenever convenient, rather than risk it mid-session.
One-line command for whenever they're ready:
`Rename-Item "C:\Users\minhao\Documents\Analogue Pocket\Cores\MusicPlayer" "PocketPlayer"`
Everything else in this section is written as if already at the new path
(`PocketPlayer/...`) since it will be true the moment that command runs -
only the physical `git mv`-equivalent itself is outstanding.

VERIFICATION: `grep -ri musicplayer` across the whole tree (excluding
`debug/`'s SD-dump history, which accurately reflects what was actually on
the card during past tests and shouldn't be rewritten, and this file's own
historical prose) came back clean. Audio bank file sizes spot-checked
identical before/after their `dist/Assets/` folder move. No iverilog
re-check needed (zero .sv/.v logic changed) and no Quartus recompile
needed - confirmed a pure config/folder-naming change.

STATUS: Section 44's HDL changes (direction fix + lock feature) are SOURCE
DONE (2026-08-28), self-reviewed + iverilog-checked. The MusicPlayer ->
PocketPlayer rename is DONE except the top-level working-folder rename
itself (deliberately left to the user - see above; now further deferred
until v1 wraps up and this session closes, per prompt_013) - dist/ already
reads "PocketPlayer" throughout and needs no recompile for the rename
part. Repo creation + the 3 documentation files are NOT started - still
the next phase.

--- Hardware test round 1: build never actually reached the device
    (prompt_013.txt, 2026-08-29) ---
Core name showed up correctly on hardware (confirms the rename's data.json/
core.json side works) but the lock feature was missing and the build
"seemed to be the same version as previous ones." Diagnosed from file
timestamps, not guessed: the user DID run a real, successful Quartus
compile after the Section 44 source changes (`ap_core.fit.summary` shows
"Fitter Status: Successful" at 2026-08-29 08:07, `build_id.mif` regenerated
matching that same compile) - but `dist/Cores/mhlin.PocketPlayer/
bitstream.rbf_r` was still dated BEFORE the source edits even happened.
Root cause: Step 2 (`tools/make_rbf_r.py`, converting the compiled .rbf to
.rbf_r and writing it into dist/) was never run this round - the file
sitting in dist/ was actually Section 43's bitstream, just relocated under
the newly-renamed folder by the rename step, which is exactly why it
looked and behaved like the unchanged old version. Not a Quartus problem,
not an HDL bug - a missed manual step, most likely because Section 44's
NEXT_STEPS.txt asked for an unusually long sequence (SD cleanup + rename
awareness + the normal 3 steps) and this one got skipped in the shuffle.
Fixed directly: ran `make_rbf_r.py` against the ALREADY-compiled
`ap_core.rbf` (no need to ask for another Quartus run - the real compile
output was sitting right there, untouched) and wrote the correct bitstream
into dist/Cores/mhlin.PocketPlayer/bitstream.rbf_r.

Fitter numbers from that already-completed compile, now on record for the
first time since MAX_TRACKS grew to 512 tracks: 36% ALM (6,741/18,480),
45% block memory bits (1,414,576/3,153,920), 59% RAM Blocks (182/308), 38%
DSP - all comfortable, Fitter Status Successful. The block-memory/RAM-block
percentages read higher than earlier rounds' rough estimates (~40%) mostly
because this is the FIRST time real post-512-track numbers were ever
actually reported back (Section 42/43 confirmations were functional
"it works" reports, not Fitter-number reports) - not a sign anything
regressed in Sections 43/44's own (memory-free) changes.

STATUS: bitstream.rbf_r in dist/ is now correct and current as of
2026-08-29 16:55 - only Step 3 (copy dist/ to the SD card) is needed, no
further Quartus work. See NEXT_STEPS.txt.

STATUS UPDATE: HARDWARE-CONFIRMED (2026-08-30, prompts/prompt_014.txt:
"All new features worked perfectly"). Direction fix and the button lock
(Start toggle, screensaver mutual-exclusion) both confirmed working once
the correct bitstream actually reached the device. Debug logs (4 new
sessions spanning 2026-08-29) show zero "error" mentions. This closes out
the Section 40-44 arc (MAX_TRACKS=512, Full Art mode, screensaver, button
lock, and the MusicPlayer->PocketPlayer rename) - user has declared the
player feature-complete for a v1 public release and is moving into
publishing/documentation work (README/user guide, developer guide,
AI-agent development notes, GitHub repo setup - see the next section).
