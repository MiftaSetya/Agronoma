# Tipografi

Semua teks aplikasi melewati satu kelas: `lib/core/theme/app_text_styles.dart`
(`AppTextStyles`). Widget tidak pernah menulis `TextStyle` sendiri — kalau
sebuah teks butuh gaya baru, gaya itu ditambahkan ke kelas tersebut dengan
komentar asal-usulnya, bukan dibuat sebarangan di layar.

Dua font yang di-bundle (dari `tool/fetch_fonts.ps1`):

| Font | Berkas | Peran |
|---|---|---|
| **Inter** | `Poppins`? — lihat tabel bawah | seluruh aplikasi |
| **Poppins Bold** | `assets/fonts/` | satu-satunya teks Poppins: sapaan `Hallo, User!` |

> SF Pro (font status bar design iPhone) **sengaja tidak di-bundle** —
> lisensinya milik Apple, dan seluruh pemakaiannya berada di status bar yang
> di Flutter digambar sistem operasi, jadi tidak ada teks design yang
> kehilangan typeface-nya.

## Dua keputusan teknis yang wajib dipahami

### 1. `letterSpacing` selalu ditulis eksplisit

Web browser menurunkan `letter-spacing: normal` ke **0px**, tetapi Flutter
menurunkannya ke **-0.5% dari ukuran font** (mis. -0,16px untuk teks 16px).
Akibatnya teks jadi ~2% lebih sempit dan ada baris yang membungkus berbeda
dari design. Karena itu **ke-41 token di bawah menuliskan `letterSpacing`**
— nilainya 0 kecuali token yang di Figma memang punya `tracking`.

### 2. `height: leadingNormal` (1,21) bukan angka karangan

Figma memakai metrik `hhea` font Inter (ascent 1984 + descent 494 dari
unitsPerEm 2048 = **1,21 em**), sedangkan Flutter/Skia memakai
`usWinAscent/usWinDescent` (2269 + 660 = 1,4302 em). Bila `height` dibiarkan
`null`, kotak baris Flutter jadi 18% lebih tinggi dan setengah kelebihannya
menambah jarak **di atas** teks — setiap blok teks `leading-normal` turun
~0,11 em (≈2px untuk 20px), dan selisih itu menumpuk di seluruh layar.
Token yang di Figma ditulis `leading-[normal]` karenanya eksplisit memakai
`AppTextStyles.leadingNormal` (1,21): [cardTitle], [cardTitleWide], [overline],
[overlineValue], [scanTitle], [scanCaption], [legend], [labelMedium],
[sheetTitle].

`text-box-trim: cap_alphabetic` (pemangkasan atas teks di Figma) tidak punya
padanan Flutter; bila sebuah layout bergantung padanya, widget-nya meniru
pemangkasan itu secara manual — lihat `_TrimmedText` dan
`_capTrimAdjust` di `lib/features/add_plant/add_plant_flow.dart`.

## Tabel token

Ukuran px yang benar-benar muncul di design: **10, 11, 12, 14, 16, 18, 20,
24, 32**.

