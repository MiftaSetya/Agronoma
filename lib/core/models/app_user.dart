import 'package:flutter/material.dart';

/// Data pengguna yang sedang masuk. Sesi masih mock, tapi bentuknya data
/// nyata supaya penggantian ke autentikasi sungguhan tidak menyentuh UI.
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

  /// Path aset lokal foto profil.
  final String photoAsset;

  final int totalPlants;
  final int harvestedThisSeason;

  /// Skor perawatan 0–100.
  final double careScore;

  final DateTime? joinedAt;

  String get firstName => name.split(' ').first;
  String get careScoreLabel => '${careScore.round()}%';
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
