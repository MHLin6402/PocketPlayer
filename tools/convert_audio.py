#!/usr/bin/env python3
"""
Convert source audio into raw 48kHz/16-bit stereo PCM for the PocketPlayer
PSRAM audio buffer.

Modes:
  Directory mode (recommended for full albums):
      py convert_audio.py --dir ALBUM_DIR [--output OUTPUT.bin] [--use-tags]
      Finds all audio files in ALBUM_DIR (sorted by filename), processes up to
      MAX_TRACKS=512. Generates one or more test_audio_bankN.bin + playlist.bin + track_thumbs.bin, and updates
      data.json automatically (interact.json's Track picker is removed, not populated - see README).

  Multi-directory mode (combine several albums into one library):
      py convert_audio.py --dirs ALBUM_DIR1 ALBUM_DIR2 [...] [--output OUTPUT.bin] [--use-tags]
      Same as --dir but scans each directory in order and concatenates their
      tracks (each directory's own files sorted by filename first), capped at
      MAX_TRACKS=512 total across all directories combined.

  Multi-artist mode (combine several artists' whole discographies):
      py convert_audio.py --artist-dirs ARTIST_DIR1 ARTIST_DIR2 [...] [--use-tags]
      Each ARTIST_DIR is expanded into its own album subdirectories (sorted
      by name), then combined exactly like --dirs - no need to list every
      album directory by hand.

  Concat mode (explicit file list):
      py convert_audio.py --concat output.bin track0.flac [track1.flac ...]
      Same output as --dir but you list the input files explicitly (in order).

  Single track (legacy):
      py convert_audio.py [input_file] [output_file] [--seconds N | --full]
      Decodes/resamples via ffmpeg, trims or pads to the requested length.
      --full: pad UP to a multiple of CHUNK_BYTES and print NUM_CHUNKS.

Options:
  --use-tags    Read track names from audio metadata (title tag via ffprobe).
                Falls back to filename-based name if the tag is absent.
                Applies to --dir and --concat modes.
                The Pocket menu uses the full title; the on-screen OSD uses
                a 16-char uppercase version (both derived from the same tag).

BYTE ORDER: ffmpeg s16le output is [L_lo, L_hi, R_lo, R_hi] per frame,
exactly matching psram_audio_buffer.sv's expected layout.

Requires: ffmpeg + ffprobe on PATH.
"""

import argparse
import json
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

# Some source filenames contain non-ASCII characters (e.g. Korean featured-
# artist credits); Windows consoles often default to a codepage (e.g. cp950)
# that can't encode them, crashing plain `print()`. Force UTF-8 stdout/stderr
# with lossy fallback so any filename prints without crashing the run.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8", errors="replace")

SAMPLE_RATE       = 48000
CHANNELS          = 2
BYTES_PER_SAMPLE  = 2
BYTES_PER_FRAME   = CHANNELS * BYTES_PER_SAMPLE
NUM_SAMPLES       = 2097152    # 2^21 frames, matches AUDIO_NUM_SAMPLES
CHUNK_BYTES       = 524288     # 0x80000: one ring slot = 2^17 frames * 4 B/frame

# Section 41 follow-up: APF's target_dataslot_slotoffset is 32 bits, and
# audio_streamer.sv addresses a chunk as {chunk_idx[12:0], 19'b0} (13 bits *
# CHUNK_BYTES=2^19 exactly fills 32 bits) - so a SINGLE data slot can never
# address more than 8192 chunks (4GB) of audio, a hard platform ceiling, not
# a tunable. MAX_TRACKS=512's real library (13GB+) blew straight through
# this once total content grew past it (see POCKETPLAYER_NOTES.txt Section 41
# follow-up for the hardware-confirmed root cause). Fixed by splitting audio
# across multiple "Audio Bank N" data slots instead of one big file -
# CHUNKS_PER_BANK leaves an 192-chunk (~100MB) margin below the 8192 wall.
CHUNKS_PER_BANK   = 8000
# First APF data slot id used for audio banks (Bank N -> id AUDIO_BANK_ID_BASE+N).
# Must match audio_streamer.sv's AUDIO_SLOT_ID_BASE parameter. 16/17/19 are
# already taken (old single Test Audio slot - now retired -, Playlist, Track
# Thumbs), so banks start at 20.
AUDIO_BANK_ID_BASE = 20

