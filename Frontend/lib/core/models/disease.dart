import 'package:flutter/material.dart';

/// Penanganan dimodelkan sebagai pasangan judul+paragraf karena di design
/// (`Disease Drawer`, node `253:2575`) langkahnya digambar sebagai garis
/// waktu bernomor, bukan daftar teks biasa.
@immutable
class DiseaseStep {
  const DiseaseStep({required this.title, required this.detail});

  final String title;
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

  /// Penyebab penyakit; belum tampil di layar mana pun, tetap disimpan
  /// sebagai bagian wajar dari satu hasil diagnosis untuk backend/detail
  /// penyakit nanti.
  final String cause;

  /// Daftar gejala; juga belum ditampilkan (lihat [cause]).
  final List<String> symptoms;

  /// Digambar sebagai garis waktu di drawer hasil.
  final List<DiseaseStep> steps;

  /// Tingkat keyakinan 0–1.
  final double confidence;

  /// Tingkat keparahan, mis. "Ringan" / "Sedang" / "Berat".
  final String severity;

  final String? photoAsset;

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
