import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

@immutable
class MapLocation {
  const MapLocation({
    required this.name,
    required this.address,
    required this.position,
    required this.city,
    required this.province,
  });

  final String name;
  final String address;
  final LatLng position;

  final String city;
  final String province;

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
    name: json['name'] as String,
    address: json['address'] as String,
    position: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    ),
    city: json['city'] as String,
    province: json['province'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'lat': position.latitude,
    'lng': position.longitude,
    'city': city,
    'province': province,
  };
}
