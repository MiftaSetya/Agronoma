import 'package:flutter/material.dart';

/// Satu langkah penanganan pada hasil deteksi penyakit.
///
/// Di design (`Disease Drawer`, node `253:2575`) penanganan digambar sebagai
/// garis waktu bernomor: tiap langkah punya judul singkat dan satu paragraf
/// penjelasan. Karena itu bentuknya bukan `List<String>` biasa.
@immutable
class DiseaseStep {
  const DiseaseStep({required this.title, required this.detail});

  /// Judul singkat, mis. "Karantina Tanaman".
  final String title;

  /// Satu paragraf penjelasan.
  final String detail;

  factory DiseaseStep.fromJson(Map<String, dynamic> json) => DiseaseStep(
    title: json['title'] as String,
    detail: json['detail'] as String,
  );

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
}

/// Hasil deteksi penyakit tanaman.
@immutable
class Disease {
  const Disease({
    required this.name,
    required this.scientificName,
    required this.diseaseType,
    required this.cause,
    required this.symptoms,
    required this.steps,
    required this.confidence,
    required this.severity,
    this.photoAsset,
  });

  final String name;
  final String scientificName;

  /// Jenis, mis. "Jamur" / "Bakteri" / "Hama".
  final String diseaseType;

  /// Penyebab penyakit.
  ///
  /// Belum ditampilkan di layar mana pun: design hanya memuat nama, nama
  /// ilmiah, tingkat keyakinan, dan langkah penanganan. Tetap disimpan karena
  /// ini bagian wajar dari satu hasil diagnosis dan akan dipakai saat backend
  /// atau halaman detail penyakit dibuat.
  final String cause;

  /// Daftar gejala. Lihat catatan pada [cause] — juga belum ditampilkan.
  final List<String> symptoms;

  /// Langkah penanganan yang digambar sebagai garis waktu di drawer hasil.
  final List<DiseaseStep> steps;

  /// Tingkat keyakinan 0–1.
  final double confidence;

  /// Tingkat keparahan, mis. "Ringan" / "Sedang" / "Berat".
  final String severity;

  /// Foto daun/tanaman yang dianalisis.
  final String? photoAsset;

  /// Teks persentase siap tampil, mis. "94%".
  String get confidenceLabel => '${(confidence * 100).round()}%';

  factory Disease.fromJson(Map<String, dynamic> json) => Disease(
    name: json['name'] as String,
    scientificName: json['scientificName'] as String,
    diseaseType: json['diseaseType'] as String,
    cause: json['cause'] as String,
    symptoms: (json['symptoms'] as List? ?? []).cast<String>(),
    steps: (json['steps'] as List? ?? [])
        .map((e) => DiseaseStep.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    confidence: (json['confidence'] as num).toDouble(),
    severity: json['severity'] as String,
    photoAsset: json['photoAsset'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'scientificName': scientificName,
    'diseaseType': diseaseType,
    'cause': cause,
    'symptoms': symptoms,
    'steps': [for (final s in steps) s.toJson()],
    'confidence': confidence,
    'severity': severity,
    'photoAsset': photoAsset,
  };
}
