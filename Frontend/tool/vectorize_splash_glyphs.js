// Normalisasi ekspor Lottie splash: ganti glyph yang ter-raster jadi path vektor.
//
// Kenapa ada: plugin eksportir Figma menggambar simpul boolean operation
// ("Subtract") sebagai gambar PNG 1x, bukan path. Untuk splash, huruf "g", "o",
// dan "a" kena -- ukurannya 32x44, 32x32, dan 26x32 px, sementara di layar
// digambar ~2,9x lebih besar, jadi ketiganya tampak lebih lembut daripada glyph
// vektor lain. Skrip ini menukar ketiga layer gambar itu dengan shape layer
// vektor memakai SVG sumber di `assets/icons/`.
//
// Kenapa aman: `ImageLayer` Lottie menggambar bitmap pada rect lokal
// (0,0)-(w,h), dan SVG juga ber-origin (0,0) di viewBox-nya -- keduanya sama
// dengan titik anchor layer. Jadi yang perlu ditukar hanya `ty` + `refId`
// menjadi `shapes`; seluruh `ks` (posisi, anchor, scale, rotate, opacity) dan
// keyframe-nya tidak disentuh sama sekali.
//
// Jalankan dari akar repo:  node tool/vectorize_splash_glyphs.js
// Skrip ini idempoten: kalau glyph sudah vektor dan tidak ada aset raster,
// hasilnya tidak berubah.

'use strict';

const fs = require('fs');
const path = require('path');

const SPLASH = path.join(__dirname, '..', 'assets', 'lottie', 'splash.json');
const ICONS = path.join(__dirname, '..', 'assets', 'icons');

// Layer (berdasarkan `ind` di dalam precomp "agronoma full") -> berkas SVG.
// Dipetakan dari pasangan ukuran+warna asset raster: 26x32->a, 32x32->o,
// 32x44->g (coklat #513620 kecuali "g" yang hijau #6D9C25).
const GLYPHS = {
  8: 'splash-glyph-a.svg', // "a"
  10: 'splash-glyph-o.svg', // "o"
  11: 'splash-glyph-g.svg', // "g"
};

const PRECOMP = 'asset_5'; // precomp "agronoma full"
const round5 = (v) => +v.toFixed(5);

function readSvg(file) {
  const svg = fs.readFileSync(path.join(ICONS, file), 'utf8');
  const d = / d="([^"]+)"/.exec(svg);
  const fill = /fill="(#[0-9A-Fa-f]{6})"/.exec(svg);
  if (!d || !fill) throw new Error(`${file}: path/fill tidak ditemukan`);
  return { d: d[1], fill: fill[1] };
}

// --- SVG path "d" -> kontur {v,i,o,closed} -------------------------------
// Hanya perintah M/L/C/Z yang dipakai berkas-berkas ini (sudah diverifikasi;
// tidak ada busur A maupun kuadrat Q), jadi parser kecil ini cukup.
function parsePath(d) {
  const toks = d.match(/[MLCZmlcz]|-?\d*\.?\d+(?:e[-+]?\d+)?/gi) || [];
  const contours = [];
  let cur = null;
  let cp = [0, 0];
  let i = 0;
  const num = () => {
    const v = Number(toks[i++]);
    if (Number.isNaN(v)) throw new Error(`angka diharapkan, dapat "${toks[i - 1]}"`);
    return v;
  };
  const rel = (c) => c === c.toLowerCase();

  while (i < toks.length) {
    const cmd = toks[i++];
    switch (cmd.toUpperCase()) {
      case 'M': {
        let [x, y] = [num(), num()];
        if (rel(cmd)) [x, y] = [x + cp[0], y + cp[1]];
        cp = [x, y];
        cur = { v: [[x, y]], i: [[0, 0]], o: [[0, 0]], closed: false };
        contours.push(cur);
        break;
      }
      case 'L': {
        let [x, y] = [num(), num()];
        if (rel(cmd)) [x, y] = [x + cp[0], y + cp[1]];
        cur.o[cur.o.length - 1] = [0, 0];
        cur.v.push([x, y]);
        cur.i.push([0, 0]);
        cur.o.push([0, 0]);
        cp = [x, y];
        break;
      }
      case 'C': {
        let [x1, y1, x2, y2, x, y] = [num(), num(), num(), num(), num(), num()];
        if (rel(cmd)) {
          [x1, y1] = [x1 + cp[0], y1 + cp[1]];
          [x2, y2] = [x2 + cp[0], y2 + cp[1]];
          [x, y] = [x + cp[0], y + cp[1]];
        }
        // Tangen di Lottie disimpan relatif terhadap vertex-nya.
        cur.o[cur.o.length - 1] = [x1 - cp[0], y1 - cp[1]];
        cur.v.push([x, y]);
        cur.i.push([x2 - x, y2 - y]);
        cur.o.push([0, 0]);
        cp = [x, y];
        break;
      }
      case 'Z':
        cur.closed = true;
        cp = [...cur.v[0]];
        break;
      default:
        throw new Error(`perintah tidak didukung: ${cmd}`);
    }
  }
  return contours;
}

