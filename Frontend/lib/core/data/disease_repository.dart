import 'package:frontend/core/models/disease.dart';

/// Antarmuka sumber data diagnosis penyakit agar implementasi mock bisa
/// ditukar backend (deteksi gambar) tanpa menyentuh UI.
abstract class DiseaseRepository {
  /// Menganalisis gambar tanaman. [imagePath] boleh null untuk mode contoh
  /// (dipakai saat berjalan di emulator tanpa kamera).
  Future<Disease> detect({String? imagePath, String? plantId});
}