| Token | Ukuran/tinggi | Font & bobot | Tracking | Warna | Dipakai untuk |
|---|---|---|---:|---|---|
| `greetingLarge` | 32/40 | Poppins w700 | -0,64 | ink | sapaan `Hallo, User!` |
| `headlineSmall` | 32/40 | Inter w700 | -0,64 | ink | nama penyakit, judul hasil menonjol |
| `displayMedium` | 32/40 | Inter w700 | -0,64 | ink | angka statistik Profil (24, 12, 98%) |
| `displayLarge` | 32/28 | Inter w500 | 0 | ink | temperatur `28°C` |
| `displayName` | 24/32 | Inter w600 | -0,24 | ink | nama pengguna di Profil |
| `sheetTitle` | 20/1,21 | Inter w600 | 0 | ink | nama tanaman di lembar Detail (leading `normal`) |
| `headlineLarge` | 20/28 | Inter w600 | 0 | ink | judul layar & seksi, kota |
| `headlineMedium` | 20/20 | Inter w600 | -1 | ink | judul di top bar |
| `headlineMediumOnDark` | 20/20 | Inter w600 | -1 | onPrimary | judul top bar di atas foto gelap |
| `sectionTitle` | 20/20 | Inter w600 | 0 | ink | "Ringkasan", "Perawatan" |
| `cardTitle` | 16/1,21 | Inter w500 | 0 | ink | judul kartu sedang ("Detail Tanam") |
| `cardTitleWide` | 18/1,21 | Inter w600 | 0 | ink | "Kalender Perawatan" |
| `overline` | 11/1,21 | Inter w700 | +0,55 | darkGrey | label kapital di kotak "Detail Tanam" |
| `overlineValue` | 14/1,21 | Inter w600 | +0,14 | ink | nilai di bawah `overline` |
| `phaseLabel` | 12/14 | Inter w500 | 0 | darkGrey | fase garis waktu yang belum dicapai |
| `phaseLabelActive` | 14/14 | Inter w600 | +0,14 | primary | fase aktif (hijau) |
| `forecastDay` | 12/16 | Inter w500 | 0 | darkGrey | nama hari di kartu cuaca |
| `forecastTemp` | 18/20 | Inter w500 | 0 | ink | suhu di kartu cuaca |
| `scanTitle` | 16/1,21 | Inter w600 | 0 | onPrimary | judul kartu "Pindai Kesehatan" (putih) |
| `scanCaption` | 14/1,21 | Inter w500 | 0 | onPrimary | keterangan di bawah `scanTitle` |
| `calendarDay` | 12/16 | Inter w400 | 0 | darkGrey | nama hari di kalender |
| `calendarDate` | 18/27 | Inter w500 | 0 | ink | tanggal di kalender |
| `legend` | 10/1,21 | Inter w400 | 0 | ink | keterangan ikon kalender ("Siram") |
| `tagChip` | 12/18 | Inter w500 | -0,5 | grey | chip `Indoor`/`Outdoor` |
| `sheetBody` | 16/18 | Inter w400 | -0,5 | darkGrey | deskripsi di bawah nama tanaman |
| `titleLarge` | 16/20 | Inter w600 | 0 | ink | judul kartu & seksi kecil |
| `titleWide` | 16/24 | Inter w500 | 0 | ink | `Ayo cek kondisi tanamanmu` |
| `menuItem` | 16/24 | Inter w600 | 0 | primary | item menu FAB |
| `menuRow` | 18/28 | Inter w400 | 0 | ink | baris menu Profil |
| `menuRowCaption` | 16/24 | Inter w400 | 0 | grey | keterangan baris menu Profil |
| `tagline` | 16/24 | Inter w400 | 0 | ink | `Arahkan kamera ke tanaman` |
| `titleMedium` | 14/20 | Inter w600 | 0 | darkGrey | label field, nama tanaman |
| `bodyLarge` | 14/20 | Inter w400 | 0 | ink | teks isi utama |
| `bodyMuted` | 14/20 | Inter w400 | 0 | grey | teks isi sekunder |
| `bodySmall` | 12/16 | Inter w400 | 0 | ink | teks isi kecil |
| `bodyCaption` | 12/16 | Inter w500 | 0 | grey | meta (`Semi-Indoor`) |
| `labelLarge` | 14/20 | Inter w500 | 0 | ink | label umum & tautan aksi |
| `labelMedium` | 12/1,21 | Inter w500 | 0 | inkMuted | label nav bawah |
| `labelSmall` | 10/15 | Inter w600 | +0,5 | ink | chip kapital `PERLU DISIRAM` |
| `buttonLarge` | 14/29 | Inter w700 | 0 | onPrimary | teks tombol utama |
| `buttonOutline` | 14/29 | Inter w700 | 0 | primary | teks tombol sekunder |

## Pengecualian yang dicatat

- **Poppins ExtraBold → Bold.** Design memakai Poppins w900 untuk
  `greetingLarge`, repo hanya menyediakan `Poppins-Bold.ttf` (w700). Bobot
  yang tersedia dipakai apa adanya — hurufnya sedikit lebih ringan, dan itu
  disengaja daripada menambah berkas font tanpa perlu.
- **Angka tinggi baris pecahan** (mis. `29/14` untuk tombol) mengikuti Figma
  apa adanya; tombol design memakai tinggi baris 29px di dalam kotak 54px.
