import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi Agronoma.
///
/// Seluruh nilai di bawah **diukur dari Figma**, bukan diperkirakan. Dua hal
/// yang paling mudah salah dan sudah dikoreksi di sini:
///
/// 1. **Tinggi baris memakai px, bukan rasio.** Figma menuliskan tinggi baris
///    secara eksplisit (mis. `leading-[20px]` untuk teks 14px), jadi angkanya
///    dipakai apa adanya lewat `height: 20 / 14`. Kalau ditulis sebagai rasio
///    bulat, akumulasi selisihnya menggeser seluruh layar dari design.
/// 2. **Poppins hampir tidak dipakai.** Dari 210 simpul teks yang diperiksa,
///    hanya satu yang memakai Poppins: sapaan `Hallo, User!` di Home. Sisanya
///    Inter, sehingga token yang dulu memakai Poppins dipindahkan ke Inter.
/// 3. **Letter-spacing harus ditulis eksplisit, termasuk `0`.** Kalau sebuah
///    token membiarkan `letterSpacing` kosong, Material menambahkan jarak dari
///    `Typography.englishLike2021` (+0,3px pada 14px) — dan Figma memakai 0
///    untuk semua teks yang tidak menuliskan `tracking`. Akibatnya teks jadi
///    ~2% lebih lebar dari design dan ada baris yang **membungkus lebih awal**
///    (mis. langkah 2 di panel hasil deteksi: 5 baris padahal design 4).
///    Karena itu ke-41 token di bawah menuliskan `letterSpacing` — nilainya 0
///    kecuali pada token yang di Figma memang punya `tracking`.
///
/// Ukuran px yang benar-benar muncul di design:
/// **10, 12, 14, 16, 18, 20, 24, 32**.
///
/// Ringkasan peran tiap token (lihat `docs/typography.md` untuk tabel lengkap):
///
/// | Token | Nilai | Dipakai untuk |
/// |---|---|---|
/// | [greetingLarge] | 32/40 Poppins w700 | `Hallo, User!` |
/// | [headlineSmall] | 32/40 Inter w700 | nama penyakit, angka besar tebal |
/// | [displayMedium] | 32/40 Inter w700 | angka statistik (24, 12, 98%) |
/// | [displayLarge] | 32/28 Inter w500 | suhu `28°C` |
/// | [headlineLarge] | 20/28 Inter w600 | judul layar, judul seksi, kota |
/// | [headlineMedium] | 20/20 Inter w600 | judul di top bar |
/// | [titleLarge] | 16/20 Inter w600 | judul kartu & seksi kecil |
/// | [titleWide] | 16/24 Inter w500 | subjudul Home, `Ayo cek …` |
/// | [menuItem] | 16/24 Inter w600 | item menu FAB |
/// | [menuRow] | 18/28 Inter w400 | baris menu Profile |
/// | [menuRowCaption] | 16/24 Inter w400 | keterangan baris menu Profile |
/// | [tagline] | 16/24 Inter w400 | teks pengantar berukuran besar |
/// | [titleMedium] | 14/20 Inter w600 | label field, nama tanaman |
/// | [bodyLarge] | 14/20 Inter w400 | teks isi |
/// | [bodyMuted] | 14/20 Inter w400 | teks isi sekunder |
/// | [bodySmall] | 12/16 Inter w400 | teks kecil |
/// | [bodyCaption] | 12/16 Inter w500 | meta, chip teks |
/// | [labelLarge] | 14/20 Inter w500 | label umum |
/// | [labelMedium] | 12 Inter w500 | label nav bawah |
/// | [labelSmall] | 10/15 Inter w600 | chip huruf kapital |
/// | [buttonLarge] | 14/29 Inter w700 | teks tombol utama |
/// | [buttonOutline] | 14/29 Inter w700 | teks tombol sekunder |
///
/// SF Pro tidak di-bundle karena lisensinya milik Apple, dan seluruh
/// pemakaiannya berada di status bar iPhone yang di Flutter digantikan oleh
/// sistem operasi — jadi tidak ada teks design yang kehilangan typeface-nya.
class AppTextStyles {
  AppTextStyles._();

  static const String fontInter = 'Inter';
  static const String fontPoppins = 'Poppins';

