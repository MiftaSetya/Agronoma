import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi Agronoma.
///
/// Design memakai 6 varian font: `Inter` (Regular / Medium / SemiBold / Bold),
/// `Poppins` Bold, dan `SF Pro` Semibold. SF Pro tidak di-bundle karena
/// lisensinya milik Apple, dan seluruh pemakaiannya berada di status bar iPhone
/// yang di Flutter digantikan oleh sistem operasi — jadi tidak ada teks design
/// yang kehilangan typeface-nya.
///
/// Ukuran (px) yang benar-benar muncul di design: 10, 12, 14, 16, 17, 20, 32.
/// Semua di bawah ini memakai satuan px yang sama (Flutter memperlakukannya
/// sebagai logical pixel, dan design digambar pada 440px untuk iPhone 16 Pro Max).
class AppTextStyles {
  AppTextStyles._();

  static const String fontInter = 'Inter';
  static const String fontPoppins = 'Poppins';

  // ── Judul ───────────────────────────────────────────────────────────────

  /// Angka besar / temperatur (mis. `28°C`). 32px SemiBold.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.ink,
  );

  /// Angka statistik di Profile (mis. `24`, `12`, `98%`).
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.ink,
  );

  /// Judul screen / judul kartu besar. 20px SemiBold.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );

  /// Judul layar di top bar (mis. `Tambahlah tanaman`). 17px SemiBold.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );

  /// Judul seksi / kartu. 16px SemiBold.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.ink,
  );

  /// Sub-judul seksi. 14px SemiBold.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  // ── Isi ─────────────────────────────────────────────────────────────────

  /// Teks isi utama. 14px Regular.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.ink,
  );

  /// Teks isi sekunder / deskripsi. 14px Regular, abu gelap.
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.inkSecondary,
  );

  /// Teks isi kecil. 12px Regular.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.ink,
  );

  /// Meta / keterangan waktu. 12px Regular, abu.
  static const TextStyle bodyCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkMuted,
  );

  // ── Label & kontrol ─────────────────────────────────────────────────────

  /// Label field / tombol. 14px Medium.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.ink,
  );

  /// Label nav bawah, tab. 12px Medium.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.inkMuted,
  );

  /// Chip / badge huruf kapital (mis. `PERLU DISIRAM`). 10px SemiBold,
  /// diberi jarak antar-huruf karena huruf kapital kecil mudah rapat.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
    color: AppColors.ink,
  );

  /// Teks tombol utama (mis. `Masuk`, `Lanjut`). 14px SemiBold.
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.onPrimary,
  );

  /// Teks tombol sekunder / outline. 14px SemiBold.
  static const TextStyle buttonOutline = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.primary,
  );
}
