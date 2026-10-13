# Token Design Agronoma

Sumber: Figma "Agronoma Design", Page 1 (`0:1`).
Diekstrak dari `get_variable_defs` dan `get_design_context` atas 24 frame in-scope.

## 1. Token resmi (Figma Variables)

Hanya **7** token yang terdaftar sebagai Variables.

| Nama | Nilai | Pemakaian |
|---|---|---|
| `Primary` | `#6D9C25` | hijau utama |
| `Grey` | `#898B87` | teks redup |
| `Dark Grey` | `#454545` | teks sekunder |
| `MainWhite` | `#FFFFFF` | latar |
| `Light Grey` | `#E7E9E7` | border/divider |
| `Labels/Primary` | `#000000` | teks judul (variabel) |
| `shadow1` | DROP_SHADOW `#0000000D`, offset (0,1), radius 2, spread 0 | kartu |

## 2. Kesenjangan: 36 warna, 7 token

24 screen memakai **36 warna berbeda**. Artinya **29 warna tidak pernah masuk
Variables** dan tertulis sebagai hex lepas di Figma. Nilai di bawah dihitung dari
frekuensi kemunculan pada 15 frame yang dianalisis.

### Netral

| Token | Nilai | Kemunculan | Peran |
|---|---|---|---|
| `ink` | `#161616` | 93 | teks judul & isi (praktiknya menggantikan `Labels/Primary`) |
| `surfaceMuted` | `#F9F9F9` | 5 | permukaan sekunder, header seksi |
| `borderStrong` | `#E1E3E4` | 3 | border kartu terpilih |
| `muted` | `#D9D9D9` | 2 | placeholder, garis non-aktif |
| `surfaceAlt` | `#EDEEEC` | 1 | baris non-aktif |

> **Catatan penting:** `Labels/Primary` (`#000000`) adalah variabel resmi, tetapi
> design nyatanya memakai `#161616` di 93 tempat. Keduanya dipertahankan supaya
> pemakaian asli bisa direplikasi apa adanya.

### Semantik

| Token | Nilai | Kemunculan | Konteks |
|---|---|---|---|
| `primaryLight` | `#9CC671` | 6 | aksen hijau terang |
| `primaryDark` | `#416600` | — | teks di atas tint hijau |
| `primaryTint` | `#E9F5D6` | 2 | chip "Kondisi Aman" |
| `primarySurface` | `#FAFFE9` | 1 | latar hijau hampir putih |
| `greenMid` | `#82B534` | 2 | gradasi/logo |
| `careWaterTint` | `#CEE8FD` | 5 | chip "Perlu Disiram" |
| `careWater` | `#369FF5` | 2 | ikon penyiraman |
| `careWaterLight` | `#B9DEFB` | 1 | gradasi ikon air |
| `careFertilizeSurface` | `#FEF7E3` | 11 | latar kuning lembut |
| `careFertilize` | `#CD9806` | 8 | ikon/teks pupuk |
| `careFertilizeTint` | `#FDF1CE` | 5 | chip "Perlu Pupuk" |
| `careFertilizeSoft` | `#FFF3D1` | 2 | kuning pucat |
| `danger` | `#CA0411` | 5 | "Penyakit terdeteksi" |
| `dangerTint` | `#FFE7E4` | 2 | latar merah muda |
| `star` | `#FDCD0C` | 1 | "Pilihan Terbaik" |
| `harvest` | `#89582B` | 2 | angka panen (Profile) |

Warna hijau sisanya (`#A1E834`, `#A8E64A`, `#C2F573`, `#659022`) hanya muncul di
gradasi ilustrasi dan tidak diekspos sebagai token.

## 3. Tipografi

6 varian font terdeteksi:

| Font | Bobot | Asal |
|---|---|---|
| Inter | Regular, Medium, SemiBold, Bold | Google Fonts / OFL |
| Poppins | Bold | Google Fonts / OFL |
| **SF Pro** | Semibold | **Apple — tidak di-bundle** |

**SF Pro tidak dipakai.** Seluruh pemakaiannya (15 kemunculan) berada di
`Status Bar - iPhone` — di Flutter digantikan status bar sistem operasi, jadi
tidak ada teks design yang kehilangan typeface-nya. Digantikan oleh Inter agar
konsisten dengan typeface utama design.

Ukuran px yang benar-benar muncul: **10, 12, 14, 16, 17, 20, 32**.

Inter diambil sebagai TTF **statis** (bukan variable font), karena pemetaan
`fontWeight` pada variable font butuh `fontVariations` yang lebih rawan salah.

## 4. Jarak, radius, ukuran

Nilai kelipatan 4 yang lazim di Figma; diukur dari `get_design_context`.

| Kategori | Nilai |
|---|---|
| Spacing | 4, 8, 12, 16, 20, 24, 32 |
| Padding halaman | 20 |
| Radius chip | 999 (pil) |
| Radius | 8, 12, 16, 20 |
| Radius bottom sheet | 24 (atas saja) |
| Tinggi tombol | 50 |
| Tinggi field | 44 |
| Tinggi top bar | 56 |
| Tinggi nav bawah | 64 |
| Ukuran FAB | 56 |

## 5. Aset

| Jenis | Jumlah | Lokasi |
|---|---|---|
| Ikon SVG | 118 | `assets/icons/` |
| Gambar | 18 | `assets/images/` |

Aset disajikan Figma dari `http://localhost:3845/assets/<id>.<ext>` (id = SHA-1
aset, hanya hidup selama Figma berjalan) — karena itu semuanya diunduh ke repo
(Fase 0) dan disimpan dengan nama deskriptif; pemetaan id → nama berkas ada di
`tool/asset-names.json`.

Raster dioptimasi 39,6 MB → 4,8 MB (87,8%). Deteksi alpha dilakukan per piksel,
bukan dari nama kanal: dari 19 gambar ternyata hanya **1** yang benar-benar
memakai transparansi. Foto dikonversi ke JPEG, sisanya tetap PNG.
