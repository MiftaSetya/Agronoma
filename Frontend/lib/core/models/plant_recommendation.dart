import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'soil_type.dart';

/// Satu rekomendasi tanaman dari langkah 4 wizard "Tambah Tanaman" (hasil
/// "AI Recommendation"). Kartu design hanya menampilkan foto, nama, dua chip,
/// dan deskripsi — `suitability`, `difficulty`, dan `harvestAge` lama
/// sengaja dihapus karena tidak pernah tampil di frame itu.
@immutable
class PlantRecommendation {
  const PlantRecommendation({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.description,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String photoAsset;
  final String description;

  /// Chip di bawah nama. Bukan daftar bebas: design hanya punya tiga varian —
  /// "Pilihan Terbaik" (kartu paling sesuai), lalu `Indoor`/`Outdoor`.
  final List<String> tags;

  bool get bestFor => tags.contains(bestForTag);

  static const String bestForTag = 'Pilihan Terbaik';

  factory PlantRecommendation.fromJson(Map<String, dynamic> json) =>
      PlantRecommendation(
        id: json['id'] as String,
        name: json['name'] as String,
        photoAsset: json['photoAsset'] as String,
        description: json['description'] as String,
        tags: (json['tags'] as List? ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoAsset': photoAsset,
    'description': description,
    'tags': tags,
  };
}

/// Data yang dikumpulkan sepanjang wizard "Tambah Tanaman"; dipegang oleh
/// [AddPlantController] agar tiap langkah bisa membaca pilihan sebelumnya
/// tanpa melempar argumen lewat rute.
@immutable
class AddPlantDraft {
  const AddPlantDraft({
    this.locationName,
    this.locationAddress,
    this.locationPosition,
    this.locationConfirmed = false,
    this.media,
    this.soil,
    this.soilDetected = false,
    this.soilPhotoPath,
    this.recommendation,
    this.manualName,
    this.manualScientificName,
    this.phase,
  });

  final String? locationName;
  final String? locationAddress;

  /// Titik yang dipilih di peta. Bisa berasal dari lokasi contoh mana pun atau
  /// titik bebas hasil menggeser peta; disimpan supaya pilihan itu tidak hilang
  /// saat berpindah langkah.
  final LatLng? locationPosition;

  /// Pengguna sudah menekan "Konfirmasi Lokasi".
  final bool locationConfirmed;

  final String? media;
  final SoilType? soil;

  /// Tanah sudah dianalisis lewat kamera.
  final bool soilDetected;

  /// Berkas foto tanah hasil kamera (null bila mode contoh). Disimpan supaya
  /// analisis sungguhan bisa dikirim ke backend tanpa memotret ulang.
  final String? soilPhotoPath;

  final PlantRecommendation? recommendation;

  /// Nama tanaman yang diisi manual (langkah "Tambah manual tanaman").
  final String? manualName;
  final String? manualScientificName;

  final String? phase;

  bool get hasLocation => locationConfirmed || locationName != null;
  bool get hasMedia => media != null;
  bool get hasSoil => soil != null || soilDetected;
  bool get hasPlant => recommendation != null || manualName != null;

  String get resolvedName =>
      manualName ?? recommendation?.name ?? 'Tanaman Baru';

  AddPlantDraft copyWith({
    String? locationName,
    String? locationAddress,
    LatLng? locationPosition,
    bool? locationConfirmed,
    String? media,
    SoilType? soil,
    bool? soilDetected,
    String? soilPhotoPath,
    PlantRecommendation? recommendation,
    String? manualName,
    String? manualScientificName,
    String? phase,
  }) => AddPlantDraft(
    locationName: locationName ?? this.locationName,
    locationAddress: locationAddress ?? this.locationAddress,
    locationPosition: locationPosition ?? this.locationPosition,
    locationConfirmed: locationConfirmed ?? this.locationConfirmed,
    media: media ?? this.media,
    soil: soil ?? this.soil,
    soilDetected: soilDetected ?? this.soilDetected,
    soilPhotoPath: soilPhotoPath ?? this.soilPhotoPath,
    recommendation: recommendation ?? this.recommendation,
    manualName: manualName ?? this.manualName,
    manualScientificName: manualScientificName ?? this.manualScientificName,
    phase: phase ?? this.phase,
  );
}
