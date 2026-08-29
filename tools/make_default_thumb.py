#!/usr/bin/env python3
"""Generate PocketPlayer's default (fallback) album-art graphic - the image
shown for any track without usable embedded cover art.

Section 35: real per-track album art now exists (tools/convert_audio.py
extracts embedded cover art per track into track_thumbs.bin) - this module's
make_image()/to_rgb565_le_bytes() are imported directly by convert_audio.py
as the fallback source for tracks with no embedded art. There is no longer a
standalone "Default Thumbnail" data slot (retired along with thumb_ram.sv;
see track_thumb_ram.sv) - running this file directly still works and is
useful for previewing the fallback graphic on its own, but its output is no
longer deployed/read by the core.

Section 43: replaced the beamed-notes glyph with the new PocketPlayer project
icon (plans/PocketPlayer_icon.drawio, exported to
plans/PocketPlayer_icon.drawio.png) - same icon used for the whole project
(see tools/make_icon.py for icon.bin/the Platform image). Just a high-quality
resize of the source PNG down to WIDTHxHEIGHT rather than redrawing the
geometry in PIL - the exported PNG IS the exact design, no approximation
needed. History of the earlier designs this replaces (Section 32's single
eighth-note, Section 35 follow-up's beamed-notes pair) kept below for
reference only - make_image() no longer draws either.
"""

import argparse
import struct
import sys
from pathlib import Path

from PIL import Image

WIDTH = 172
HEIGHT = 172

ICON_SOURCE = Path(__file__).resolve().parent.parent / "plans" / "PocketPlayer_icon.drawio.png"

DEFAULT_OUTPUT = Path(__file__).resolve().parent.parent / "dist" / "Assets" / "pocketplayer" / "common" / "default_thumb.bin"


def make_image() -> Image.Image:
    src = Image.open(ICON_SOURCE).convert("RGB")
    return src.resize((WIDTH, HEIGHT), Image.LANCZOS)


def to_rgb565_le_bytes(img: Image.Image) -> bytes:
    """Same packing as ImageViewer/tools/convert_images.py's to_rgb565_bytes
    (byte_order="little"): 2 bytes/pixel, row-major, little-endian uint16."""
    pixels = img.tobytes()  # 3 bytes/pixel, RGB
    out = bytearray(WIDTH * HEIGHT * 2)
    pack_into = struct.Struct("<H").pack_into
    for i in range(WIDTH * HEIGHT):
        r, g, b = pixels[i * 3], pixels[i * 3 + 1], pixels[i * 3 + 2]
        value = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        pack_into(out, i * 2, value)
    return bytes(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    img = make_image()
    data = to_rgb565_le_bytes(img)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    print(f"Wrote {len(data)} bytes ({WIDTH}x{HEIGHT} RGB565) to {args.output}")
    if len(data) != 0xE720:
        print(f"WARNING: expected 0xE720 (59168) bytes to match data.json size_exact, got {hex(len(data))}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
