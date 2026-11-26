#!/usr/bin/env python3
"""生成 1024pt 应用图标：暗色底 + 黑胶唱片 + 米色标签。纯标准库，无依赖。"""

import math
import os
import struct
import zlib

SIZE = 1024
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "VinylPlayer", "Resources", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png",
)


def smoothstep(edge0, edge1, value):
    if edge1 <= edge0:
        return 0.0 if value < edge0 else 1.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def clamp255(v):
    return 0 if v < 0 else (255 if v > 255 else int(v))


def render():
    pixels = bytearray(SIZE * SIZE * 3)
    c = SIZE / 2.0
    disc_r = SIZE * 0.395
    label_r = SIZE * 0.135
    hole_r = SIZE * 0.016

    for y in range(SIZE):
        for x in range(SIZE):
            dx = x - c
            dy = y - c
            d = math.hypot(dx, dy)

            t = min(1.0, d / (SIZE * 0.75))
            bg = 34.0 * (1.0 - t) + 9.0 * t
            streak = math.exp(-(((x * 0.6 + y * 0.8) / SIZE - 0.55) ** 2) / 0.02) * 7.0
            r = bg + streak
            g = bg * 0.98 + streak
            b = bg * 0.94 + streak

            if d <= disc_r:
                groove = 0.5 + 0.5 * math.cos(d * 0.42)
                base = 13.0 + groove * 9.0
                base += 8.0 * smoothstep(disc_r * 0.75, label_r, disc_r - d)
                r, g, b = base, base, base * 1.04

                ang = math.atan2(dy, dx)
                sheen = math.exp(-((ang + 2.2) ** 2) / 0.12) * smoothstep(label_r, disc_r * 0.55, d) * 26.0
                r += sheen
                g += sheen
                b += sheen

            if d <= label_r:
                lg = 232.0 - 18.0 * (d / label_r)
                r, g, b = lg, lg * 0.935, lg * 0.80
                ring = smoothstep(label_r - 2.0, label_r, d)
                r *= (1.0 - 0.12 * ring)
                g *= (1.0 - 0.12 * ring)
                b *= (1.0 - 0.12 * ring)

            if d <= hole_r:
                r = g = b = 12.0

            i = (y * SIZE + x) * 3
            pixels[i] = clamp255(r)
            pixels[i + 1] = clamp255(g)
            pixels[i + 2] = clamp255(b)

    return pixels


def write_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 3
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride:(y + 1) * stride])

    def chunk(tag, payload):
        checksum = zlib.crc32(tag + payload) & 0xFFFFFFFF
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", checksum))

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(bytes([137, 80, 78, 71, 13, 10, 26, 10]))
        handle.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


def main():
    if os.path.exists(OUT) and os.path.getsize(OUT) > 1000:
        print("icon already in repo, skip:", OUT)
        return
    pixels = render()
    write_png(OUT, SIZE, SIZE, pixels)
    print("icon written:", OUT, os.path.getsize(OUT), "bytes")


if __name__ == "__main__":
    main()
