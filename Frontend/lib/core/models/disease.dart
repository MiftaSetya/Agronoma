import 'package:flutter/material.dart';

/// Hasil deteksi penyakit tanaman.
@immutable
class Disease {
  const Disease({
    required this.name,
    required this.scientificName,
    required this.diseaseType,
    required this.cause,
    required this.symptoms,
    required this.treatment,
    required this.confidence,
    required this.severity,
    this.photoAsset,
  });

  final String name;
  final String scientificName;

  /// Jenis, mis. "Jamur" / "Bakteri" / "Hama".
  final String diseaseType;

  final String cause;
  final List<String> symptoms;
  final List<String> treatment;

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
    treatment: (json['treatment'] as List? ?? []).cast<String>(),
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
    'treatment': treatment,
    'confidence': confidence,
    'severity': severity,
    'photoAsset': photoAsset,
  };
}
