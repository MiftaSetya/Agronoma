import 'package:flutter/material.dart';

/// Jenis tanah (langkah 3 wizard tambah tanaman).
///
/// Kartu design (`113:765`) hanya memuat foto 80px, nama, dan tiga baris
/// keterangan — `phRange` dan `bestFor` lama sengaja dihapus karena tidak
/// pernah tampil di frame mana pun.
@immutable
class SoilType {
  const SoilType({
    required this.id,
    required this.name,
    required this.description,
    required this.photoAsset,
  });

  final String id;
  final String name;
  final String description;

  /// Foto jenis tanah 80x80 pada kartu daftar.
  final String photoAsset;

  factory SoilType.fromJson(Map<String, dynamic> json) => SoilType(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    photoAsset: json['photoAsset'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'photoAsset': photoAsset,
  };
}