  /// Tinggi baris untuk semua teks yang di Figma ditulis `leading-[normal]`.
  ///
  /// Ini bukan angka karangan. Figma memakai metrik `hhea` font Inter
  /// (ascent 1984 + descent 494 dari unitsPerEm 2048 = **1,21 em**), sedangkan
  /// Flutter/Skia mengambil `usWinAscent/usWinDescent` (2269 + 660 = 1,4302 em).
  /// Kalau `height` dibiarkan `null`, kotak baris Flutter jadi 18% lebih tinggi
  /// dan **setengah kelebihannya menambah jarak di atas teks** — sehingga setiap
  /// blok teks `leading-normal` turun ~0,11 em dari design (≈2px untuk 20px),
  /// dan kesalahan itu menumpuk ke seluruh layar. Menuliskan 1,21 eksplisit
  /// membuat Flutter memakai tinggi baris yang sama dengan Figma.
  ///
  /// Nilai ini dipakai di [cardTitle], [cardTitleWide], [overline],
  /// [overlineValue], [scanTitle], [legend], [labelMedium], dan [sheetTitle].
  static const double leadingNormal = 1.21;

  // ── Judul ───────────────────────────────────────────────────────────────

  /// Sapaan besar di Home (`Hallo, User!`). 32px Poppins Bold, 40px.
  ///
  /// Satu-satunya teks design yang memakai Poppins, dan satu-satunya yang
  /// memakai letter-spacing negatif sebesar -0.64px (2% dari ukuran font).
  ///
  /// Catatan: design memakai Poppins **ExtraBold** (w900), sedangkan repo hanya
  /// menyediakan `Poppins-Bold.ttf` (w700). Bobot yang tersedia dipakai apa
  /// adanya — hurufnya sedikit lebih ringan dari design, dan itu disengaja
  /// daripada menambah berkas font tanpa perlu.
  static const TextStyle greetingLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  /// Judul hasil yang menonjol, mis. nama penyakit `Karat Daun`.
  /// 32px Bold, 40px, letter-spacing -0.64px.
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  /// Angka statistik di Profile (mis. `24`, `12`, `98%`). 32px Bold, 40px.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  /// Angka besar / temperatur (mis. `28°C`). 32px Medium, 28px.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 28 / 32,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Nama pengguna di Profile (`Username`). 24px SemiBold, 32px,
  /// letter-spacing -0.24px.
  static const TextStyle displayName = TextStyle(
    fontFamily: fontInter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.24,
    color: AppColors.ink,
  );