# Must match playlist_ram.sv MAX_TRACKS parameter.
# playlist.bin is always padded to MAX_TRACKS*128 bytes so the FPGA's
# target_dataslot_length request exactly matches the file size.
MAX_TRACKS           = 512
PLAYLIST_RECORD_SIZE = 128  # 4 header + 64 title + 32 artist + 28 reserved

# Section 35: per-track album art. Must match audio_streamer.sv's
# IMG_BYTES/BG_BYTES parameters and track_thumb_ram.sv's IMG_W/H, BG_W/H.
# track_thumbs.bin is always padded to MAX_TRACKS*PER_TRACK_IMG_BYTES so the
# FPGA's fixed offset*track_idx addressing always lands on a valid slot -
# every track (real or padding) gets a real image, real or fallback, so the
# hardware never needs a "does this track have art" special case.
THUMB_W = 172
THUMB_H = 172
BG_W    = 100  # Section 37 follow-up: 50->100 (visible upscale "color blocks" fix)
BG_H    = 90   # Section 37 follow-up: 45->90
ROW_ICON_W = 30  # Section 39: per-row Library thumbnail cache (matches core_top.v's LIST_ICON_SIZE)
ROW_ICON_H = 30
THUMB_BYTES          = THUMB_W * THUMB_H * 2
BG_BYTES             = BG_W * BG_H * 2
ROW_ICON_BYTES       = ROW_ICON_W * ROW_ICON_H * 2
# Order matters - must match audio_streamer.sv's row_icon_slotoffset (sharp
# thumb, then background, then row icon, back to back per track).
PER_TRACK_IMG_BYTES  = THUMB_BYTES + BG_BYTES + ROW_ICON_BYTES

AUDIO_EXTENSIONS = {'.flac', '.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.wma'}

HERE           = Path(__file__).resolve().parent
# No bundled example track ships in this repo - pass your own file's path
# explicitly in single-track mode, or use --dir/--dirs/--artist-dirs instead.
DEFAULT_INPUT  = HERE.parent / "source_musics" / "some_artist" / "some_album" / "01 - track.flac"
DEFAULT_OUTPUT = HERE.parent / "dist" / "Assets" / "pocketplayer" / "common" / "test_audio.bin"


# ---------------------------------------------------------------------------
# Name helpers
# ---------------------------------------------------------------------------

def _title_from_filename(filepath: Path) -> str:
    """Strip leading track number from filename, return cleaned title string."""
    stem = filepath.stem
    return re.sub(r'^\d+[\s\-_.]+', '', stem).strip()


def _title_from_tags(filepath: Path) -> str:
    """Extract title tag via ffprobe; returns empty string if absent or on error."""
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format_tags=title",
             "-of", "default=noprint_wrappers=1:nokey=1", str(filepath)],
            capture_output=True, text=True, check=True, timeout=10,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def _artist_from_tags(filepath: Path) -> str:
    """Extract artist tag via ffprobe; returns empty string if absent or on error."""
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format_tags=artist",
             "-of", "default=noprint_wrappers=1:nokey=1", str(filepath)],
            capture_output=True, text=True, check=True, timeout=10,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def get_osd_name(filepath: Path, use_tags: bool = False) -> bytes:
    """Return 64-byte uppercase ASCII track title for playlist.bin."""
    title = (_title_from_tags(filepath) if use_tags else "") or _title_from_filename(filepath)
    return title[:64].upper().encode("ascii", errors="replace").ljust(64, b" ")


def get_artist_name(filepath: Path, use_tags: bool = False) -> bytes:
    """Return 32-byte uppercase ASCII artist name for playlist.bin.
    Falls back to grandparent directory name (typical artist folder) if tag absent."""
    artist = (_artist_from_tags(filepath) if use_tags else "") or filepath.parent.parent.name
    return artist[:32].upper().encode("ascii", errors="replace").ljust(32, b" ")


# Legacy alias used by single-track mode below.
def make_track_name(filepath: Path) -> bytes:
    return get_osd_name(filepath, use_tags=False)


