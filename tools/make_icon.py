#!/usr/bin/env python3
"""Generate PocketPlayer's core-selection icon.bin from the project icon.

Section 43: icon.bin is the small (36x36 RGB565, 2592 bytes, matching
POCKET_CORE_NOTES.txt's documented format) icon shown in openFPGA's core
list. Previously the stock open-fpga-core-template default; now the user's
own PocketPlayer icon (plans/PocketPlayer_icon.drawio) - the ROUNDED export
is used here (plans/PocketPlayer_icon_rounded.drawio.png) since this is
displayed as a rounded-corner app icon, unlike the plain-square default
thumbnail (tools/make_default_thumb.py uses the non-rounded export instead,
since track art there is always a plain rectangle).

Output format matches ImageViewer/tools/convert_images.py exactly: flat
RGB565, little-endian, row-major (pixel i = y*WIDTH+x), no header.

Usage: py tools/make_icon.py [output_path]
"""

import argparse
import struct
import sys
from pathlib import Path

from PIL import Image

WIDTH = 36
HEIGHT = 36
EXPECTED_BYTES = WIDTH * HEIGHT * 2  # 2592

ICON_SOURCE = Path(__file__).resolve().parent.parent / "plans" / "PocketPlayer_icon_rounded.drawio.png"
DEFAULT_OUTPUT = Path(__file__).resolve().parent.parent / "dist" / "Cores" / "mhlin.PocketPlayer" / "icon.bin"


def make_image() -> Image.Image:
    src = Image.open(ICON_SOURCE).convert("RGB")
    return src.resize((WIDTH, HEIGHT), Image.LANCZOS)


def to_rgb565_le_bytes(img: Image.Image) -> bytes:
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
    if len(data) != EXPECTED_BYTES:
        print(f"WARNING: expected {EXPECTED_BYTES} bytes, got {len(data)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
