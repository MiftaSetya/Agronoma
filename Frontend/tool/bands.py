"""Mengukur letak pita (band) elemen pada gambar layar tanpa melihatnya.

Memindai setiap baris lalu mencari baris yang punya piksel "tinta" (bukan latar);
baris ber-urutan digabung jadi pita dan dilaporkan batas atas/bawahnya. Gunanya
membandingkan posisi elemen antara tangkapan emulator dan frame Figma sampai
beberapa piksel.

Pemakaian:
    python tool/bands.py <nama> [--th 200] [--x0 14] [--x1 260] [--gap 2]

--th  : ambang kecerahan; piksel di bawah ini dianggap tinta (default 200)
--x0  : kolom awal yang dipindai (default 14)
--x1  : kolom akhir yang dipindai (default 260)
--gap : jumlah baris kosong yang memisahkan dua pita (default 2)
"""

from __future__ import annotations

import os
import sys

from PIL import Image

REF = os.path.join(os.environ["TEMP"], "agro-ref")
CANVAS = (440, 956)


def bands(im: Image.Image, th: int, x0: int, x1: int, gap: int):
    out = []
    cur = None
    blank = 0
    for y in range(im.size[1]):
        count = 0
        for x in range(x0, x1):
            r, g, b = im.getpixel((x, y))
            if min(r, g, b) < th:
                count += 1
        if count == 0:
            blank += 1
            if cur is not None and blank > gap:
                out.append(cur)
                cur = None
            continue
        blank = 0
        if cur is None:
            cur = [y, y]
        else:
            cur[1] = y
    if cur is not None:
        out.append(cur)
    return out


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        raise SystemExit(2)

    name = args[0]

    def opt(flag: str, default: int) -> int:
        return int(args[args.index(flag) + 1]) if flag in args else default

    th = opt("--th", 200)
    x0 = opt("--x0", 14)
    x1 = opt("--x1", 260)
    gap = opt("--gap", 2)

    for label, prefix in (("FIGMA", ""), ("EMULATOR", "run-")):
        path = os.path.join(REF, f"{prefix}{name}.png")
        im = Image.open(path).convert("RGB")
        if im.size != CANVAS:
            im = im.resize(CANVAS, Image.LANCZOS)
        print(f"== {label} ==")
        prev = None
        for b in bands(im, th, x0, x1, gap):
            delta = "" if prev is None else f"  (+{b[0] - prev})"
            print(f"   {b[0]:>3}-{b[1]:<3} h={b[1] - b[0] + 1:<3}{delta}")
            prev = b[0]
        print()


if __name__ == "__main__":
    main()