# ---------------------------------------------------------------------------
# Section 35: per-track album art (track_thumbs.bin).
#
# Real per-track thumbnails, extracted from each file's embedded cover art
# (ID3 APIC / FLAC picture block - ffmpeg exposes these as an attached
# "video" stream, so a plain -vcodec copy pulls the original image bytes
# straight out, no re-encoding). Tracks without embedded art (or where
# extraction fails for any reason) fall back to the same bundled note-icon
# graphic as before (tools/make_default_thumb.py) - every track always gets
# SOME valid image, so the hardware side never needs a "no art" special case
# (per CLAUDE.md's "let the PC do the work" guidance).
#
# Two images per track, back-to-back, fixed size (so the FPGA can compute a
# track's offset with a plain multiply - no lookup table needed):
#   - sharp 172x172 thumbnail: Library icon, Still Thumbnail, Spinning Vinyl.
#   - small 50x45 "background": a PRE-blurred, PRE-dimmed downscale of the
#     same art, meant for a cheap nearest-neighbor hardware upscale to fill
#     the screen behind Still Thumbnail/Spinning Vinyl (see core_top.v's
#     bg_rgb888) - doing the blur/dimming here means the FPGA only ever does
#     a plain memory read + blit, never actual image processing.
# ---------------------------------------------------------------------------

_default_art_cache = None


def _default_art() -> Image.Image:
    """The bundled note-icon graphic (tools/make_default_thumb.py), used
    whenever a track has no usable embedded cover art. Cached - it's the
    same image for every track that needs it."""
    global _default_art_cache
    if _default_art_cache is None:
        from make_default_thumb import make_image
        _default_art_cache = make_image()
    return _default_art_cache


def extract_cover_art(filepath: Path) -> "Image.Image | None":
    """Extract embedded cover art via ffmpeg. Returns None if the file has
    none, or on any extraction/decode error (caller falls back to the
    default graphic - this is not a fatal condition, most tracks in a real
    library won't have usable embedded art)."""
    with tempfile.TemporaryDirectory() as td:
        out_path = Path(td) / "cover.jpg"
        try:
            subprocess.run(
                ["ffmpeg", "-y", "-v", "error", "-an", "-i", str(filepath),
                 "-vcodec", "copy", "-frames:v", "1", str(out_path)],
                capture_output=True, check=True, timeout=15,
            )
            if out_path.exists() and out_path.stat().st_size > 0:
                return Image.open(out_path).convert("RGB").copy()
        except Exception:
            pass
    return None


def _square_crop(img: Image.Image) -> Image.Image:
    """Center-crop to a square (thumbnail slot is square; source art rarely is)."""
    w, h = img.size
    side = min(w, h)
    left, top = (w - side) // 2, (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def image_to_rgb565_le_bytes(img: Image.Image) -> bytes:
    """Flat RGB565, little-endian, row-major - same packing as
    make_default_thumb.py/ImageViewer's convert_images.py, but derives
    width/height from the image itself instead of a fixed module constant,
    since this is shared between the 172x172 thumbnail and 50x45 background."""
    img = img.convert("RGB")
    w, h = img.size
    pixels = img.tobytes()
    out = bytearray(w * h * 2)
    pack_into = struct.Struct("<H").pack_into
    for i in range(w * h):
        r, g, b = pixels[i * 3], pixels[i * 3 + 1], pixels[i * 3 + 2]
        value = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        pack_into(out, i * 2, value)
    return bytes(out)


def make_track_thumb_bytes(art: "Image.Image | None") -> bytes:
    """Sharp 172x172 thumbnail. `art` is the extracted cover (or None to use
    the default graphic)."""
    img = art if art is not None else _default_art()
    img = _square_crop(img).resize((THUMB_W, THUMB_H), Image.LANCZOS)
    return image_to_rgb565_le_bytes(img)


def make_track_row_icon_bytes(art: "Image.Image | None") -> bytes:
    """Section 39: sharp ROW_ICON_W x ROW_ICON_H icon, pre-scaled here so the
    FPGA can drop it directly into the Library list's per-row icon slot with
    no scaling math at all (unlike the old design, which downscaled from the
    full 172x172 thumbnail on every read, and only for the one
    currently-loaded track). Same sharp/no-blur treatment as
    make_track_thumb_bytes - this is a crisp small icon, not a soft
    backdrop."""
    img = art if art is not None else _default_art()
    img = _square_crop(img).resize((ROW_ICON_W, ROW_ICON_H), Image.LANCZOS)
    return image_to_rgb565_le_bytes(img)