function toShapeData(contours) {
  const i = [];
  const o = [];
  const v = [];
  for (const c of contours) {
    for (let k = 0; k < c.v.length; k++) {
      v.push(c.v[k].map(round5));
      i.push(c.i[k].map(round5));
      o.push(c.o[k].map(round5));
    }
  }
  return { i, o, v, c: true };
}

const hexToRgb01 = (hex) => {
  const n = parseInt(hex.slice(1), 16);
  return [
    +(((n >> 16) & 255) / 255).toFixed(7),
    +(((n >> 8) & 255) / 255).toFixed(7),
    +((n & 255) / 255).toFixed(7),
  ];
};

function shapeLayer(layer, svgFile) {
  const { d, fill } = readSvg(svgFile);
  const shape = toShapeData(parsePath(d));
  delete layer.refId;
  layer.ty = 4;
  layer.shapes = [
    {
      ty: 'gr',
      nm: 'Subtract',
      it: [
        { ty: 'sh', nm: 'Subtract', ind: 0, ks: { a: 0, k: shape } },
        {
          ty: 'fl',
          nm: 'Fill',
          c: { a: 0, k: hexToRgb01(fill) },
          o: { a: 0, k: 100 },
          r: 1, // nonzero == fill-rule default SVG
        },
        {
          ty: 'tr',
          p: { a: 0, k: [0, 0] },
          a: { a: 0, k: [0, 0] },
          s: { a: 0, k: [100, 100] },
          r: { a: 0, k: 0 },
          o: { a: 0, k: 100 },
        },
      ],
    },
  ];
}

const json = JSON.parse(fs.readFileSync(SPLASH, 'utf8'));
const precomp = json.assets.find((a) => a.id === PRECOMP);
if (!precomp) throw new Error(`precomp "${PRECOMP}" tidak ada di splash.json`);

let converted = 0;
for (const layer of precomp.layers) {
  const svgFile = GLYPHS[layer.ind];
  if (!svgFile) continue;
  if (layer.ty === 4) continue; // sudah vektor
  if (layer.ty !== 2) throw new Error(`layer ind ${layer.ind} tak terduga`);
  shapeLayer(layer, svgFile);
  converted++;
  console.log(`ind ${layer.ind} -> vektor (${svgFile.slice(0, 8)})`);
}

// Buang aset raster yang tidak lagi dirujuk oleh layer mana pun.
const used = new Set();
(function collect(layers) {
  for (const l of layers || []) {
    if (l.refId) used.add(l.refId);
    if (l.ty === 0 && l.refId) {
      const a = json.assets.find((x) => x.id === l.refId);
      if (a && a.layers) collect(a.layers);
    }
  }
})(json.layers);

const before = json.assets.length;
json.assets = json.assets.filter((a) => {
  const raster = typeof a.p === 'string' && a.p.startsWith('data:');
  return !(raster && !used.has(a.id));
});

fs.writeFileSync(SPLASH, JSON.stringify(json));
console.log(
  `\n${converted} layer dikonversi | aset ${before} -> ${json.assets.length} | ${SPLASH}`
);
