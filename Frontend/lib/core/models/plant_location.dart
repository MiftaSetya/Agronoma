import 'package:flutter/foundation.dart';

@immutable
class PlantLocation {
  const PlantLocation({
    required this.id,
    required this.label,
    required this.city,
    required this.province,
  });

  final int id;
  final String label;
  final String city;
  final String province;

  String get region => province.trim().isEmpty ? city : '$city, $province';

  factory PlantLocation.fromJson(Map<String, dynamic> json) => PlantLocation(
    id: (json['id'] as num).toInt(),
    label: (json['label'] as String? ?? '').trim(),
    city: (json['city'] as String? ?? '').trim(),
    province: (json['province'] as String? ?? '').trim(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'city': city,
    'province': province,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantLocation && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}
