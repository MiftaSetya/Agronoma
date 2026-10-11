"""Pisahkan selisih Figma vs emulator jadi area foto dan area lembar putih."""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageChops

REF = os.path.join(os.environ["TEMP"], "agro-ref")


def score(a: Image.Image, b: Image.Image) -> float:
    diff = ImageChops.difference(a, b).convert("L")
    hist = diff.histogram()
    return sum(v * i for i, v in enumerate(hist)) / (a.size[0] * a.size[1])


def main() -> None:
    name = sys.argv[1]
    top = int(sys.argv[2]) if len(sys.argv) > 2 else 64
    a = Image.open(os.path.join(REF, f"{name}.png")).convert("RGB")
    b = Image.open(os.path.join(REF, f"run-{name}.png")).convert("RGB")
    if b.size != a.size:
        b = b.resize(a.size, Image.LANCZOS)
    # Bandingkan hanya pada area isi (status bar Figma 64px, Android 64px inset).
    a = a.crop((0, top, a.size[0], a.size[1] - 24))
    b = b.crop((0, top, b.size[0], b.size[1] - 24))
    h = a.size[1]
    for label, y0, y1 in (
        ("seluruh isi", 0, h),
        ("foto (0-252)", 0, 252 - top),
        ("lembar (252+)", 252 - top, h),
    ):
        print(f"  {label:16s} {score(a.crop((0, y0, a.size[0], y1)), b.crop((0, y0, b.size[0], y1))):6.1f}")


if __name__ == "__main__":
    main()
