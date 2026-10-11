"""Deteksi garis tepi kartu di tangkapan asli dengan uji "run panjang".

Satu baris dianggap garis tepi kartu kalau ada >=1000 piksel berturut-turut
(x=60..1260, dengan toleransi 3 baris di tepi kiri/kanan) yang berwarna
#e7e9e7 +-10. Cara ini tahan terhadap anti-aliasing hasil pengecilan.
"""

from __future__ import annotations

import os

from PIL import Image

REF = os.path.join(os.environ["TEMP"], "agro-ref")
BORDER = (0xE7, 0xE9, 0xE7)
S = 3.0


def is_border(px: tuple[int, int, int]) -> bool:
    return all(abs(px[i] - BORDER[i]) <= 10 for i in range(3))


def main() -> None:
    out = []
    for label, path, x_lo, x_hi in (
        ("FIGMA", "home.png", 20, 420),
        ("EMULATOR", "run-home.png", 60, 1260),
    ):
        im = Image.open(os.path.join(REF, path)).convert("RGB")
        scale = im.size[1] / 956.0
        rows = []
        for y in range(im.size[1]):
            run = best = 0
            for x in range(x_lo, x_hi):
                if is_border(im.getpixel((x, y))):
                    run += 1
                    best = max(best, run)
                else:
                    run = 0
            if best >= (x_hi - x_lo) * 0.75:
                rows.append(round(y / scale, 2))
        # Gabungkan baris berurutan (tebal border 1 logical px = `scale` baris).
        groups = []
        for y in rows:
            if groups and y - groups[-1][-1] <= 1.5 / scale + 0.01:
                groups[-1].append(y)
            else:
                groups.append([y])
        out.append(f"-- {label} (skala {scale:.1f}): {len(groups)} garis tepi")
        for i, g in enumerate(groups):
            note = "" if i == 0 else f"  (+{(g[0] - groups[i-1][0]):.2f})"
            out.append(f"   y={g[0]:7.2f}..{g[-1]:7.2f}{note}")
        out.append("")

    open(os.path.join("build", "edges.txt"), "w", encoding="utf-8").write(
        "\n".join(out) + "\n"
    )


if __name__ == "__main__":
    main()
