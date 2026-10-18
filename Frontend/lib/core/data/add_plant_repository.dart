import 'dart:io';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/api/plant_mapper.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_catalog.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_location.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/plant_suitability.dart';
import 'package:frontend/core/models/soil_type.dart';

abstract class AddPlantRepository {
  Future<List<SoilType>> getSoilTypes();

  Future<SoilScanResult> scanSoil({String? imagePath});

  Future<List<PlantLocation>> getLocations();

  Future<PlantLocation> createLocation({
    required String label,
    required String city,
    required String province,
  });

  Future<PlantLocation> updateLocation(
    int id, {
    required String label,
    required String city,
    required String province,
  });

  Future<void> deleteLocation(int id);

  Future<PlantSuitability> checkSuitability({
    required String plantName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  });

  Future<List<PlantRecommendation>> getRecommendations({
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  });

  Future<Plant> createPlant({
    required String name,
    String? scientificName,
    required PlantingMedia media,
    required SoilType soil,
    required int locationId,
    required String city,
    required String province,
    required String locationLabel,
    required GrowthPhase phase,
    String? description,
    DateTime? plantingDate,
  });
}

class HttpAddPlantRepository implements AddPlantRepository {
  HttpAddPlantRepository({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  static const Duration aiTimeout = Duration(seconds: 120);

  @override
  Future<List<SoilType>> getSoilTypes() async => SoilCatalog.types;

  @override
  Future<List<PlantLocation>> getLocations() async {
    final body = await _client.get('locations');
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) PlantLocation.fromJson(item),
    ];
  }

  @override
  Future<PlantLocation> createLocation({
    required String label,
    required String city,
    required String province,
  }) async {
    final body = await _json('locations', {
      'label': label.trim(),
      'city': city.trim(),
      'province': province.trim().isEmpty ? null : province.trim(),
    });

    final raw = body['location'];
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Lokasi tanam gagal disimpan.',
        statusCode: 500,
      );
    }

    return PlantLocation.fromJson(raw);
  }

  @override
  Future<PlantLocation> updateLocation(
    int id, {
    required String label,
    required String city,
    required String province,
  }) async {
    final raw = await _client.patch(
      'locations/$id',
      body: {
        'label': label.trim(),
        'city': city.trim(),
        'province': province.trim().isEmpty ? null : province.trim(),
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Lokasi tanam gagal diperbarui.',
        statusCode: 500,
      );
    }

    final updated = raw['location'];
    if (updated is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Lokasi tanam gagal diperbarui.',
        statusCode: 500,
      );
    }

    return PlantLocation.fromJson(updated);
  }

  @override
  Future<void> deleteLocation(int id) async {
    await _client.delete('locations/$id');
  }

  @override
  Future<PlantSuitability> checkSuitability({
    required String plantName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  }) async {
    final body = await _json('plant-suitability', {
      'plant_name': plantName.trim(),
      'planting_medium': BackendCodes.plantingMedium(media),
      'soil_type': BackendCodes.soilType(soil),
      'city': city,
      'province': province,
    });

    if (body['plant_name'] is! String && body['verdict'] is! String) {
      throw const ApiException(
        message: 'Evaluasi kesesuaian tidak berhasil dibuat.',
        statusCode: 500,
      );
    }

    return PlantSuitability.fromJson(body);
  }

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
      for (final (index, raw) in items.indexed) _toRecommendation(raw, index),
    ];
  }

  @override
  Future<Plant> createPlant({
    required String name,
    String? scientificName,
    required PlantingMedia media,
    required SoilType soil,
    required int locationId,
    required String city,
    required String province,
    required String locationLabel,
    required GrowthPhase phase,
    String? description,
    DateTime? plantingDate,
  }) async {
    final planting = plantingDate ?? DateTime.now();
    final body = await _json('plants', {
      'location_id': locationId,
      'plant_name': name,
      'planting_medium': BackendCodes.plantingMedium(media),
      'soil_type': BackendCodes.soilType(soil),
      'current_phase': BackendCodes.phase(phase),
      'planting_date': _dateOnly(planting),
    }, timeout: aiTimeout);

    final plant = body['plant'];
    if (plant is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Tanaman tersimpan, tetapi balasannya tidak dikenali.',
        statusCode: 500,
      );
    }

    return _toPlant(
      plant,
      scientificName: scientificName,
      description: description,
      locationLabel: locationLabel,
    );
  }

  Future<Map<String, dynamic>> _json(
    String path,
    Object body, {
    Duration? timeout,
  }) async {
    final raw = await _client.post(
      path,
      body: body,
      timeout: timeout ?? aiTimeout,
    );
    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Balasan server tidak dikenali.',
        statusCode: 500,
      );
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
      throw const ApiException(
        message: 'Balasan server tidak dikenali.',
        statusCode: 500,
      );
    }
    return raw;
  }

  PlantRecommendation _toRecommendation(Object? raw, int index) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final name = (json['plant_name'] as String? ?? 'Tanaman').trim();
    final visual = PlantCatalog.find(name);
    final rank = json['rank'] is int ? json['rank'] as int : index + 1;

    return PlantRecommendation(
      id: 'ai-$rank-${name.toLowerCase()}',
      name: name,
      photoAsset: visual?.photoAsset ?? PlantCatalog.fallbackPhoto,
      description: (json['reasoning'] as String? ?? '').trim(),
      tags: [if (rank == 1) PlantRecommendation.bestForTag, ...?visual?.tags],
    );
  }

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

class SampleAddPlantRepository implements AddPlantRepository {
  SampleAddPlantRepository();

  static const Duration _latency = Duration(milliseconds: 900);

  final List<PlantLocation> _locations = [
    const PlantLocation(
      id: 1,
      label: 'Politeknik Elektronika Negeri Surabaya',
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
    const PlantLocation(
      id: 2,
      label: 'Kebun Bibit Wonorejo',
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
    const PlantLocation(
      id: 3,
      label: 'Rumah Kaca Sukolilo',
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
  ];

  @override
  Future<List<SoilType>> getSoilTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return SoilCatalog.types;
  }

  @override
  Future<List<PlantLocation>> getLocations() async => List.of(_locations);

  @override
  Future<PlantLocation> createLocation({
    required String label,
    required String city,
    required String province,
  }) async {
    final created = PlantLocation(
      id: _locations.length + 1,
      label: label.trim(),
      city: city.trim(),
      province: province.trim(),
    );
    _locations.insert(0, created);
    return created;
  }

  @override
  Future<PlantLocation> updateLocation(
    int id, {
    required String label,
    required String city,
    required String province,
  }) async {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw ApiException(
        message: 'Lokasi tidak ditemukan.',
        statusCode: 404,
      );
    }

    final updated = PlantLocation(
      id: id,
      label: label.trim(),
      city: city.trim(),
      province: province.trim(),
    );
    _locations[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteLocation(int id) async {
    _locations.removeWhere((l) => l.id == id);
  }

  @override
  Future<PlantSuitability> checkSuitability({
    required String plantName,
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  }) async {
    await Future<void>.delayed(_latency);
    return PlantSuitability(
      plantName: plantName.trim(),
      verdict: PlantSuitabilityVerdict.suitable,
      climateFit: 88,
      productivity: 90,
      easeOfCare: 84,
      reasoning:
          '$plantName cocok ditanam di $city pada media '
          '${media.label} dengan tanah ${soil.name}.',
      alternativeSuggestion: null,
    );
  }

  @override
  Future<SoilScanResult> scanSoil({String? imagePath}) async {
    await Future<void>.delayed(_latency);

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
    required int locationId,
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

      tasks: const [],
    );
  }
}
