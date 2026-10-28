#!/usr/bin/env python3
"""Placeholder branding in the app's primary color (pure Python, no deps).

Writes to assets/branding/:
  icon.png             1024 app icon: primary background + white mark
  icon_foreground.png  1024 adaptive-icon foreground (mark only, transparent)
  icon_dev.png / icon_staging.png  flavor icons with a colored band
  splash.png           768 splash mark (white, transparent)
Replace them with the icon from Claude Design (same names/sizes), then
regenerate (docs/design.md).

usage: make_branding.py <out_dir> <#RRGGBB>
"""
import os
import struct
import sys
import zlib


def png(path, width, height, pixel):
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row.extend(pixel(x, y))
        rows.append(bytes(row))
    raw = zlib.compress(b"".join(rows), 9)

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", raw))
        f.write(chunk(b"IEND", b""))


def mark(x, y, size, scale):
    """A ring with a dot: simple, readable at any size."""
    c = size / 2
    d = ((x + 0.5 - c) ** 2 + (y + 0.5 - c) ** 2) ** 0.5 / (size * scale / 2)
    return (0.62 <= d <= 0.86) or d <= 0.28


def main():
    out, hex_color = sys.argv[1], sys.argv[2].lstrip("#")
    os.makedirs(out, exist_ok=True)
    primary = tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    white = (255, 255, 255)
    n = 1024

    def icon(band=None):
        def pixel(x, y):
            if band and y > n * 0.78:
                return band + (255,)
            return (white if mark(x, y, n, 0.62) else primary) + (255,)
        return pixel

    png(os.path.join(out, "icon.png"), n, n, icon())
    png(os.path.join(out, "icon_dev.png"), n, n, icon((242, 153, 0)))
    png(os.path.join(out, "icon_staging.png"), n, n, icon((52, 120, 246)))
    png(os.path.join(out, "icon_foreground.png"), n, n,
        lambda x, y: white + (255,) if mark(x, y, n, 0.42) else (0, 0, 0, 0))
    s = 768
    png(os.path.join(out, "splash.png"), s, s,
        lambda x, y: white + (255,) if mark(x, y, s, 0.6) else (0, 0, 0, 0))


if __name__ == "__main__":
    main()
