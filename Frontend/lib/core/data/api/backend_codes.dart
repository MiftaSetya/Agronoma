import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Penerjemah antara nilai enum milik design dan nilai yang dipakai backend.
///
/// Sepuluh nilai design sengaja tidak selalu sama dengan kontrak backend
/// (mis. `PlantingMedia.ground` = "Pekarangan rumah" sedangkan backend
/// menyebutnya `home_yard`), jadi pemetaannya dikumpulkan di satu berkas ini
/// agar tidak tersebar dan bisa diuji sendiri.
///
/// Backend hanya menerima/mengirim kode berikut:
/// - `planting_medium`: `home_yard` | `open_land` | `pot`
/// - `soil_type`: `fertile` | `clay` | `sandy` | `chalky` | `volcanic` | `peat`
///   | `artificial_media`
/// - `current_phase`: `seedling` | `early_vegetative` | `late_vegetative`
///   | `generative`
/// - `badge_status`: `perlu_disiram` | `perlu_pupuk` | `kondisi_aman`
class BackendCodes {
  BackendCodes._();

  static String plantingMedium(PlantingMedia media) => switch (media) {
    PlantingMedia.pot => 'pot',
    PlantingMedia.ground => 'home_yard',
    PlantingMedia.openField => 'open_land',
  };

  /// Kode asing (enum backend bertambah tanpa aplikasi ikut diubah) jatuh ke
  /// `pot` — nilai paling umum di design.
  static PlantingMedia plantingMediumFrom(String? code) => switch (code) {
    'home_yard' => PlantingMedia.ground,
    'open_land' => PlantingMedia.openField,
    _ => PlantingMedia.pot,
  };

  static String soilType(SoilType soil) => soil.code;

  static SoilType soilTypeFrom(String? code) =>
      SoilCatalog.byCode(code ?? '');

  static String phase(GrowthPhase phase) => switch (phase) {
    GrowthPhase.seedling => 'seedling',
    GrowthPhase.vegetativeEarly => 'early_vegetative',
    GrowthPhase.vegetativeLate => 'late_vegetative',
    GrowthPhase.generative => 'generative',
  };

  static GrowthPhase phaseFrom(String? code) => switch (code) {
    'early_vegetative' => GrowthPhase.vegetativeEarly,
    'late_vegetative' => GrowthPhase.vegetativeLate,
    'generative' => GrowthPhase.generative,
    _ => GrowthPhase.seedling,
  };

  /// `badge_status` backend → kondisi kartu Home. Tanaman baru selalu
  /// `kondisi_aman`, tetapi pemetaannya tetap lengkap supaya daftar tanaman
  /// dari `GET /plants` (slice berikutnya) bisa memakai fungsi yang sama.
  static CareStatus badgeStatus(String? code) => switch (code) {
    'perlu_disiram' => CareStatus.needsWater,
    'perlu_pupuk' => CareStatus.needsFertilizer,
    _ => CareStatus.safe,
  };
}
