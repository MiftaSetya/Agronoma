import 'package:flutter/material.dart';

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

  final String diseaseType;

  final String cause;

  final List<String> symptoms;

  final List<DiseaseStep> steps;

  final double confidence;

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
