import 'package:flutter/material.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.photoAsset,
    required this.totalPlants,
    required this.harvestedThisSeason,
    this.photoUrl,
    this.wateringReminderEnabled = true,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;

  final String photoAsset;

  final String? photoUrl;

  final int totalPlants;
  final int harvestedThisSeason;

  final bool wateringReminderEnabled;

  final DateTime? joinedAt;

  AppUser copyWith({
    int? totalPlants,
    int? harvestedThisSeason,
    String? photoUrl,
    bool clearPhotoUrl = false,
    bool? wateringReminderEnabled,
  }) => AppUser(
    id: id,
    name: name,
    email: email,
    photoAsset: photoAsset,
    photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    totalPlants: totalPlants ?? this.totalPlants,
    harvestedThisSeason: harvestedThisSeason ?? this.harvestedThisSeason,
    wateringReminderEnabled:
        wateringReminderEnabled ?? this.wateringReminderEnabled,
    joinedAt: joinedAt,
  );

  String get firstName => name.split(' ').first;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    photoAsset: json['photoAsset'] as String,
    photoUrl: json['photoUrl'] as String?,
    totalPlants: (json['totalPlants'] as num).toInt(),
    harvestedThisSeason: (json['harvestedThisSeason'] as num).toInt(),
    wateringReminderEnabled: (json['wateringReminderEnabled'] as bool?) ?? true,
    joinedAt: json['joinedAt'] == null
        ? null
        : DateTime.parse(json['joinedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photoAsset': photoAsset,
    'photoUrl': photoUrl,
    'totalPlants': totalPlants,
    'harvestedThisSeason': harvestedThisSeason,
    'wateringReminderEnabled': wateringReminderEnabled,
    'joinedAt': joinedAt?.toIso8601String(),
  };
}
