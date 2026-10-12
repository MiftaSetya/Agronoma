import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi Agronoma — seluruh nilai diukur dari Figma, bukan diperkirakan.
///
/// Dua keputusan penting: (1) `height` selalu ditulis eksplisit karena Flutter
/// memakai metrik `usWin` Inter (1,43 em) sementara Figma memakai `hhea`
/// (1,21 em) — `height: null` membuat kotak baris 18% lebih tinggi; (2)
/// `letterSpacing` juga selalu eksplisit (0 kecuali yang di Figma punya
/// `tracking`) karena bila dibiarkan null Material menambah +0,3px dari
/// `Typography.englishLike2021`, membuat teks ~2% lebih lebar hingga ada yang
/// membungkus lebih awal dari design.
///
/// Poppins hanya dipakai [greetingLarge]; sisanya Inter. SF Pro tidak
/// di-bundle (lisensi Apple) karena pemakaiannya hanya di status bar yang di
/// Flutter digantikan sistem operasi.
class AppTextStyles {
  AppTextStyles._();

  static const String fontInter = 'Inter';
  static const String fontPoppins = 'Poppins';

  /// Tinggi baris untuk semua teks yang di Figma ditulis `leading-[normal]`;
  /// 1,21 em dari metrik `hhea` Inter — alasan lengkapnya di doc kelas.
  static const double leadingNormal = 1.21;

  // Judul

  /// Satu-satunya teks yang memakai Poppins (design pakai ExtraBold, tapi repo
  /// hanya punya Poppins-Bold.ttf — bobot w700 dipakai apa adanya).
  /// Satu-satunya letter-spacing negatif besar: -0.64px.
  static const TextStyle greetingLarge = TextStyle(
    fontFamily: fontPoppins,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.ink,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 28 / 32,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle displayName = TextStyle(
    fontFamily: fontInter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.24,
    color: AppColors.ink,
  );

  /// Tinggi barisnya sengaja `leadingNormal` (bukan 28 seperti [headlineLarge])
  /// agar isi lembar Detail Tanaman tidak tergeser.
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -1,
    color: AppColors.ink,
  );

  /// Varian putih [headlineMedium] untuk top bar di atas foto gelap.
  static const TextStyle headlineMediumOnDark = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -1,
    color: AppColors.onPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle cardTitleWide = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontInter,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: leadingNormal,
    letterSpacing: 0.55,
    color: AppColors.darkGrey,
  );

  static const TextStyle overlineValue = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0.14,
    color: AppColors.ink,
  );

  static const TextStyle phaseLabel = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  static const TextStyle phaseLabelActive = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0.14,
    color: AppColors.primary,
  );

  static const TextStyle forecastDay = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  static const TextStyle forecastTemp = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 20 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle scanTitle = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  static const TextStyle scanCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  static const TextStyle calendarDay = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  static const TextStyle calendarDate = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 27 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle legend = TextStyle(
    fontFamily: fontInter,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle tagChip = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: -0.5,
    color: AppColors.grey,
  );

  static const TextStyle sheetBody = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 18 / 16,
    letterSpacing: -0.5,
    color: AppColors.darkGrey,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle titleWide = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle menuItem = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  static const TextStyle menuRow = TextStyle(
    fontFamily: fontInter,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle menuRowCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: fontInter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  /// Warnanya `Dark Grey` sesuai design, bukan hitam.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.darkGrey,
  );

  // Isi

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle bodyCaption = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: AppColors.grey,
  );

  // Label & kontrol

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontInter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: leadingNormal,
    letterSpacing: 0,
    color: AppColors.inkMuted,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontInter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 15 / 10,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 29 / 14,
    letterSpacing: 0,
    color: AppColors.onPrimary,
  );

  static const TextStyle buttonOutline = TextStyle(
    fontFamily: fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 29 / 14,
    letterSpacing: 0,
    color: AppColors.primary,
  );
}
