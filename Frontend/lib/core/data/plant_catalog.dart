import 'package:frontend/core/assets/app_assets.dart';

/// Satu baris katalog tampilan tanaman: foto design + penanda Indoor/Outdoor.
///
/// Kartu "Hasil rekomendasi" (frame `336:2882`) butuh foto dan chip
/// Indoor/Outdoor, sedangkan `POST /plant-recommendations` hanya mengirim
/// `plant_name`, `scores`, dan `reasoning` — tidak ada URL gambar maupun
/// penanda ruang. Jadi dua hal itu dipetakan dari katalog lokal ini; nama yang
/// tidak dikenal memakai [PlantCatalog.fallbackPhoto] tanpa chip ruang
/// (kartunya tetap utuh, hanya chip Indoor/Outdoor yang absen).
class PlantVisual {
  const PlantVisual({
    required this.photoAsset,
    this.tags = const [],
  });

  final String photoAsset;
  final List<String> tags;
}

/// Katalog tampilan tanaman untuk kartu rekomendasi AI.
///
/// Kunci pencarian sengaja huruf kecil dan dicocokkan sebagai *awalan*: model
/// AI bebas menambah keterangan dalam tanda kurung (mis. "Lidah Mertua
/// (Sansevieria)"), sedangkan foto design hanya ada untuk tanaman tertentu.
class PlantCatalog {
  PlantCatalog._();

  /// Dipakai bila nama dari AI tidak ada di [visuals] — pot berisi tanah,
  /// bukan foto tanaman tertentu, supaya kartunya tidak menampilkan tanaman
  /// yang salah.
  static const String fallbackPhoto = AppAssets.photoPotSoil;

  /// Urutan penting: kunci yang lebih spesifik ditulis lebih dulu supaya
  /// "cabai keriting" tidak tertangkap "cabai rawit" dan sebaliknya.
  static const Map<String, PlantVisual> visuals = {
    'cabai rawit': PlantVisual(
      photoAsset: AppAssets.photoCabaiRawit,
      tags: ['Indoor'],
    ),
    'cabai keriting': PlantVisual(
      photoAsset: AppAssets.photoCabaiKeriting,
      tags: ['Indoor'],
    ),
    'tomat ceri': PlantVisual(
      photoAsset: AppAssets.photoTomatCeri,
      tags: ['Indoor'],
    ),
    'lidah mertua': PlantVisual(
      photoAsset: AppAssets.photoLidahMertua,
      tags: ['Indoor'],
    ),
    'sansevieria': PlantVisual(
      photoAsset: AppAssets.photoLidahMertua,
      tags: ['Indoor'],
    ),
    'sirih gading': PlantVisual(
      photoAsset: AppAssets.photoSirihGading,
      tags: ['Indoor', 'Outdoor'],
    ),
  };

  /// Tampilan untuk [plantName]; `null` bila namanya tidak dikenal katalog.
  static PlantVisual? find(String plantName) {
    // Nama dari AI bisa memuat nama ilmiah dalam tanda kurung atau embel-embel
    // sesudah koma; bagian itu dibuang sebelum dicocokkan.
    final normalized = plantName
        .toLowerCase()
        .split('(')
        .first
        .split(',')
        .first
        .trim();

    for (final entry in visuals.entries) {
      if (normalized.startsWith(entry.key)) return entry.value;
    }
    return null;
  }
}
