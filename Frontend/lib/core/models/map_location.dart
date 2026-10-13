import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Lokasi penanaman (langkah 1 wizard tambah tanaman).
///
/// Koordinatnya dipakai peta sungguhan ([AgroMap]) sehingga pilihan di daftar
/// dan titik di peta selalu sama — dulu daftarnya hanya nama + alamat tanpa
/// koordinat, jadi peta tak bisa mengikuti pilihan pengguna.
@immutable
class MapLocation {
  const MapLocation({
    required this.name,
    required this.address,
    required this.position,
  });

  final String name;
  final String address;
  final LatLng position;

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
    name: json['name'] as String,
    address: json['address'] as String,
    position: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'lat': position.latitude,
    'lng': position.longitude,
  };
}
