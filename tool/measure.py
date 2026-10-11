"""Mengukur kotak elemen pada gambar layar tanpa melihatnya.

Menghitung, untuk setiap baris, berapa piksel yang bukan latar putih; lalu
mengelompokkan baris-baris berurutan menjadi "pita" dan melaporkan kotak
pembatasnya (baris atas/bawah, kolom kiri/kanan). Dengan begitu posisi field,
tombol, dan judul bisa dibandingkan dengan frame Figma sampai beberapa piksel.

Semua baris dinomori relatif terhadap **area isi layar** (lihat tool/compare.py),
jadi angka untuk Figma dan emulator langsung bisa dibandingkan.

Pemakaian:
    python tool/measure.py <nama> [--gap 3]

--gap adalah jumlah baris kosong yang memisahkan dua pita (default 3).
"""

from __future__ import annotations

import os
import sys

from PIL import Image

# Konsol Windows default-nya cp1252 dan akan gagal menulis karakter kotak yang
# dipakai untuk memisahkan bagian keluaran.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

REF = os.path.join(os.environ["TEMP"], "agro-ref")
CANVAS = (440, 956)
STATUS_BAR = 64
HOME_BAR = 24

# Ambang "bukan latar": latar halaman hampir selalu putih (255,255,255) atau
# abu sangat muda untuk field (247,247,247). Nilai 250 cukup longgar untuk
# menangkap teks abu muda tetapi tetap mengabaikan latar.
INK_THRESHOLD = 250


def row_ink(im: Image.Image, y: int) -> tuple[int, int, int]:
    """Banyak piksel non-latar, kolom terkiri, kolom terkanan pada baris y."""
    count = 0
    left = None
    right = None
    for x in range(im.size[0]):
        r, g, b = im.getpixel((x, y))
        if min(r, g, b) < INK_THRESHOLD:
            count += 1
            if left is None:
                left = x
            right = x
    return count, (left if left is not None else -1), (right if right is not None else -1)


def bands(im: Image.Image, gap: int):
    """Kelompokkan baris ber-isi menjadi pita, dengan kotak pembatasnya."""
    out = []
    current = None
    blank = 0

    for y in range(im.size[1]):
        count, left, right = row_ink(im, y)
        if count == 0:
            blank += 1
            if current is not None and blank > gap:
                out.append(current)
                current = None
            continue

        blank = 0
        if current is None:
            current = {"top": y, "bottom": y, "left": left, "right": right, "ink": count}
        else:
            current["bottom"] = y
            current["left"] = min(current["left"], left)
            current["right"] = max(current["right"], right)
            current["ink"] += count

    if current is not None:
        out.append(current)
    return out


def load(path: str) -> Image.Image:
    im = Image.open(path).convert("RGB")
    if im.size != CANVAS:
        im = im.resize(CANVAS, Image.LANCZOS)
    return im.crop((0, STATUS_BAR, CANVAS[0], CANVAS[1] - HOME_BAR))


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print("Pemakaian: python tool/measure.py <nama> [--gap 3]")
        raise SystemExit(2)

    name = args[0]
    gap = 3
    if "--gap" in args:
        gap = int(args[args.index("--gap") + 1])

    for label, prefix in (("FIGMA", ""), ("EMULATOR", "run-")):
        path = os.path.join(REF, f"{prefix}{name}.png")
        if not os.path.exists(path):
            print(f"{label}: berkas tidak ada ({path})\n")
            continue

        im = load(path)
        print(f"== {label} ==")
        print(f"{'atas':>5} {'bawah':>5} {'tinggi':>6} {'kiri':>5} {'kanan':>5}")
        for b in bands(im, gap):
            print(
                f"{b['top']:>5} {b['bottom']:>5} {b['bottom'] - b['top'] + 1:>6} "
                f"{b['left']:>5} {b['right']:>5}"
            )
        print()


if __name__ == "__main__":
    main()