def make_track_bg_bytes(art: "Image.Image | None") -> bytes:
    """Small background: downscaled (cheap blur-by-construction at this
    size), Gaussian-blurred, then dimmed - so it reads as a soft,
    out-of-focus backdrop that doesn't visually compete with the sharp
    thumbnail/vinyl drawn on top of it.

    Section 39 tried adding film-grain noise dithering here to mask the
    FPGA's nearest-neighbor upscale blockiness (see git history) - reverted
    per user feedback ("too colored, looks strange"): applying independent
    Gaussian noise per R/G/B channel is CHROMATIC noise, not the
    luminance-only grain real film has, so it randomly shifted pixel HUE
    (a grey pixel could pick up a random reddish/greenish tint) instead of
    just varying brightness - a real, avoidable bug in that attempt (should
    have applied ONE shared random offset per pixel across all 3 channels,
    not three independent ones), but the user had already moved on to
    wanting a proper bilinear-upscale fix by the time this was reported, so
    it wasn't worth re-attempting a corrected version of the same idea.
    Section 40 instead does real bilinear interpolation on the FPGA side
    (see core_top.v) - this function no longer needs to fight the hardware
    upscale's blockiness at all, so it's back to the plain Section 38
    pipeline."""
    img = art if art is not None else _default_art()
    img = img.resize((BG_W, BG_H), Image.LANCZOS)
    img = img.filter(ImageFilter.GaussianBlur(radius=6))
    img = ImageEnhance.Brightness(img).enhance(0.35)
    return image_to_rgb565_le_bytes(img)


# ---------------------------------------------------------------------------
# playlist.bin entry builder
# ---------------------------------------------------------------------------

def make_playlist_entry(start_chunk: int, chunk_count: int,
                        title_bytes: bytes, artist_bytes: bytes,
                        audio_bank: int = 0) -> bytes:
    """128-byte playlist.bin entry (big-endian, matches APF bridge delivery):
       [  0-  3] start_chunk (uint16, LOCAL to audio_bank's data slot) + chunk_count (uint16)
       [  4- 67] track title (64 ASCII bytes)
       [ 68- 99] artist name (32 ASCII bytes)
       [    100] audio_bank (uint8, 0..15 - which "Audio Bank N" data slot)
       [101-127] reserved zeros

    Section 41 follow-up: start_chunk used to be a global offset into one
    giant audio file; it's now LOCAL to whichever bank audio_bank names (see
    playlist_ram.sv/audio_streamer.sv - a single data slot can't address
    more than 4GB via APF's 32-bit slotoffset field)."""
    assert 0 <= audio_bank <= 15, f"audio_bank {audio_bank} doesn't fit in 4 bits"
    return (struct.pack(">HH", start_chunk, chunk_count) + title_bytes + artist_bytes +
            bytes([audio_bank]) + b"\x00" * 27)


# ---------------------------------------------------------------------------
# Config file updaters
# ---------------------------------------------------------------------------

