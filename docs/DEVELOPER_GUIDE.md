# Developer Guide

PocketPlayer is an [openFPGA](https://www.analogue.co/developer) core for
the [Analogue Pocket](https://www.analogue.co/pocket) - it turns the Pocket
into a dedicated music player, browsing and playing a library built from
your own audio files. This guide covers building and extending the core
itself. If you just want to install and use it, see [../README.md](../README.md)
instead.

## Toolchain

You'll need:

- **Quartus Prime Lite** (the version this was built against: 25.1std.0,
  Cyclone V device support) - free from Intel/Altera, needed to compile the
  FPGA bitstream.
- **Python 3** with [Pillow](https://pypi.org/project/Pillow/) installed
  (`pip install Pillow`) - the `tools/` scripts use it for image handling.
- **ffmpeg** (with `ffprobe`) on your `PATH` - used to decode/resample
  source audio and extract embedded cover art.

## Repo layout

```
open-fpga-core-template-da3a021/   FPGA core source + Quartus project
  src/fpga/ap_core.qpf/.qsf          the Quartus project itself
  src/fpga/core/core_top.v           top-level design - tabs, rendering, input
  src/fpga/core/audio_streamer.sv    SD-card audio/art streaming FSM
  src/fpga/core/playlist_ram.sv      per-track metadata storage
  src/fpga/core/track_thumb_ram.sv   on-chip album art cache
  src/fpga/core/psram_audio_buffer.sv  PSRAM-backed playback ring buffer
  core.json / data.json / interact.json / video.json   core config (source copies)
tools/                              Python asset-generation scripts
dist/                               deployable folder - copy to an SD card
docs/                               this guide, the AI agent guide, full dev history
```

`dist/` and the `open-fpga-core-template-da3a021/` root each keep their own
copy of `core.json`/`data.json`/etc. - when you change one, update the
other to match (there's no build step that syncs them automatically).

## Build and deploy

1. Open `open-fpga-core-template-da3a021/src/fpga/ap_core.qpf` in Quartus
   and compile. Check the Fitter report for utilization - the design should
   comfortably fit a Cyclone V 5CEBA4 (currently well under half of ALM,
   block memory, and RAM block budgets).
2. Convert the compiled bitstream (Quartus outputs `.rbf`; the Pocket needs
   a bit-reversed `.rbf_r`):
   ```
   py tools/make_rbf_r.py open-fpga-core-template-da3a021/src/fpga/output_files/ap_core.rbf dist/Cores/mhlin.PocketPlayer/bitstream.rbf_r
   ```
3. Copy `dist/`'s contents to the root of your SD card (merge, don't
   replace the whole card - other cores' folders live alongside it).

If you only changed a Python tool's output or a JSON config (no HDL
edits), skip straight to step 3.

## Regenerating assets

`tools/convert_audio.py` builds everything under
`dist/Assets/pocketplayer/common/` from a folder of your own audio files -
see the README for user-facing usage. A few things worth knowing if you're
modifying it:

- Output is split across multiple "Audio Bank" files (`test_audio_bankN.bin`)
  because a single APF data slot can only address 4GB (see
  [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) for why) - `CHUNKS_PER_BANK`
  controls the split point.
- `playlist.bin` is a fixed-size table (`MAX_TRACKS` × 128 bytes/record) -
  every slot is always written, real track or zero-padded, so the FPGA's
  fixed-offset addressing never needs an "out of range" special case.
- `track_thumbs.bin` likewise always has real art or the bundled fallback
  graphic (`tools/make_default_thumb.py`) for every slot.
- `MAX_TRACKS` (currently 512) is a compile-time constant shared between
  this script and `playlist_ram.sv`'s parameter of the same name - raising
  it means changing both, plus widening every track-index signal in
  `core_top.v` (a genuinely mechanical but wide-reaching change - see
  DEVELOPMENT_HISTORY.md's account of the 32->512 jump for what that
  actually involved).

`tools/make_icon.py` / `tools/make_default_thumb.py` regenerate the
core-selection icon and fallback album art from the source images - only
worth re-running if you're changing PocketPlayer's branding.

## Architecture tour

- **`core_top.v`** owns almost everything: the 2-bit tab state machine
  (NowPlaying / Library), the 2-bit Now Playing effect state (Still
  Thumbnail / Spinning Vinyl / Full Art), all button input handling, the
  video timing generator and per-pixel rendering (a large priority-mux:
  later `if` blocks override earlier ones for the same pixel), and the
  screensaver/button-lock logic. If you're adding a new visual element or
  control, this is almost certainly where it goes.
- **`playlist_ram.sv`** loads `playlist.bin` at boot and exposes per-track
  metadata (title, artist, chunk offsets, which audio bank) through two
  read ports - one for the currently-playing track, one for whichever row
  the Library list is currently scanning. Internally it's one wide row per
  track (not a flat word array) specifically to satisfy Quartus's
  block-RAM inference rules - see AI_AGENT_GUIDE.md before changing its
  record format.
- **`audio_streamer.sv`** is the single SD-card-request state machine: a
  priority chain that fetches audio playback chunks first, then per-track
  album art (only when there's spare bus time), then Library row-icon
  thumbnails (lowest priority, only while the Library tab is open). This
  layering exists because the APF-level SD-card read protocol only
  supports one outstanding request at a time, system-wide - see
  AI_AGENT_GUIDE.md.
- **`track_thumb_ram.sv`** is a small on-chip cache: the current track's
  full-size art plus 8 slots for the Library's visible rows. It does NOT
  grow with library size - only the currently-visible content is ever
  cached on-chip.
- **`psram_audio_buffer.sv`** is the playback ring buffer backed by the
  Pocket's PSRAM (`cram0`), decoupling steady playback from the bursty
  SD-card read pattern above.

## Contributing

Issues and pull requests are welcome. A few conventions this codebase
follows, worth matching:

- Comments explain *why*, not *what* - a hidden constraint, a non-obvious
  timing requirement, or the reason a workaround exists. Skip comments
  that just restate what a well-named signal already says.
- Before any HDL change, check it elaborates cleanly:
  ```
  iverilog -g2012 -Wall -tnull open-fpga-core-template-da3a021/src/fpga/core/core_top.v open-fpga-core-template-da3a021/src/fpga/core/audio_streamer.sv open-fpga-core-template-da3a021/src/fpga/core/playlist_ram.sv open-fpga-core-template-da3a021/src/fpga/core/track_thumb_ram.sv open-fpga-core-template-da3a021/src/fpga/core/psram_audio_buffer.sv open-fpga-core-template-da3a021/src/fpga/core/psram.sv open-fpga-core-template-da3a021/src/fpga/core/font_rom.v open-fpga-core-template-da3a021/src/fpga/core/core_bridge_cmd.v open-fpga-core-template-da3a021/src/fpga/core/mf_pllbase.v open-fpga-core-template-da3a021/src/fpga/apf/common.v
  ```
  This will report a couple of pre-existing "Unknown module type" errors
  for two Quartus-IP stub modules (`mf_datatable`, `mf_pllbase_0002`) that
  iverilog can't see - that's expected and unrelated to your change; watch
  for whether your edit introduces any *new* errors beyond those two.
- Since only real hardware testing can actually confirm a change works,
  describe exactly what you changed and what to test for in your PR
  description - whoever picks it up will need to compile, deploy, and test
  on a real Pocket.
- See [DEVELOPMENT_HISTORY.md](DEVELOPMENT_HISTORY.md) for the full
  rationale behind any existing design choice before changing it - several
  things that look like they could be simplified turned out that way for a
  specific, previously-hard-won reason.

## License

MIT - see [../LICENSE](../LICENSE).
