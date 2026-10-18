import 'package:flutter/foundation.dart';

@immutable
class SoilType {
  const SoilType({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.photoAsset,
  });

  final String id;

  final String code;

  final String name;
  final String description;

  final String photoAsset;

  factory SoilType.fromJson(Map<String, dynamic> json) => SoilType(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    photoAsset: json['photoAsset'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'photoAsset': photoAsset,
  };
}

@immutable
class SoilScanResult {
  const SoilScanResult({required this.soil, required this.confidence});

  final SoilType soil;

  final double confidence;

  int get confidencePercent => (confidence * 100).round();
}
