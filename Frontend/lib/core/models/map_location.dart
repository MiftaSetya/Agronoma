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
    required this.city,
    required this.province,
  });

  final String name;
  final String address;
  final LatLng position;

  /// Kota dan provinsi terpisah dari [address]: endpoint AI
  /// (`/plant-recommendations`, `/plant-suitability`) dan `POST /plants`
  /// menuntut keduanya sebagai field sendiri, sedangkan design hanya
  /// menggambar satu blok alamat.
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
