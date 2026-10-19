import 'package:flutter/foundation.dart';

@immutable
class PlantLocation {
  const PlantLocation({
    required this.id,
    required this.label,
    required this.city,
    required this.province,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String label;
  final String city;
  final String province;

  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get region => province.trim().isEmpty ? city : '$city, $province';

  factory PlantLocation.fromJson(Map<String, dynamic> json) => PlantLocation(
    id: (json['id'] as num).toInt(),
    label: (json['label'] as String? ?? '').trim(),
    city: (json['city'] as String? ?? '').trim(),
    province: (json['province'] as String? ?? '').trim(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'city': city,
    'province': province,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantLocation && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}
