import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';

abstract class PlantRepository {
  Future<List<Plant>> getPlants();
  Future<Plant> getPlant(String id);

  Future<String?> dashboardGreeting();

  Future<List<Plant>> getArchivedPlants();

  Future<void> setArchived(String plantId, {required bool archived});

  Future<void> confirmRain(int wateringLogId, {required bool rained});

  Future<void> moistureFeedback(
    int wateringLogId, {
    required bool moist,
  });

  Future<void> postponeWatering(String plantId);

  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  });

  Future<Plant> setTaskDone(String plantId, CareTaskKind kind, bool done);
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    int? locationId,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  });
}

class MockPlantRepository implements PlantRepository {
  MockPlantRepository();

  final List<Plant> _plants = [...MockData.plants];

  static const Duration _latency = Duration(milliseconds: 900);

  @override
  Future<List<Plant>> getPlants() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_plants);
  }

  @override
  Future<Plant> getPlant(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _plants.firstWhere((p) => p.id == id);
  }

  @override
  Future<String?> dashboardGreeting() async => null;

  @override
  Future<List<Plant>> getArchivedPlants() async => const [];

  @override
  Future<void> setArchived(String plantId, {required bool archived}) async {}

  @override
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {}

  @override
  Future<void> moistureFeedback(int wateringLogId, {required bool moist}) async {}

  @override
  Future<void> postponeWatering(String plantId) async {}

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [];
  }

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index < 0) return _plants.first;
    final plant = _plants[index];
    final updated = plant.copyWith(
      tasks: [
        for (final t in plant.tasks)
          if (t.kind == kind) t.copyWith(done: done) else t,
      ],
    );
    _plants[index] = updated;
    return updated;
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
    await Future<void>.delayed(_latency);
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index < 0) return _plants.first;
    final updated = _plants[index].copyWith(
      name: name,
      location: location,
      locationId: locationId,
      place: place,
      phase: phase,
      soilName: soilName,
    );
    _plants[index] = updated;
    return updated;
  }
}