def update_data_json(sizes: dict, audio_bank_sizes: list) -> None:
    """Update size_exact for the given {slot_id: byte_size} STATIC slots
    (Playlist, Track Thumbs - always present in the checked-in data.json,
    never added/removed here) in both data.json copies (dev + dist), AND
    (re)build the dynamic "Audio Bank N" slot entries from audio_bank_sizes
    (ordered list of each bank file's byte size).

    Section 41 follow-up: the audio bank COUNT varies run to run (depends on
    total library duration), so those entries can't just live pre-written in
    the checked-in data.json like the static slots - this ADDS/REPLACES
    exactly the "Audio Bank N" entries this run actually produced and
    REMOVES any leftover ones from a previous run with a different bank
    count (plus the old single `id: 16` "Test Audio" slot, retired now that
    audio lives in banks - see AUDIO_BANK_ID_BASE's comment)."""
    root = Path(__file__).resolve().parent.parent
    paths = [
        root / "open-fpga-core-template-da3a021" / "data.json",
        root / "dist" / "Cores" / "mhlin.PocketPlayer" / "data.json",
    ]
    updates = {sid: f"0x{size:X}" for sid, size in sizes.items()}
    bank_ids = {AUDIO_BANK_ID_BASE + i for i in range(len(audio_bank_sizes))}
    RETIRED_IDS = {16}  # old single-file "Test Audio" slot
    for path in paths:
        if not path.exists():
            print(f"  Warning: not found, skipping: {path}")
            continue
        config = json.loads(path.read_text(encoding="utf-8"))
        slots = config.setdefault("data", {}).setdefault("data_slots", [])
        found_ids = set()
        kept = []
        for slot in slots:
            sid = slot.get("id")
            if sid in RETIRED_IDS or (sid in bank_ids or (sid is not None and sid >= AUDIO_BANK_ID_BASE)):
                continue  # drop retired slot and ALL old bank entries (rebuilt below)
            if sid in updates:
                slot["size_exact"] = updates[sid]
                found_ids.add(sid)
            kept.append(slot)
        for i, size in enumerate(audio_bank_sizes):
            kept.append({
                "name": f"Audio Bank {i}",
                "id": AUDIO_BANK_ID_BASE + i,
                "required": False,
                "deferload": True,
                "parameters": "0",
                "filename": f"test_audio_bank{i}.bin",
                "extensions": ["bin"],
                "address": f"0x{0x24000000 + i * 0x01000000:X}",
                "size_exact": f"0x{size:X}",
            })
        config["data"]["data_slots"] = kept
        path.write_text(json.dumps(config, indent=4) + "\n", encoding="utf-8")
        print(f"  Updated: {path} ({len(audio_bank_sizes)} audio bank(s))")
        missing = set(updates) - found_ids
        if missing:
            print(f"  Warning: slot(s) {sorted(missing)} not found in {path}")


def update_interact_json() -> None:
    """Remove the Settings-menu "Track" list variable (id=1) from interact.json,
    if present.

    Section 41: this variable's options list held one entry per track (name +
    value = playlist index), written by the bridge at 0xF3000010. It worked
    fine up to 26 tracks, but MAX_TRACKS=512 (only 356 populated) grew it to a
    ~49KB/356-option list and the Pocket's interact.json parser failed outright
    ("Load error in 'interact', General error" - the boot log stops dead right
    after "Opening .../interact.json", before any further core-load steps).
    JSON syntax/encoding were both confirmed fine (valid, pure-ASCII) - this is
    a firmware-side limit on list size we'd never come close to hitting before.

    This picker was always a Settings-menu convenience, entirely separate from
    the in-core Library tab (driven by D-pad reads in core_top.v, independent
    of interact.json) - dropping it has zero effect on the actual player.
    Removing the variable outright (not just emptying its options) restores
    interact.json to the same shape it had before this feature ever existed
    (Sections <29: `{"interact": {"variables": [], "messages": []}}`).
    """
    root = Path(__file__).resolve().parent.parent
    paths = [
        root / "open-fpga-core-template-da3a021" / "interact.json",
        root / "dist" / "Cores" / "mhlin.PocketPlayer" / "interact.json",
    ]
    for path in paths:
        if not path.exists():
            print(f"  Warning: not found, skipping: {path}")
            continue
        config = json.loads(path.read_text(encoding="utf-8"))
        variables = config.get("interact", {}).get("variables", [])
        before = len(variables)
        config["interact"]["variables"] = [v for v in variables if v.get("id") != 1]
        if len(config["interact"]["variables"]) != before:
            path.write_text(json.dumps(config, indent=4) + "\n", encoding="utf-8")
            print(f"  Updated: {path} (removed Track variable)")
        else:
            print(f"  No Track variable (id=1) found in {path} - nothing to do")


# ---------------------------------------------------------------------------
# Core conversion logic
# ---------------------------------------------------------------------------

def decode_and_pad(input_path: Path) -> bytes:
    """Decode input to 48kHz s16le stereo PCM, pad UP to next CHUNK_BYTES boundary."""
    cmd = [
        "ffmpeg", "-y", "-v", "error",
        "-i", str(input_path),
        "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", str(CHANNELS),
        "-",
    ]
    print(f"  Decoding: {input_path.name}")
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True)
    except FileNotFoundError:
        sys.exit("ffmpeg not found on PATH")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ffmpeg failed with exit code {exc.returncode}")

    pcm = result.stdout
    remainder = len(pcm) % CHUNK_BYTES
    if remainder:
        pcm = pcm + b"\x00" * (CHUNK_BYTES - remainder)
    return pcm


