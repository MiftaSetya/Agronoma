"""Simpan potongan foto Figma & emulator berdampingan untuk dibandingkan mata."""

from __future__ import annotations

import os
import sys

from PIL import Image

REF = os.path.join(os.environ["TEMP"], "agro-ref")


def main() -> None:
    name = sys.argv[1]
    y0, y1 = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (0, 252)
    a = Image.open(os.path.join(REF, f"{name}.png")).convert("RGB")
    b = Image.open(os.path.join(REF, f"run-{name}.png")).convert("RGB")
    if b.size != a.size:
        b = b.resize(a.size, Image.LANCZOS)
    a = a.crop((0, y0, 440, y1))
    b = b.crop((0, y0, 440, y1))
    canvas = Image.new("RGB", (440 * 2 + 8, y1 - y0), "white")
    canvas.paste(a, (0, 0))
    canvas.paste(b, (448, 0))
    out = os.path.join(REF, f"pair-{name}.png")
    canvas.resize((canvas.width * 2, canvas.height * 2), Image.LANCZOS).save(out)
    print(out)


if __name__ == "__main__":
    main()
