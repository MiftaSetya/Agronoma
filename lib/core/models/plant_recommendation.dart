import 'package:flutter/material.dart';

import 'soil_type.dart';

/// Satu rekomendasi tanaman dari langkah 4 wizard tambah tanaman.
///
/// Ini hasil "AI Recommendation": daftar tanaman yang cocok dengan lokasi,
/// media tanam, dan jenis tanah yang sudah dipilih pengguna.
///
/// Di design kartunya cuma menampilkan empat hal: foto, nama, dua chip, dan
/// deskripsi. Model yang lama menyimpan `suitability`, `difficulty`, dan
/// `harvestAge`, tetapi ketiganya **tidak pernah tampil** pada frame itu —
/// angka kesesuaian hanya menambah data yang tidak terpakai, jadi dihapus.
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

  /// Chip di bawah nama tanaman.
  ///
  /// Design menampilkan satu chip "Pilihan Terbaik" berlatar kuning di kartu
  /// yang paling sesuai, lalu nol atau dua chip `Indoor`/`Outdoor`. Tag lain
  /// yang tidak ada di design sengaja tidak dimodelkan — chip-nya memang bukan
  /// daftar bebas, melainkan tiga varian tetap itu.
  final List<String> tags;

  /// Kartu ini ditandai "Pilihan Terbaik".
  bool get bestFor => tags.contains(bestForTag);

  /// Nilai tag yang menandai "Pilihan Terbaik".
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

/// Data yang dikumpulkan sepanjang wizard "Tambah Tanaman".
///
/// Dipegang oleh [AddPlantController] supaya setiap langkah bisa membaca
/// pilihan langkah sebelumnya tanpa harus melempar argumen lewat rute.
@immutable
class AddPlantDraft {
  const AddPlantDraft({
    this.locationName,
    this.locationAddress,
    this.locationConfirmed = false,
    this.media,
    this.soil,
    this.soilDetected = false,
    this.recommendation,
    this.manualName,
    this.manualScientificName,
    this.phase,
  });

  /// Nama tempat, mis. "Politeknik Elektronika Negeri Surabaya".
  final String? locationName;

  /// Alamat lengkap hasil pencarian lokasi.
  final String? locationAddress;

  /// Pengguna sudah menekan "Konfirmasi Lokasi".
  final bool locationConfirmed;

  final String? media;
  final SoilType? soil;

  /// Tanah sudah dianalisis lewat kamera.
  final bool soilDetected;

  final PlantRecommendation? recommendation;

  /// Nama tanaman yang diisi manual (langkah "Tambah manual tanaman").
  final String? manualName;
  final String? manualScientificName;

  final String? phase;

  /// Langkah 1 selesai: lokasi sudah dikonfirmasi.
  bool get hasLocation => locationConfirmed || locationName != null;

  /// Langkah 2 selesai: media tanam sudah dipilih.
  bool get hasMedia => media != null;

  /// Langkah 3 selesai: tanah sudah ditentukan (pilih atau analisis).
  bool get hasSoil => soil != null || soilDetected;

  /// Langkah 4 selesai: tanaman sudah dipilih atau diisi manual.
  bool get hasPlant => recommendation != null || manualName != null;

  /// Nama tanaman yang akan disimpan.
  String get resolvedName =>
      manualName ?? recommendation?.name ?? 'Tanaman Baru';

  AddPlantDraft copyWith({
    String? locationName,
    String? locationAddress,
    bool? locationConfirmed,
    String? media,
    SoilType? soil,
    bool? soilDetected,
    PlantRecommendation? recommendation,
    String? manualName,
    String? manualScientificName,
    String? phase,
  }) => AddPlantDraft(
    locationName: locationName ?? this.locationName,
    locationAddress: locationAddress ?? this.locationAddress,
    locationConfirmed: locationConfirmed ?? this.locationConfirmed,
    media: media ?? this.media,
    soil: soil ?? this.soil,
    soilDetected: soilDetected ?? this.soilDetected,
    recommendation: recommendation ?? this.recommendation,
    manualName: manualName ?? this.manualName,
    manualScientificName: manualScientificName ?? this.manualScientificName,
    phase: phase ?? this.phase,
  );
}
