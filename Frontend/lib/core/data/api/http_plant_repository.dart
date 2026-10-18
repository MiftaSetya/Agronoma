import 'package:frontend/core/data/api/api_client.dart';
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
    final body = await _api.get('plants');
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
  Future<List<CareDay>> careDays(Plant plant, {required DateTime today}) async {
    final month = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    final body = await _api.get(
      'plants/${plant.id}/care-calendar',
      query: {'month': month},
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
    if (done) {
      await _api.post(
        kind == CareTaskKind.fertilizing
            ? 'plants/$plantId/fertilizing/complete'
            : 'plants/$plantId/watering/complete',
        timeout: _actionTimeout,
      );
    }
    return getPlant(plantId);
  }

  @override
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async {
    final body = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      body['plant_name'] = name.trim();
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
