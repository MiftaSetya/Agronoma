import 'dart:io';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/api/plant_mapper.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_catalog.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Sumber data **khusus wizard "Tambah Tanaman"** (langkah 3–5).
///
/// Dipisahkan dari [PlantRepository] yang mengurus daftar tanaman: keempat
/// operasi di sini memerlukan backend AI (`/soil-scan`, `/plant-recommendations`,
/// `/locations`, `/plants`) sedangkan daftar tanaman masih dibaca dari
/// [MockPlantRepository] sampai slice berikutnya menggantinya. Pemisahan ini
/// membuat wizard bisa tersambung penuh tanpa memaksa Home/Detail pindah sekaligus.
///
/// [PlantRepository]: ../plant_repository.dart
abstract class AddPlantRepository {
  /// Tujuh jenis tanah design; lihat [SoilCatalog] — endpoint daftar tanah
  /// tidak ada di backend karena itu memang katalog tampilan, bukan data.
  Future<List<SoilType>> getSoilTypes();

  /// `POST /soil-scan`. [imagePath] adalah berkas hasil jepretan kamera
  /// (`null` hanya pada mode contoh, karena pratinjau design tidak menyentuh
  /// kamera).
  Future<SoilScanResult> scanSoil({String? imagePath});

  /// `POST /plant-recommendations` — dijalankan saat langkah 4 dibuka.
  Future<List<PlantRecommendation>> getRecommendations({
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  });

  /// Menyimpan tanaman lewat `POST /plants` (lokasinya dibuat lebih dulu bila
  /// belum ada). [description] diisi teks `reasoning` rekomendasi AI supaya
  /// Detail Tanaman menampilkan kalimat sungguhan, bukan isian hampa.
  Future<Plant> createPlant({
    required String name,
    String? scientificName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
    required String locationLabel,
    required GrowthPhase phase,
    String? description,
    DateTime? plantingDate,
  });
}

/// Implementasi sungguhan di atas [ApiClient].
class HttpAddPlantRepository implements AddPlantRepository {
  HttpAddPlantRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  /// Tiga endpoint di repositori ini memanggil model bahasa (dua di antaranya
  /// dengan *grounding* Google Search) sehingga bisa memakan puluhan detik.
  /// Waktu tunggu bawaan [ApiClient] (30 detik) terlalu pendek dan akan
  /// memunculkan "Server tidak merespons" padahal permintaannya sedang diproses.
  static const Duration aiTimeout = Duration(seconds: 120);

  /// Lokasi terakhir yang dibuat **untuk instance ini**, dipakai ulang bila
  /// kota/provinsinya sama. Semua lokasi contoh design berada di Surabaya,
  /// jadi tanpa cache ini setiap tanaman baru akan menumpuk baris lokasi yang
  /// sama di backend.
  int? _locationId;
  String? _locationKey;

  @override
  Future<List<SoilType>> getSoilTypes() async => SoilCatalog.types;

  @override
  Future<SoilScanResult> scanSoil({String? imagePath}) async {
    if (imagePath == null) {
      throw const ApiException(
        message: 'Foto tanah tidak tersedia, jadi belum bisa dianalisis.',
      );
    }

    final file = File(imagePath);
    final body = await _multipart(
      'soil-scan',
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
    );

    final code = body['detected_soil_type'] as String?;
    if (code == null) {
      throw const ApiException(
        message: 'Jenis tanah pada foto itu tidak berhasil dikenali.',
      );
    }

    final raw = body['ai_confidence'];
    return SoilScanResult(
      soil: SoilCatalog.byCode(code),
      // Backend mengirim keyakinan 0–100; UI memakainya sebagai 0..1.
      confidence: raw is num ? (raw / 100).clamp(0, 1).toDouble() : 0,
    );
  }

  @override
  Future<List<PlantRecommendation>> getRecommendations({
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  }) async {
    final body = await _json('plant-recommendations', {
      'planting_medium': BackendCodes.plantingMedium(media),
      'soil_type': BackendCodes.soilType(soil),
      'city': city,
      'province': province,
    });

    final items = (body['recommendations'] as List?) ?? const [];
    return [
      for (final (index, raw) in items.indexed)
        _toRecommendation(raw, index),
    ];
  }

  @override
  Future<Plant> createPlant({
    required String name,
    String? scientificName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
    required String locationLabel,
    required GrowthPhase phase,
    String? description,
    DateTime? plantingDate,
  }) async {
    final locationId = await _ensureLocation(
      label: locationLabel,
      city: city,
      province: province,
    );

    final planting = plantingDate ?? DateTime.now();
    final body = await _json(
      'plants',
      {
        'location_id': locationId,
        'plant_name': name,
        'planting_medium': BackendCodes.plantingMedium(media),
        'soil_type': BackendCodes.soilType(soil),
        'current_phase': BackendCodes.phase(phase),
        'planting_date': _dateOnly(planting),
      },
      timeout: aiTimeout,
    );

    final plant = body['plant'];
    if (plant is! Map<String, dynamic>) {
      throw const ApiException(message: 'Tanaman tersimpan, tetapi balasannya tidak dikenali.', statusCode: 500);
    }

    return _toPlant(
      plant,
      scientificName: scientificName,
      description: description,
      locationLabel: locationLabel,
    );
  }

