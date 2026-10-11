"""Memotong gambar perbandingan menjadi beberapa bagian agar mudah dilihat.

`cmp-<nama>.png` berisi dua kanvas 440x956 berdampingan. Di layar biasa gambar
itu tampil terlalu kecil untuk melihat selisih beberapa piksel. Skrip ini
memotongnya secara mendatar menjadi beberapa bagian, lalu menyimpannya sebagai
`cmp-<nama>-<bagian>.png` sehingga tiap bagian tampil lebih besar.

Pemakaian:
    python tool/crop_cmp.py <nama> [--parts 3]
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageDraw

REF = os.path.join(os.environ["TEMP"], "agro-ref")


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print("Pemakaian: python tool/crop_cmp.py <nama> [--parts 3]")
        raise SystemExit(2)

    name = args[0]
    parts = 3
    if "--parts" in args:
        parts = int(args[args.index("--parts") + 1])

    src = os.path.join(REF, f"cmp-{name}.png")
    im = Image.open(src)
    # Buang baris label di atas.
    im = im.crop((0, 28, im.width, im.height))

    step = im.height // parts
    for i in range(parts):
        top = i * step
        bottom = im.height if i == parts - 1 else (i + 1) * step
        tile = im.crop((0, top, im.width, bottom))
        tile = tile.resize((tile.width * 2, tile.height * 2), Image.LANCZOS)
        draw = ImageDraw.Draw(tile)
        draw.text((6, 4), f"rows {top}-{bottom}", fill="red")
        out = os.path.join(REF, f"cmp-{name}-{i}.png")
        tile.save(out)
        print(f"{i}: baris {top}..{bottom} -> {out}")


if __name__ == "__main__":
    main()
