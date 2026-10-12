import 'package:flutter/material.dart';

/// Token warna Agronoma dalam dua lapis: 7 token resmi dari Figma Variables
/// (nilai heksnya tidak boleh diubah) dan 29 token turunan — warna yang tidak
/// pernah masuk ke Variables (24 screen memakai 36 warna berbeda) dan diberi
/// nama semantik di sini agar tidak tersebar sebagai hex lepas di widget.
/// Jumlah kemunculan tiap token turunan tercatat di `docs/design-tokens.md`.
class AppColors {
  AppColors._();

  // Token resmi (Figma Variables)

  static const Color primary = Color(0xFF6D9C25);

  static const Color grey = Color(0xFF898B87);

  static const Color darkGrey = Color(0xFF454545);

  static const Color mainWhite = Color(0xFFFFFFFF);

  /// Dipakai sebagai border/divider, bukan sebagai latar.
  static const Color lightGrey = Color(0xFFE7E9E7);

  /// Variabel resmi untuk teks judul, tetapi design lebih sering memakai
  /// [#ink] (93× vs belasan); keduanya disediakan agar pemakaian asli tetap
  /// bisa direplikasi.
  static const Color labelPrimary = Color(0xFF000000);

  // Turunan — netral

  /// Menggantikan [#labelPrimary] pada praktiknya (teks judul & isi utama).
  static const Color ink = Color(0xFF161616);

  static const Color inkSecondary = darkGrey;

  static const Color inkMuted = grey;

  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color surface = mainWhite;

  /// Kartu di atas kartu / header seksi seperti "PREFERENSI". 5 kemunculan.
  static const Color surfaceMuted = Color(0xFFF9F9F9);

  /// Permukaan abu paling terang, untuk baris non-aktif. 1 kemunculan.
  static const Color surfaceAlt = Color(0xFFEDEEEC);

  /// Border kartu & input. Menggunakan token resmi [#lightGrey].
  static const Color border = lightGrey;

  /// Border yang lebih tegas (kartu terpilih / outline). 3 kemunculan.
  static const Color borderStrong = Color(0xFFE1E3E4);

  /// Tidak pernah tertulis sebagai hex di design: tombol "Lanjut" langkah 4/5
  /// ditulis `bg-[#898b87] opacity-40` di atas putih, dan meniru opacity-nya
  /// membuat teks ikut pudar — jadi warna hasil campurannya yang dipakai.
  static const Color disabledFill = Color(0xFFD0D1CF);

  /// Placeholder abu & garis non-aktif. 2 kemunculan.
  static const Color muted = Color(0xFFD9D9D9);

  /// Lapisan gelap di belakang bottom sheet / dialog.
  static const Color scrim = Color(0x80454545);

  // Turunan — semantik

  static const Color primaryLight = Color(0xFF9CC671);

  static const Color primaryDark = Color(0xFF416600);

  /// Status aman / terpilih.
  static const Color primaryTint = Color(0xFFE9F5D6);

  static const Color primarySurface = Color(0xFFFAFFE9);

  // -- Perawatan: penyiraman (biru)

  /// Chip "Perlu Disiram". 5 kemunculan.
  static const Color careWaterTint = Color(0xFFCEE8FD);

  static const Color careWater = Color(0xFF369FF5);

  static const Color careWaterLight = Color(0xFFB9DEFB);

  // -- Perawatan: pemupukan (kuning)

  /// Latar chip "Perlu Pupuk". 11 kemunculan [#careFertilizeSurface].
  static const Color careFertilizeTint = Color(0xFFFDF1CE);

  static const Color careFertilizeSurface = Color(0xFFFEF7E3);

  static const Color careFertilize = Color(0xFFCD9806);

  static const Color careFertilizeSoft = Color(0xFFFFF3D1);

  // -- Status: bahaya / peringatan

  /// Teks peringatan & "Penyakit terdeteksi". 5 kemunculan.
  static const Color danger = Color(0xFFCA0411);

  static const Color dangerTint = Color(0xFFFFE7E4);

  // -- Aksen lain

  /// Bintang "Pilihan Terbaik". 1 kemunculan.
  static const Color star = Color(0xFFFDCD0C);

  /// Angka hasil panen di Profile (brown). 2 kemunculan.
  static const Color harvest = Color(0xFF89582B);

  /// Hijau intermediate untuk gradasi/logo. 2 kemunculan.
  static const Color greenMid = Color(0xFF82B534);

  // Bayangan

  /// `shadow1` dari Figma: DROP_SHADOW, #000000 5%, offset (0, 1), blur 2.
  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowRaised = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Nilai identik dengan [shadow1]; sama-sama berasal dari kartu Detail
  /// Tanaman di design (`DROP_SHADOW, #0000000D, offset (0, 1), blur 2`).
  static const List<BoxShadow> shadowRaisedSoft = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
}
