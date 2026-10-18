import 'dart:io';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/api/plant_mapper.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';

class HttpPlantRepository implements PlantRepository {
  HttpPlantRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const Duration _actionTimeout = Duration(seconds: 20);

  @override
  Future<List<Plant>> getPlants() async {
    final body = await _api.get('plants', query: {'status': 'active'});
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) PlantMapper.fromBackend(item),
    ];
  }

  @override
  Future<Plant> getPlant(String id) async {
    final body = await _api.get('plants/$id');
    final raw = body is Map<String, dynamic> ? body['plant'] : null;
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Balasan tanaman tidak dikenali.');
    }
    return PlantMapper.fromBackend(raw);
  }

  @override
  Future<String?> dashboardGreeting() async {
    try {
      final body = await _api.get('dashboard');
      return body is Map<String, dynamic>
          ? body['greeting'] as String?
          : null;
    } on ApiException {
      return null;
    }
  }

  @override
  Future<List<Plant>> getArchivedPlants() async {
    final body = await _api.get('plants', query: {'status': 'archived'});
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) PlantMapper.fromBackend(item),
    ];
  }

  @override
  Future<void> setArchived(String plantId, {required bool archived}) async {
    await _api.patch(
      'plants/$plantId',
      body: {'status': archived ? 'archived' : 'active'},
    );
  }

  @override
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {
    await _api.post(
      'watering-logs/$wateringLogId/rain-confirm',
      body: {'rain_confirmed': rained ? 'yes' : 'no'},
      timeout: _actionTimeout,
    );
  }

  @override
  Future<void> moistureFeedback(int wateringLogId, {required bool moist}) async {
    await _api.post(
      'watering-logs/$wateringLogId/moisture-feedback',
      body: {'user_moisture_feedback': moist ? 'moist' : 'dry'},
      timeout: _actionTimeout,
    );
  }

  @override
  Future<void> postponeWatering(String plantId) async {
    await _api.post(
      'plants/$plantId/watering/postpone',
      timeout: _actionTimeout,
    );
  }

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async {
    final target = month ??
        (() {
          final base = today ?? DateTime.now();
          return '${base.year}-${base.month.toString().padLeft(2, '0')}';
        })();
    final body = await _api.get(
      'plants/${plant.id}/care-calendar',
      query: {'month': target},
    );
    final raw = body is Map<String, dynamic> ? body['days'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) CareDay.fromJson(item),
    ];
  }

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    if (!done) {
      throw const ApiException(
        message: 'Perawatan yang sudah selesai tidak bisa dibatalkan.',
        statusCode: 409,
      );
    }

    await _api.post(
      kind == CareTaskKind.fertilizing
          ? 'plants/$plantId/fertilizing/complete'
          : 'plants/$plantId/watering/complete',
      timeout: _actionTimeout,
    );

    return getPlant(plantId);
  }

  @override
  Future<Plant> uploadPhoto(String plantId, String imagePath) async {
    final file = File(imagePath);
    final raw = await _api.postMultipart(
      'plants/$plantId/photo',
      field: 'image',
      bytes: await file.readAsBytes(),
      filename: file.uri.pathSegments.last,
      timeout: _actionTimeout,
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Foto tanaman gagal disimpan.',
        statusCode: 500,
      );
    }

    return getPlant(plantId);
  }

  @override
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    int? locationId,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async {
    final body = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      body['plant_name'] = name.trim();
    }
    if (locationId != null) {
      body['location_id'] = locationId;
    }
    if (phase != null) {
      body['current_phase'] = BackendCodes.phase(phase);
    }
    if (place != null) {
      final media = PlantingMedia.values.firstWhere(
        (m) => m.label == place,
        orElse: () => PlantingMedia.pot,
      );
      body['planting_medium'] = BackendCodes.plantingMedium(media);
    }
    if (soilName != null) {
      final soil = SoilCatalog.byName(soilName);
      if (soil != null) body['soil_type'] = soil.code;
    }

    if (body.isNotEmpty) {
      await _api.patch('plants/$plantId', body: body);
    }

    return getPlant(plantId);
  }
}
