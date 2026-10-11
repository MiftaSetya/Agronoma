import 'package:flutter/material.dart';

/// Data pengguna yang sedang masuk.
///
/// Sesi masih palsu (mock): [AuthController] membuatnya saat login berhasil.
/// Modelnya sudah berbentuk data nyata supaya penggantian ke autentikasi
/// sungguhan tidak mengubah UI.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.photoAsset,
    required this.totalPlants,
    required this.harvestedThisSeason,
    required this.careScore,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;

  /// Path aset foto profil.
  final String photoAsset;

  /// Jumlah tanaman yang sedang tumbuh.
  final int totalPlants;

  /// Jumlah tanaman yang sudah dipanen musim ini.
  final int harvestedThisSeason;

  /// Skor perawatan 0–100.
  final double careScore;

  final DateTime? joinedAt;

  /// Sebutan singkat pada sapaan Home, mis. "User".
  String get firstName => name.split(' ').first;

  /// Teks skor siap tampil, mis. "98%".
  String get careScoreLabel => '${careScore.round()}%';

  /// Deskripsi skor, mis. "Sangat baik".
  String get careScoreCaption => switch (careScore) {
    >= 90 => 'Sangat baik',
    >= 75 => 'Baik',
    >= 60 => 'Cukup',
    _ => 'Perlu ditingkatkan',
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    photoAsset: json['photoAsset'] as String,
    totalPlants: (json['totalPlants'] as num).toInt(),
    harvestedThisSeason: (json['harvestedThisSeason'] as num).toInt(),
    careScore: (json['careScore'] as num).toDouble(),
    joinedAt: json['joinedAt'] == null
        ? null
        : DateTime.parse(json['joinedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photoAsset': photoAsset,
    'totalPlants': totalPlants,
    'harvestedThisSeason': harvestedThisSeason,
    'careScore': careScore,
    'joinedAt': joinedAt?.toIso8601String(),
  };
}