  /// Nama tanaman di atas lembar Detail Tanaman (`Cabai Rawit`). 20px SemiBold,
  /// tinggi baris `normal`.
  ///
  /// Sengaja dipisah dari [headlineLarge] yang tinggi barisnya 28px: di design
  /// simpul nama tanaman memakai `leading-[normal]`, dan selisih 4px itu
  /// menggeser seluruh isi lembar di bawahnya.
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Judul layar / judul seksi. 20px SemiBold, 28px.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Judul di top bar. 20px SemiBold, 20px, letter-spacing -1px.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -1,
    color: AppColors.ink,
  );

  /// Judul top bar di atas foto gelap (Detail Tanaman, kamera). Sama seperti
  /// [headlineMedium] tetapi putih.
  static const TextStyle headlineMediumOnDark = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -1,
    color: AppColors.onPrimary,
  );

  /// Judul seksi besar pada Detail Tanaman ("Ringkasan", "Perawatan").
  /// 20px SemiBold, 20px.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Judul kartu berukuran sedang, mis. "Detail Tanam", "Perkiraan Cuaca".
  /// 16px Medium, tinggi baris `normal`.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Judul kartu yang lebih tegas, mis. "Kalender Perawatan". 18px SemiBold,
  /// tinggi baris `normal`.
  static const TextStyle cardTitleWide = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Label kecil huruf kapital di dalam kotak "Detail Tanam". 11px Bold,
  /// letter-spacing 0.55px, tinggi baris `normal`.
  static const TextStyle overline = TextStyle(
    fontFamily: fontInter,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: leadingNormal,
    letterSpacing: 0.55,
    color: AppColors.darkGrey,
  );

  /// Nilai di bawah [overline]. 14px SemiBold, letter-spacing 0.14px,
  /// tinggi baris `normal`.
  static const TextStyle overlineValue = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0.14,
    color: AppColors.ink,
  );

  /// Label fase pada garis waktu "Fase Pertumbuhan" yang belum dicapai.
  /// 12px Medium, 14px.
  static const TextStyle phaseLabel = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  /// Label fase yang sedang aktif. 14px SemiBold, 14px, hijau.
  static const TextStyle phaseLabelActive = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0.14,
    color: AppColors.primary,
  );

  /// Nama hari pada kartu ramalan cuaca. 12px Medium, 16px.
  static const TextStyle forecastDay = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  /// Suhu pada kartu ramalan cuaca. 18px Medium, 20px.
  static const TextStyle forecastTemp = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 20 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Judul kartu "Pindai Kesehatan" (putih di atas hijau). 16px SemiBold,
  /// tinggi baris `normal`.
  static const TextStyle scanTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  /// Keterangan di bawah [scanTitle]. 14px Medium, tinggi baris `normal`.
  static const TextStyle scanCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  /// Nama hari pada kalender perawatan. 12px Regular, 16px.
  static const TextStyle calendarDay = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  /// Tanggal pada kalender perawatan. 18px Medium, 27px.
  static const TextStyle calendarDate = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 27 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Keterangan ikon di bawah kalender ("Siram", "Pupuk"). 10px Regular,
  /// tinggi baris `normal`.
  static const TextStyle legend = TextStyle(
    fontFamily: fontInter,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Chip kecil di Detail Tanaman (`Indoor`/`Outdoor`). 12px Medium, 18px,
  /// letter-spacing -0.5px.
  static const TextStyle tagChip = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: -0.5,
    color: AppColors.grey,
  );

  /// Deskripsi di bawah nama tanaman pada Detail Tanaman. 16px Regular, 18px,
  /// letter-spacing -0.5px, `Dark Grey`.
  static const TextStyle sheetBody = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 18 / 16,
    letterSpacing: -0.5,
    color: AppColors.darkGrey,
  );

  /// Judul kartu & seksi kecil. 16px SemiBold, 20px.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Baris dua tingkat dengan judul dan keterangan (mis. kota + kondisi cuaca
  /// di kartu cuaca). 16px Medium, 24px.
  static const TextStyle titleWide = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Item menu yang muncul dari tombol tambah. 16px SemiBold, 24px.
  static const TextStyle menuItem = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  /// Baris menu di Profile (mis. `Pengingat Penyiraman`). 18px Regular, 28px.
  static const TextStyle menuRow = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Keterangan di bawah baris menu Profile. 16px Regular, 24px.
  static const TextStyle menuRowCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  /// Teks pengantar berukuran besar (mis. `Arahkan kamera ke tanaman`).
  /// 16px Regular, 24px.
  static const TextStyle tagline = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Sub-judul seksi / label field / nama tanaman. 14px SemiBold, 20px.
  ///
  /// Warnanya `Dark Grey` (#454545) sesuai design, bukan hitam.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  // ── Isi ─────────────────────────────────────────────────────────────────

  /// Teks isi utama. 14px Regular, 20px.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Teks isi sekunder / deskripsi. 14px Regular, 20px, abu.
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  /// Teks isi kecil. 12px Regular, 16px.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Meta / label kecil (mis. `Semi-Indoor`). 12px Medium, 16px, abu.
  static const TextStyle bodyCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  // ── Label & kontrol ─────────────────────────────────────────────────────

  /// Label umum & tautan aksi. 14px Medium, 20px.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Label nav bawah ("Beranda", "Profil"). 12px Medium, tinggi baris `normal`.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.inkMuted,
  );

  /// Chip / badge huruf kapital (mis. `PERLU DISIRAM`). 10px SemiBold, 15px,
  /// letter-spacing 0.5px.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 15 / 10,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  /// Teks tombol utama (mis. `Masuk`, `Lanjut`). 14px Bold, 29px.
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 29 / 14,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  /// Teks tombol sekunder / outline. 14px Bold, 29px.
  static const TextStyle buttonOutline = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 29 / 14,
    letterSpacing: 0,
    color: AppColors.primary,
  );
}
