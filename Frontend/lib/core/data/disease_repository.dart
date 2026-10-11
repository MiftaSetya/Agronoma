import 'package:frontend/core/models/disease.dart';

/// Sumber data diagnosis penyakit tanaman.
///
/// Di produksi, [detect] akan mengirim gambar ke model klasifikasi dan
/// mengembalikan hasilnya. Untuk sekarang dipakai contoh dari [MockData].
abstract class DiseaseRepository {
  /// Menganalisis gambar tanaman. [imagePath] boleh null untuk mode contoh
  /// (dipakai saat berjalan di emulator tanpa kamera).
  Future<Disease> detect({String? imagePath});
}
