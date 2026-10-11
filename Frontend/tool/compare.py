"""Membandingkan tangkapan layar emulator dengan frame Figma.

Kanvas Figma 440x956 terdiri dari tiga bagian:

    baris   0.. 63   Status Bar - iPhone   (64px)
    baris  64..931   isi layar (Frame 65)  (868px)
    baris 932..955   Bottom/Home Bar       (24px)

Emulator Android tidak punya status bar setinggi itu (52px di Pixel 9 Pro),
sehingga isi layar yang sama akan berada di baris yang berbeda. Karena itu
perbandingan dilakukan pada **area isi** kedua gambar, bukan pada gambar utuh:
dengan begitu selisihnya benar-benar mencerminkan perbedaan layout, bukan
perbedaan tinggi status bar.

Emulator disetel ke 440x956 logical (lihat docs/testing.md), jadi rasio piksel
3x menghasilkan 1320x2868 dan setelah diperkecil tangkapannya seukuran kanvas
Figma.

Pemakaian:
    python tool/compare.py <nama> [<nama2> ...] [--run-top 52]

Untuk setiap nama dibutuhkan dua berkas:
    %TEMP%\\agro-ref\\<nama>.png        -> referensi dari Figma
    %TEMP%\\agro-ref\\run-<nama>.png    -> tangkapan emulator
Hasil: %TEMP%\\agro-ref\\cmp-<nama>.png (kiri: Figma, kanan: emulator)
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageChops, ImageDraw

REF = os.path.join(os.environ["TEMP"], "agro-ref")
CANVAS = (440, 956)

# Geometri kanvas Figma.
FIGMA_STATUS_BAR = 64
FIGMA_HOME_BAR = 24

# Tinggi status bar Android pada emulator uji. Bisa ditimpa dengan --run-top.
DEFAULT_RUN_TOP = 52

GAP = 16
LABEL_H = 28


def load(path: str) -> Image.Image:
    """Buka gambar dan perkecil ke ukuran kanvas Figma (440x956)."""
    im = Image.open(path).convert("RGB")
    if im.size != CANVAS:
        im = im.resize(CANVAS, Image.LANCZOS)
    return im


def content(im: Image.Image, top: int, bottom: int) -> Image.Image:
    """Ambil area isi layar saja, buang status bar dan home bar."""
    return im.crop((0, top, CANVAS[0], CANVAS[1] - bottom))


def diff_score(a: Image.Image, b: Image.Image) -> float:
    """Rata-rata selisih absolut 0-255; makin kecil makin mirip."""
    diff = ImageChops.difference(a, b).convert("L")
    hist = diff.histogram()
    total = sum(v * i for i, v in enumerate(hist))
    return total / (a.size[0] * a.size[1])


def main(names: list[str], run_top: int) -> None:
    for name in names:
        ref_path = os.path.join(REF, f"{name}.png")
        run_path = os.path.join(REF, f"run-{name}.png")
        if not os.path.exists(ref_path) or not os.path.exists(run_path):
            print(f"LEWAT {name}: berkas tidak lengkap")
            continue

        ref = content(load(ref_path), FIGMA_STATUS_BAR, FIGMA_HOME_BAR)
        run = content(load(run_path), run_top, FIGMA_HOME_BAR)

        # Area isi Figma dan emulator sama-sama 868px, jadi bisa ditempel
        # berdampingan tanpa penyesuaian tinggi.
        height = ref.size[1]
        canvas = Image.new("RGB", (CANVAS[0] * 2 + GAP, height + LABEL_H), "white")
        canvas.paste(ref, (0, LABEL_H))
        canvas.paste(run, (CANVAS[0] + GAP, LABEL_H))

        draw = ImageDraw.Draw(canvas)
        draw.text((4, 8), f"FIGMA  {name}", fill="black")
        draw.text((CANVAS[0] + GAP + 4, 8), "EMULATOR", fill="black")
        draw.line(
            [(CANVAS[0] + GAP // 2, 0), (CANVAS[0] + GAP // 2, canvas.height)],
            fill=(200, 200, 200),
        )

        out = os.path.join(REF, f"cmp-{name}.png")
        canvas.save(out)
        print(f"{name}: selisih rata-rata {diff_score(ref, run):.1f}/255 -> {out}")


if __name__ == "__main__":
    argv = sys.argv[1:]
    top = DEFAULT_RUN_TOP
    if "--run-top" in argv:
        i = argv.index("--run-top")
        top = int(argv[i + 1])
        del argv[i : i + 2]

    if not argv:
        print("Pemakaian: python tool/compare.py <nama> [<nama> ...] [--run-top N]")
        raise SystemExit(2)
    main(argv, top)
