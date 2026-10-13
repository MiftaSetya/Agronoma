import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Antarmuka sumber data tanaman — satu-satunya tempat yang tahu asal data;
/// nanti cukup tambahkan `HttpPlantRepository` dan tukar di `main.dart`
/// tanpa menyentuh widget mana pun.
abstract class PlantRepository {
  Future<List<Plant>> getPlants();
  Future<Plant> getPlant(String id);
  Future<Plant> addPlant({
    required String name,
    String? scientificName,
    required String location,
    required SoilType soil,
    String? phase,
  });
  Future<Plant> setTaskDone(String plantId, String taskTitle, bool done);
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  });
  Future<List<PlantRecommendation>> getRecommendations({
    required String location,
    required SoilType soil,
  });
  Future<List<SoilType>> getSoilTypes();
}

/// Implementasi contoh dari [MockData] di memori; perubahan (tambah tanaman,
/// tandai tugas) tersimpan selama aplikasi hidup sehingga wizard bisa dicoba
/// sampai selesai.
class MockPlantRepository implements PlantRepository {
  MockPlantRepository();

  final List<Plant> _plants = [...MockData.plants];

  /// Jeda buatan supaya indikator loading benar-benar terlihat.
  static const Duration _latency = Duration(milliseconds: 900);

  /// Jenis tanah paling kaya bahan organik pada daftar design, jadi satu-satunya
  /// yang diberi pupuk organik. Dicocokkan lewat [SoilType.id] — nama tanah
  /// adalah teks design yang bisa berubah kapan saja.
  static const String _organicSoilId = 's2';

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
  Future<Plant> addPlant({
    required String name,
    String? scientificName,
    required String location,
    required SoilType soil,
    String? phase,
  }) async {
    await Future<void>.delayed(_latency);
    final source = MockData.recommendations.firstWhere(
      (r) => r.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MockData.recommendations.first,
    );
    final plant = Plant(
      id: 'p${_plants.length + 1}-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      scientificName: scientificName,
      photoAsset: source.photoAsset,
      location: location,
      place: 'Pekarangan Rumah',
      media: PlantingMedia.pot,
      status: CareStatus.safe,
      phase: GrowthPhase.values.firstWhere(
        (g) => g.name == phase,
        orElse: () => GrowthPhase.seedling,
      ),
      plantedAt: DateTime.now(),
      careScore: 100,
      description: source.description,
      tags: const ['Indoor'],
      fertilizer: soil.id == _organicSoilId ? 'NPK Organik' : 'NPK Daun',
      soilName: soil.name,
      // Tanaman baru selalu mulai dari nol: belum ada jadwal perawatan dan
      // belum ada tonggak pertumbuhan yang terlewati.
      tasks: const [],
      timeline: const [],
    );
    _plants.add(plant);
    return plant;
  }

  @override
  Future<Plant> setTaskDone(
    String plantId,
    String taskTitle,
    bool done,
  ) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index < 0) return _plants.first;
    final plant = _plants[index];
    final updated = plant.copyWith(
      tasks: [
        for (final t in plant.tasks)
          if (t.title == taskTitle) t.copyWith(done: done) else t,
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
      place: place,
      phase: phase,
      soilName: soilName,
    );
    _plants[index] = updated;
    return updated;
  }

  @override
  Future<List<PlantRecommendation>> getRecommendations({
    required String location,
    required SoilType soil,
  }) async {
    await Future<void>.delayed(_latency);
    return MockData.recommendations;
  }

  @override
  Future<List<SoilType>> getSoilTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.soilTypes;
  }
}
