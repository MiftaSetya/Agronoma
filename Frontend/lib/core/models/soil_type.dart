import 'package:flutter/foundation.dart';

/// Jenis tanah (langkah 3 wizard tambah tanaman).
///
/// Kartu design (`113:765`) hanya memuat foto 80px, nama, dan tiga baris
/// keterangan — `phRange` dan `bestFor` lama sengaja dihapus karena tidak
/// pernah tampil di frame mana pun.
@immutable
class SoilType {
  const SoilType({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.photoAsset,
  });

  final String id;

  /// Nilai enum `soil_type` milik backend (`fertile`, `clay`, `sandy`,
  /// `chalky`, `volcanic`, `peat`, `artificial_media`). Dipisahkan dari [id]
  /// karena [id] adalah kunci data design yang cuma stabil di aplikasi,
  /// sedangkan [code] adalah kontrak yang dipakai endpoint AI — hasil
  /// `POST /soil-scan` dikembalikan dalam bentuk [code] ini.
  final String code;

  final String name;
  final String description;

  /// Foto jenis tanah 80x80 pada kartu daftar.
  final String photoAsset;

  factory SoilType.fromJson(Map<String, dynamic> json) => SoilType(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    photoAsset: json['photoAsset'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'photoAsset': photoAsset,
  };
}

/// Hasil `POST /soil-scan` (langkah 3, tombol "Bantu Saya Scan Tanah").
///
/// Backend hanya membalas kode enum tanah + keyakinan model, jadi foto dan
/// keterangan tetap dipinjam dari katalog design lewat [soil].
@immutable
class SoilScanResult {
  const SoilScanResult({required this.soil, required this.confidence});

  final SoilType soil;

  /// Keyakinan model 0..1 (backend mengirim 0–100, dinormalkan di repositori).
  final double confidence;

  int get confidencePercent => (confidence * 100).round();
}
