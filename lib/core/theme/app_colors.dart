import 'package:flutter/material.dart';

/// Token warna Agronoma.
///
/// Ada dua lapis, dan perbedaannya disengaja:
///
/// 1. **Token resmi** — berasal dari Figma Variables. Hanya ada 7, dan
///    nilai heksnya tidak boleh diubah.
/// 2. **Token turunan** — 24 screen design memakai 36 warna berbeda, artinya
///    29 warna tidak pernah masuk ke Variables dan tertulis sebagai hex lepas
///    di Figma. Warna-warna itu diberi nama semantik di sini supaya tidak
///    tersebar sebagai angka heksadesimal liar di dalam widget.
///
/// Setiap token turunan disertai jumlah kemunculan pada 15 frame yang
/// dianalisis (`docs/design-tokens.md`), jadi asalnya bisa ditelusuri.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Token resmi (Figma Variables)
  // ─────────────────────────────────────────────────────────────────────────

  /// `Primary` — hijau utama Agronoma.
  static const Color primary = Color(0xFF6D9C25);

  /// `Grey` — teks sekunder paling umum.
  static const Color grey = Color(0xFF898B87);

  /// `Dark Grey` — teks sekunder yang lebih kuat.
  static const Color darkGrey = Color(0xFF454545);

  /// `MainWhite` — latar utama.
  static const Color mainWhite = Color(0xFFFFFFFF);

  /// `Light Grey` — dipakai sebagai border/divider, bukan sebagai latar.
  static const Color lightGrey = Color(0xFFE7E9E7);

  /// `Labels/Primary` — variabel resmi untuk teks judul.
  ///
  /// Catatan: design sebenarnya memakai [#ink] (#161616) di 93 tempat,
  /// sedangkan variabel ini hanya muncul belasan kali. Keduanya disediakan
  /// supaya pemakaian asli tetap bisa direplikasi apa adanya.
  static const Color labelPrimary = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Turunan — netral
  // ─────────────────────────────────────────────────────────────────────────

  /// Teks judul & isi utama. Menggantikan [#labelPrimary] pada praktiknya.
  static const Color ink = Color(0xFF161616);

  /// Teks pendukung: deskripsi, subjudul. = [#darkGrey].
  static const Color inkSecondary = darkGrey;

  /// Teks paling redup: hint input, label non-aktif, meta. = [#grey].
  static const Color inkMuted = grey;

  /// Teks di atas latar hijau.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Latar halaman & permukaan kartu.
  static const Color surface = mainWhite;

  /// Permukaan yang sedikit berbeda dari putih (kartu di atas kartu,
  /// header seksi seperti "PREFERENSI"). 5 kemunculan.
  static const Color surfaceMuted = Color(0xFFF9F9F9);

  /// Permukaan abu paling terang, untuk baris non-aktif. 1 kemunculan.
  static const Color surfaceAlt = Color(0xFFEDEEEC);

  /// Border kartu & input. Menggunakan token resmi [#lightGrey].
  static const Color border = lightGrey;

  /// Border yang lebih tegas (kartu terpilih / outline). 3 kemunculan.
  static const Color borderStrong = Color(0xFFE1E3E4);

  /// Tombol utama saat nonaktif. Tidak pernah tertulis sebagai hex di design:
  /// terukur dari pixel tombol "Lanjut" langkah 4/5 yang di Figma ditulis
  /// `bg-[#898b87] opacity-40` — hasil campurannya di atas putih itulah
  /// #D0D1CF. Meniru opacity membuat teksnya ikut pudar, jadi warna akhirnya
  /// saja yang dipakai.
  static const Color disabledFill = Color(0xFFD0D1CF);

  /// Placeholder abu & garis non-aktif. 2 kemunculan.
  static const Color muted = Color(0xFFD9D9D9);

  /// Lapisan gelap di belakang bottom sheet / dialog.
  static const Color scrim = Color(0x80454545);

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Turunan — semantik
  // ─────────────────────────────────────────────────────────────────────────

  /// Warna hijau terang untuk aksen latar (mis. tombol FAB, ikon aktif).
  static const Color primaryLight = Color(0xFF9CC671);

  /// Hijau gelap untuk teks di atas [#primaryTint].
  static const Color primaryDark = Color(0xFF416600);

  /// Latar hijau muda untuk status aman / terpilih.
  static const Color primaryTint = Color(0xFFE9F5D6);

  /// Latar hijau hampir putih.
  static const Color primarySurface = Color(0xFFFAFFE9);

  // -- Perawatan: penyiraman (biru)
  /// Latar chip "Perlu Disiram". 5 kemunculan.
  static const Color careWaterTint = Color(0xFFCEE8FD);

  /// Ikon/teks penyiraman. 2 kemunculan.
  static const Color careWater = Color(0xFF369FF5);

  /// Biru muda untuk gradasi ikon.
  static const Color careWaterLight = Color(0xFFB9DEFB);

  // -- Perawatan: pemupukan (kuning)
  /// Latar chip "Perlu Pupuk". 11 kemunculan [#careFertilizeSurface].
  static const Color careFertilizeTint = Color(0xFFFDF1CE);

  /// Latar kuning paling lembut. 11 kemunculan.
  static const Color careFertilizeSurface = Color(0xFFFEF7E3);

  /// Teks/ikon pemupukan. 8 kemunculan.
  static const Color careFertilize = Color(0xFFCD9806);

  /// Kuning pucat tambahan. 2 kemunculan.
  static const Color careFertilizeSoft = Color(0xFFFFF3D1);

  // -- Status: bahaya / peringatan
  /// Teks peringatan & "Penyakit terdeteksi". 5 kemunculan.
  static const Color danger = Color(0xFFCA0411);

  /// Latar merah muda. 2 kemunculan.
  static const Color dangerTint = Color(0xFFFFE7E4);

  // -- Aksen lain
  /// Bintang "Pilihan Terbaik". 1 kemunculan.
  static const Color star = Color(0xFFFDCD0C);

  /// Angka hasil panen di Profile (brown). 2 kemunculan.
  static const Color harvest = Color(0xFF89582B);

  /// Hijau intermediate untuk gradasi/logo. 2 kemunculan.
  static const Color greenMid = Color(0xFF82B534);

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Bayangan
  // ─────────────────────────────────────────────────────────────────────────

  /// `shadow1` dari Figma: DROP_SHADOW, #000000 5%, offset (0, 1), blur 2, spread 0.
  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Bayangan kartu yang lebih terlihat, untuk elemen mengambang (FAB, sheet).
  static const List<BoxShadow> shadowRaised = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Bayangan lembut kartu pada Detail Tanaman:
  /// `DROP_SHADOW, #0000000D, offset (0, 1), blur 2` — sama dengan [shadow1],
  /// tetapi design menuliskannya pada kartu yang lebih besar sehingga tepinya
  /// terlihat lebih tegas di layar.
  static const List<BoxShadow> shadowRaisedSoft = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
}
