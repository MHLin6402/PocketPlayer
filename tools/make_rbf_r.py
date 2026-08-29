#!/usr/bin/env python3
"""
Convert a Quartus .rbf bitstream to the .rbf_r format the Analogue Pocket
expects (every byte's bits reversed, e.g. 0x6a <-> 0x56).

Usage:
    python make_rbf_r.py <input.rbf> [output.rbf_r]

If output is omitted, writes "bitstream.rbf_r" next to the input file.
"""

import sys
from pathlib import Path


def bit_reverse_table() -> bytes:
    table = bytearray(256)
    for x in range(256):
        r = 0
        for i in range(8):
            r |= ((x >> i) & 1) << (7 - i)
        table[x] = r
    return bytes(table)


def main() -> int:
    if not 2 <= len(sys.argv) <= 3:
        print(__doc__)
        return 1

    src = Path(sys.argv[1])
    dst = Path(sys.argv[2]) if len(sys.argv) == 3 else src.parent / "bitstream.rbf_r"

    table = bit_reverse_table()
    data = src.read_bytes()
    dst.write_bytes(data.translate(table))
    print(f"Wrote {dst} ({len(data)} bytes, bit-reversed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
