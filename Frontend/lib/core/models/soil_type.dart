import 'package:flutter/material.dart';

/// Jenis tanah (langkah 3 wizard tambah tanaman).
@immutable
class SoilType {
  const SoilType({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.phRange = '-',
    this.bestFor = const [],
  });

  final String id;
  final String name;
  final String description;
  final String iconAsset;

  /// Rentang pH tanah, mis. "6.0 - 7.0".
  final String phRange;

  /// Jenis tanaman yang cocok dengan tanah ini.
  final List<String> bestFor;

  factory SoilType.fromJson(Map<String, dynamic> json) => SoilType(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    iconAsset: json['iconAsset'] as String,
    phRange: json['phRange'] as String? ?? '-',
    bestFor: (json['bestFor'] as List? ?? []).cast<String>(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconAsset': iconAsset,
    'phRange': phRange,
    'bestFor': bestFor,
  };
}
