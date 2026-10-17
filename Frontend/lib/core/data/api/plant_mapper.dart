import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/plant_catalog.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Penerjemah `UserPlantResource` (backend) → [Plant] (model design).
///
/// Dulu pemetaan ini hanya ada di dalam `HttpAddPlantRepository` karena wizard
/// adalah satu-satunya pemakai `POST /plants`. Sejak Beranda membaca
/// `GET /plants`, pemetaannya dipindah ke sini supaya kedua jalur memakai
/// **aturan yang sama** — dua salinan pemetaan cepat atau lambat berbeda dan
/// tanaman yang baru ditanam akan tampak berubah setelah dimuat ulang.
///
/// Yang dikirim backend hanya identitas tanaman, fase, tanggal, badge, dan
/// lokasi. Sisanya berasal dari:
///
/// - **katalog design** (`PlantCatalog`): foto + chip Indoor/Outdoor;
/// - **`SoilCatalog`**: nama tanah dan jenis pupuk;
/// - **pemanggil** (`description`): kalimat hasil AI yang dikumpulkan wizard.
///   Tanpa itu, deskripsi disusun dari hal yang memang diketahui (media+tanah).
class PlantMapper {
  PlantMapper._();

  /// `UserPlantResource` → [Plant].
  ///
  /// [description] adalah kalimat `reasoning` dari rekomendasi AI (wizard);
  /// boleh `null` untuk tanaman yang dibaca dari `GET /plants`, karena backend
  /// tidak menyimpan deskripsi.
  static Plant fromBackend(
    Map<String, dynamic> json, {
    String? scientificName,
    String? description,
    String? fallbackCity,
  }) {
    final name = (json['plant_name'] as String? ?? '').trim();
    final visual = PlantCatalog.find(name);
    final media = BackendCodes.plantingMediumFrom(
      json['planting_medium'] as String?,
    );
    final soil = SoilCatalog.byCode(json['soil_type'] as String? ?? '');
    final location = json['location'] as Map<String, dynamic>?;
    final plantingDate =
        DateTime.tryParse('${json['planting_date']}') ?? DateTime.now();

    return Plant(
      id: '${json['id']}',
      name: name.isEmpty ? 'Tanaman' : name,
      scientificName: scientificName,
      photoAsset: visual?.photoAsset ?? PlantCatalog.fallbackPhoto,
      // Kota dipakai untuk memilih cuaca per lokasi, jadi urutannya:
      // lokasi tanaman → kota cadangan dari pemanggil → label lokasi.
      // Nilai kosong diperlakukan sebagai tidak ada: kota adalah kunci cache
      // cuaca, dan string kosong akan menghasilkan kartu cuaca tanpa nama.
      location:
          _firstNonEmpty([
            location?['city'] as String?,
            fallbackCity,
            location?['label'] as String?,
          ]) ??
          'Lokasi Tanam',
      // Media tanam pilihan langkah 2 menentukan "MEDIA TANAM" di Detail.
      place: media.label,
      media: media,
      status: BackendCodes.badgeStatus(json['badge_status'] as String?),
      phase: BackendCodes.phaseFrom(json['current_phase'] as String?),
      plantedAt: plantingDate,
      // Skor perawatan milik pengguna (`GET /profile`), bukan per tanaman;
      // `Plant.careScore` hanya dipakai data contoh. Nilai netral di sini
      // supaya layar yang membacanya tidak menampilkan angka palsu.
      careScore: 100,
      description: _descriptionOrFallback(
        description: description,
        media: media,
        soil: soil,
      ),
      tags: visual?.tags ?? const [],
      // Tanah paling kaya bahan organik pada katalog design; sejalan dengan
      // data contoh supaya Detail Tanaman tidak tampak berbeda.
      fertilizer: soil.code == 'fertile' ? 'NPK Organik' : 'NPK Daun',
      soilName: soil.name,
      // Jadwal perawatan datang dari `GET /plants/{id}/care-calendar` (lihat
      // `PlantSchedule`), bukan dari resource tanaman.
      tasks: const [],
      timeline: const [],
    );
  }

  /// Nilai pertama yang tidak kosong, atau `null` bila semuanya kosong.
  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  /// Deskripsi Detail Tanaman.
  ///
  /// Kalimat AI hanya tersedia pada tanaman yang baru saja disimpan wizard.
  /// Untuk tanaman yang dibaca ulang dari backend, deskripsi disusun dari dua
  /// hal yang benar-benar diketahui — media dan jenis tanah — daripada
  /// mengarang cerita tanaman.
  static String _descriptionOrFallback({
    required String? description,
    required PlantingMedia media,
    required SoilType soil,
  }) {
    final trimmed = (description ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Ditanam di ${media.label.toLowerCase()} dengan '
        '${soil.name.toLowerCase()}.';
  }
}