  /// Membuat lokasi sekali per (kota, provinsi); `POST /plants` menuntut
  /// `location_id` milik pengguna, sedangkan wizard hanya menyimpan nama tempat.
  Future<int> _ensureLocation({
    required String label,
    required String city,
    required String province,
  }) async {
    final key = '$label|$city|$province';
    final cached = _locationId;
    if (cached != null && _locationKey == key) return cached;

    final body = await _json('locations', {
      'label': label,
      'city': city,
      'province': province,
    });

    final location = body['location'];
    final id = location is Map<String, dynamic> ? location['id'] : null;
    if (id is! int) {
      throw const ApiException(message: 'Lokasi tanam gagal disimpan.', statusCode: 500);
    }

    _locationId = id;
    _locationKey = key;
    return id;
  }

  Future<Map<String, dynamic>> _json(
    String path,
    Object body, {
    Duration? timeout,
  }) async {
    final raw = await _client.post(path, body: body, timeout: timeout ?? aiTimeout);
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Balasan server tidak dikenali.', statusCode: 500);
    }
    return raw;
  }

  Future<Map<String, dynamic>> _multipart(
    String path, {
    required List<int> bytes,
    required String filename,
  }) async {
    final raw = await _client.postMultipart(
      path,
      field: 'image',
      bytes: bytes,
      filename: filename,
      timeout: aiTimeout,
    );
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(message: 'Balasan server tidak dikenali.', statusCode: 500);
    }
    return raw;
  }

  /// `plant_name`, `scores`, `reasoning`, `rank` — foto dan chip ruang tidak
  /// dikirim backend, jadi diambil dari [PlantCatalog]. Kartu bernilai `rank` 1
  /// saja yang diberi chip "Pilihan Terbaik": pada data contoh chip itu memang
  /// menandai kartu paling sesuai.
  PlantRecommendation _toRecommendation(Object? raw, int index) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final name = (json['plant_name'] as String? ?? 'Tanaman').trim();
    final visual = PlantCatalog.find(name);
    final rank = json['rank'] is int ? json['rank'] as int : index + 1;

    return PlantRecommendation(
      // Dipakai untuk mencocokkan kartu terpilih, jadi harus stabil antar-build.
      id: 'ai-$rank-${name.toLowerCase()}',
      name: name,
      photoAsset: visual?.photoAsset ?? PlantCatalog.fallbackPhoto,
      description: (json['reasoning'] as String? ?? '').trim(),
      tags: [
        if (rank == 1) PlantRecommendation.bestForTag,
        ...?visual?.tags,
      ],
    );
  }

  /// `UserPlantResource` tidak memuat foto, deskripsi, ataupun jadwal
  /// perawatan, jadi ketiganya diisi dari katalog dan teks yang sudah
  /// dikumpulkan wizard. Pemetaannya sendiri ada di `PlantMapper` supaya
  /// tanaman yang baru disimpan tampil sama dengan hasil `GET /plants`.
  Plant _toPlant(
    Map<String, dynamic> json, {
    required String? scientificName,
    required String? description,
    required String locationLabel,
  }) => PlantMapper.fromBackend(
    json,
    scientificName: scientificName,
    description: description,
    fallbackCity: locationLabel,
  );

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

/// Implementasi contoh (tanpa server) yang dipakai pratinjau design dan widget
/// test. Perilakunya sengaja dibuat sama dengan [MockPlantRepository] supaya
/// wizard tetap bisa ditelusuri sampai langkah 5 tanpa backend.
class SampleAddPlantRepository implements AddPlantRepository {
  SampleAddPlantRepository();

  /// Jeda buatan supaya indikator loading benar-benar terlihat.
  static const Duration _latency = Duration(milliseconds: 900);

  @override
  Future<List<SoilType>> getSoilTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return SoilCatalog.types;
  }

  @override
  Future<SoilScanResult> scanSoil({String? imagePath}) async {
    await Future<void>.delayed(_latency);
    // Hasil contoh: tanah gembur — jenis yang paling umum dipakai di design.
    return SoilScanResult(soil: SoilCatalog.types[1], confidence: 0.92);
  }

  @override
  Future<List<PlantRecommendation>> getRecommendations({
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  }) async {
    await Future<void>.delayed(_latency);
    return MockData.recommendations;
  }

  @override
  Future<Plant> createPlant({
    required String name,
    String? scientificName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
    required String locationLabel,
    required GrowthPhase phase,
    String? description,
    DateTime? plantingDate,
  }) async {
    await Future<void>.delayed(_latency);
    final source = MockData.recommendations.firstWhere(
      (r) => r.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MockData.recommendations.first,
    );
    final visual = PlantCatalog.find(name);

    return Plant(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      scientificName: scientificName,
      photoAsset: visual?.photoAsset ?? source.photoAsset,
      location: city,
      // Media tanam pilihan langkah 2 menentukan "MEDIA TANAM" di Detail
      // Tanaman; labelnya dipakai langsung supaya kartu dan wizard seragam.
      place: media.label,
      media: media,
      status: CareStatus.safe,
      phase: phase,
      plantedAt: plantingDate ?? DateTime.now(),
      careScore: 100,
      description: (description ?? '').trim().isEmpty
          ? source.description
          : description!.trim(),
      tags: visual?.tags ?? source.tags,
      fertilizer: soil.code == 'fertile' ? 'NPK Organik' : 'NPK Daun',
      soilName: soil.name,
      // Tanaman baru selalu mulai dari nol: belum ada jadwal perawatan dan
      // belum ada tonggak pertumbuhan yang terlewati.
      tasks: const [],
      timeline: const [],
    );
  }
}