def run_concat(inputs: list, output: Path, use_tags: bool) -> int:
    """Decode/pad inputs, write one or more test_audio_bankN.bin files (split
    per CHUNKS_PER_BANK - see its comment) + playlist.bin into output's
    directory, update configs."""
    if len(inputs) > MAX_TRACKS:
        print(f"Warning: {len(inputs)} files found, MAX_TRACKS={MAX_TRACKS} — "
              f"taking first {MAX_TRACKS} only.")
        inputs = inputs[:MAX_TRACKS]

    print(f"Processing {len(inputs)} track(s) -> {output}")
    blobs = [decode_and_pad(p) for p in inputs]

    print()
    print("Per-track parameters:")
    playlist_data = b""
    thumbs_data   = b""
    art_hits     = 0
    # Section 41 follow-up: assign each track to an "Audio Bank N" instead of
    # one giant concatenated file (see CHUNKS_PER_BANK's comment for why) -
    # a track never spans two banks; bank_chunks_used tracks how full the
    # CURRENT bank is, local_start_chunk is this track's offset WITHIN it.
    bank_buffers    = [b""]   # bank_buffers[i] accumulates bank i's raw PCM
    bank_idx        = 0
    bank_chunks_used = 0
    for i, (p, blob) in enumerate(zip(inputs, blobs)):
        n = len(blob) // CHUNK_BYTES
        if bank_chunks_used > 0 and bank_chunks_used + n > CHUNKS_PER_BANK:
            bank_idx += 1
            bank_chunks_used = 0
            bank_buffers.append(b"")
        if n > CHUNKS_PER_BANK:
            print(f"  Warning: track {i} alone is {n} chunks, over the "
                  f"{CHUNKS_PER_BANK}-chunk bank budget - giving it its own "
                  f"oversized bank (still must stay under the hard 8192-chunk "
                  f"platform ceiling).")
        local_start_chunk = bank_chunks_used
        bank_buffers[bank_idx] += blob
        bank_chunks_used += n

        dur          = (n * CHUNK_BYTES // BYTES_PER_FRAME) / SAMPLE_RATE
        title_bytes  = get_osd_name(p, use_tags=use_tags)
        artist_bytes = get_artist_name(p, use_tags=use_tags)
        title_str    = title_bytes[:32].decode("ascii").rstrip()
        artist_str   = artist_bytes.decode("ascii").rstrip()
        art          = extract_cover_art(p)
        if art is not None:
            art_hits += 1
        print(f"  Track {i}: bank={bank_idx}, start={local_start_chunk}, chunks={n}, {dur:.2f}s")
        print(f"    title='{title_str}'  artist='{artist_str}'"
              f"  art={'embedded' if art is not None else 'default'}")
        playlist_data += make_playlist_entry(local_start_chunk, n, title_bytes, artist_bytes,
                                              audio_bank=bank_idx)
        thumbs_data   += (make_track_thumb_bytes(art) + make_track_bg_bytes(art) +
                           make_track_row_icon_bytes(art))

    # Pad playlist to MAX_TRACKS records so FPGA's target_dataslot_length matches exactly.
    playlist_data += b"\x00" * (MAX_TRACKS * PLAYLIST_RECORD_SIZE - len(playlist_data))
    # Pad track_thumbs.bin the same way, but with REAL (default) images, not
    # zeros - track_thumb_ram's fixed track_idx*PER_TRACK_IMG_BYTES addressing
    # means any slot could in principle be read, so every slot must hold a
    # valid image, not just the populated ones.
    for _ in range(MAX_TRACKS - len(inputs)):
        thumbs_data += (make_track_thumb_bytes(None) + make_track_bg_bytes(None) +
                         make_track_row_icon_bytes(None))

    total_bytes  = sum(len(b) for b in bank_buffers)
    total_chunks = total_bytes // CHUNK_BYTES
    print()
    print(f"Total: {total_chunks} chunks, {total_bytes} bytes ({total_bytes/1024/1024:.1f} MB) "
          f"across {len(bank_buffers)} audio bank(s)")
    print(f"Album art: {art_hits}/{len(inputs)} track(s) had embedded cover art; "
          f"the rest use the default graphic.")

    output.parent.mkdir(parents=True, exist_ok=True)
    for i, bank_bytes in enumerate(bank_buffers):
        bank_path = output.parent / f"test_audio_bank{i}.bin"
        bank_path.write_bytes(bank_bytes)
        print(f"Wrote {len(bank_bytes)} bytes -> {bank_path}")

    playlist_path = output.parent / "playlist.bin"
    playlist_path.write_bytes(playlist_data)
    print(f"Wrote {len(playlist_data)} bytes -> {playlist_path}  (padded to {MAX_TRACKS} slots)")

    thumbs_path = output.parent / "track_thumbs.bin"
    thumbs_path.write_bytes(thumbs_data)
    print(f"Wrote {len(thumbs_data)} bytes -> {thumbs_path}  (padded to {MAX_TRACKS} slots)")

    print()
    print("Updating data.json (audio banks, slot 17/19 size_exact):")
    update_data_json({17: len(playlist_data), 19: len(thumbs_data)},
                      [len(b) for b in bank_buffers])

    print()
    print("Updating interact.json (removing Track picker - see Section 41):")
    update_interact_json()

    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # --- multi-track modes ---
    parser.add_argument(
        "--dir", metavar="DIRECTORY", type=Path,
        help=f"Directory mode: auto-discover audio files in DIRECTORY (sorted by "
             f"filename), process first {MAX_TRACKS}. "
             f"Supported: {', '.join(sorted(AUDIO_EXTENSIONS))}",
    )
    parser.add_argument(
        "--dirs", metavar="DIRECTORY", type=Path, nargs="+",
        help=f"Multi-directory mode: combine audio files from multiple "
             f"directories (each sorted by filename, directories processed in "
             f"the order given), capped at {MAX_TRACKS} tracks total.",
    )
    parser.add_argument(
        "--artist-dirs", metavar="DIRECTORY", type=Path, nargs="+",
        help="Multi-artist mode: each DIRECTORY is an artist folder containing "
             "one subdirectory per album. Expands each artist directory into "
             "its immediate album subdirectories (sorted by name) and combines "
             "them exactly like --dirs, in the order given - saves listing "
             f"every album directory by hand. Capped at {MAX_TRACKS} tracks "
             "total across everything.",
    )
    parser.add_argument(
        "--concat", metavar="OUTPUT",
        help="Concat mode: write merged output to OUTPUT. "
             "Input files follow as positional arguments.",
    )
    parser.add_argument(
        "--use-tags", action="store_true",
        help="Read track names from audio metadata title tag (ffprobe). "
             "Falls back to filename if tag is absent. Applies to --dir/--concat.",
    )
    parser.add_argument(
        "--output", metavar="PATH", type=Path, default=DEFAULT_OUTPUT,
        help=f"Output path for test_audio.bin in --dir mode "
             f"(default: {DEFAULT_OUTPUT})",
    )

    # --- single-track / positional args ---
    parser.add_argument(
        "input_file", type=Path, nargs="?", default=DEFAULT_INPUT,
        help=f"source audio file (single-track mode; default: {DEFAULT_INPUT.name})",
    )
    parser.add_argument(
        "output_file", type=Path, nargs="?", default=DEFAULT_OUTPUT,
        help=f"output PCM file (single-track mode; default: {DEFAULT_OUTPUT.name})",
    )
    parser.add_argument(
        "--seconds", type=float, default=None,
        help="single-track: clip to N seconds "
             f"(default: {NUM_SAMPLES} frames = {NUM_SAMPLES / SAMPLE_RATE:.3f}s)",
    )
    parser.add_argument(
        "--full", action="store_true",
        help="single-track: encode full track, pad to CHUNK_BYTES multiple, "
             "print NUM_CHUNKS. Mutually exclusive with --seconds.",
    )
    parser.add_argument("extra_inputs", nargs="*", type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()

    # ------------------------------------------------------------ --artist-dirs
    # Expand each artist directory into its sorted album subdirectories, then
    # feed the result through the same combining logic as --dirs below - no
    # separate code path needed for the actual scan/concat/convert work.
    if args.artist_dirs:
        expanded = []
        for artist_dir in args.artist_dirs:
            if not artist_dir.is_dir():
                parser.error(f"not a directory: {artist_dir}")
            albums = sorted(p for p in artist_dir.iterdir() if p.is_dir())
            if not albums:
                parser.error(f"no album subdirectories found in {artist_dir}")
            print(f"{artist_dir.name}: {len(albums)} album(s)")
            expanded.extend(albums)
        args.dirs = expanded

    # ------------------------------------------------------------------ --dir
    if args.dir:
        directory = args.dir
        if not directory.is_dir():
            parser.error(f"not a directory: {directory}")
        audio_files = sorted(
            p for p in directory.iterdir()
            if p.is_file() and p.suffix.lower() in AUDIO_EXTENSIONS
        )
        if not audio_files:
            parser.error(
                f"no audio files found in {directory} "
                f"(supported: {', '.join(sorted(AUDIO_EXTENSIONS))})"
            )
        print(f"Found {len(audio_files)} audio file(s) in {directory.name}")
        return run_concat(audio_files, args.output, args.use_tags)

    # ----------------------------------------------------------------- --dirs
    if args.dirs:
        audio_files = []
        for directory in args.dirs:
            if not directory.is_dir():
                parser.error(f"not a directory: {directory}")
            found = sorted(
                p for p in directory.iterdir()
                if p.is_file() and p.suffix.lower() in AUDIO_EXTENSIONS
            )
            print(f"Found {len(found)} audio file(s) in {directory.name}")
            audio_files.extend(found)
        if not audio_files:
            parser.error(
                f"no audio files found in any of the given directories "
                f"(supported: {', '.join(sorted(AUDIO_EXTENSIONS))})"
            )
        print(f"Total: {len(audio_files)} audio file(s) across {len(args.dirs)} directories")
        return run_concat(audio_files, args.output, args.use_tags)

    # ------------------------------------------------------------------ concat
    if args.concat:
        output = Path(args.concat)
        inputs = []
        if args.input_file != DEFAULT_INPUT or args.input_file.is_file():
            inputs.append(args.input_file)
        if args.output_file != DEFAULT_OUTPUT or args.output_file.is_file():
            inputs.append(args.output_file)
        inputs.extend(args.extra_inputs)
        if not inputs:
            parser.error("--concat requires at least one input file")
        for p in inputs:
            if not p.is_file():
                parser.error(f"input file not found: {p}")
        return run_concat(inputs, output, args.use_tags)

    # ----------------------------------------------------------- single-track
    if args.full and args.seconds is not None:
        parser.error("--full and --seconds are mutually exclusive")
    if not args.input_file.is_file():
        parser.error(f"input file not found: {args.input_file}")

    cmd = [
        "ffmpeg", "-y", "-v", "error",
        "-i", str(args.input_file),
        "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", str(CHANNELS),
        "-",
    ]
    print(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True)
    except FileNotFoundError:
        sys.exit("ffmpeg not found on PATH")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ffmpeg failed with exit code {exc.returncode}")

    pcm = result.stdout

    if args.full:
        remainder = len(pcm) % CHUNK_BYTES
        if remainder:
            pcm = pcm + b"\x00" * (CHUNK_BYTES - remainder)
        num_chunks = len(pcm) // CHUNK_BYTES
        num_frames = len(pcm) // BYTES_PER_FRAME
        print(f"NUM_CHUNKS = {num_chunks}  "
              f"({len(pcm)} bytes = {num_chunks} * 0x{CHUNK_BYTES:X}, "
              f"{num_frames / SAMPLE_RATE:.3f}s)")
        print(f"Plug NUM_CHUNKS={num_chunks} into audio_streamer parameter in core_top.v "
              f"and update data.json size_exact to 0x{len(pcm):X}")
    else:
        num_samples = NUM_SAMPLES if args.seconds is None else round(SAMPLE_RATE * args.seconds)
        out_bytes   = num_samples * BYTES_PER_FRAME
        if len(pcm) >= out_bytes:
            pcm = pcm[:out_bytes]
        else:
            pcm = pcm + b"\x00" * (out_bytes - len(pcm))

    args.output_file.parent.mkdir(parents=True, exist_ok=True)
    args.output_file.write_bytes(pcm)

    if args.full:
        print(f"Wrote {len(pcm)} bytes to {args.output_file}")
    else:
        nf = len(pcm) // BYTES_PER_FRAME
        print(f"Wrote {len(pcm)} bytes ({nf} frames @ {SAMPLE_RATE}Hz, "
              f"{nf / SAMPLE_RATE:.3f}s) to {args.output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
