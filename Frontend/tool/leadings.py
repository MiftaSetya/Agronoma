"""Peta tinggi baris teks Figma -> teksnya, lengkap dengan ukuran font.

Setiap simpul teks di design ditulis sebagai:

    <div className="... font-['Inter:Semi_Bold'] font-semibold justify-center
                    leading-[0] ... text-[16px] ...">
      <p className="leading-[normal]">Ringkasan</p>
    </div>

Angka yang berlaku untuk tinggi baris ada di `<p>` (`leading-[normal]` atau
`leading-[Npx]`), sedangkan ukuran & bobot font ada di pembungkusnya. Karena
`ctx-*.txt` memakai UTF-16, berkasnya dibaca sebagai biner lalu didekode dulu.

Pemakaian:  python tool/leadings.py [filter-teks]
"""

from __future__ import annotations

import glob
import os
import re
import sys

REF = os.path.join(os.environ["TEMP"], "agro-ref")

P = re.compile(r'<p className="([^"]*)"\s*>(.*?)</p>', re.S)
SIZE = re.compile(r"text-\[(\d+)px\]")
WEIGHT = re.compile(r"font-\[['\"]Inter:([A-Za-z]+)['\"]\]")
DIV = re.compile(r"<div className=\"([^\"]*)\"[^>]*data-node-id=\"([^\"]+)\"")


def read(path: str) -> str:
    b = open(path, "rb").read()
    enc = "utf-16" if b[:2] in (b"\xff\xfe", b"\xfe\xff") else "utf-8"
    return b.decode(enc, errors="replace")


def main() -> None:
    needle = sys.argv[1].lower() if len(sys.argv) > 1 else ""
    rows = []

    for path in sorted(glob.glob(os.path.join(REF, "ctx-*.txt"))):
        text = read(path)
        # Semua pembungkus <div> beserta posisinya di berkas.
        divs = [(m.start(), m.group(1), m.group(2)) for m in DIV.finditer(text)]
        for m in P.finditer(text):
            body = re.sub(r"\s+", " ", m.group(2)).strip()
            body = body.replace("<br />", " ").strip()
            if not body or len(body) > 70:
                continue
            lead_m = re.search(r"leading-\[([^\]]+)\]", m.group(1))
            if not lead_m:
                continue
            if needle and needle not in body.lower():
                continue
            # Pembungkus terdekat sebelum <p> ini.
            prev = [d for d in divs if d[0] < m.start()]
            cls, node = (prev[-1][1], prev[-1][2]) if prev else ("", "?")
            size = SIZE.search(cls)
            weight = WEIGHT.search(cls)
            rows.append(
                (
                    lead_m.group(1),
                    size.group(1) if size else "?",
                    weight.group(1) if weight else "?",
                    body,
                )
            )

    rows.sort(key=lambda r: (r[0] != "normal", r[0], r[2]))
    for lead, size, weight, body in rows:
        print(f"{lead:>8}  {size:>2}px {weight:<9} {body}")


if __name__ == "__main__":
    main()
