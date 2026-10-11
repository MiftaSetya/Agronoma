import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Sumber data tanaman.
///
/// Ini satu-satunya tempat yang tahu dari mana data tanaman berasal. Saat
/// backend Agronoma tersedia, cukup tambahkan `HttpPlantRepository` yang
/// mengimplementasikan antarmuka ini dan tukar di `main.dart` — tidak ada
/// widget yang perlu disentuh.
abstract class PlantRepository {
  /// Semua tanaman yang sedang ditanam pengguna.
  Future<List<Plant>> getPlants();

  /// Satu tanaman berdasarkan id.
  Future<Plant> getPlant(String id);

  /// Menyimpan tanaman baru hasil wizard "Tambah Tanaman".
  Future<Plant> addPlant({
    required String name,
    String? scientificName,
    required String location,
    required SoilType soil,
    String? phase,
  });

  /// Menandai sebuah tugas perawatan sebagai selesai/belum.
  Future<Plant> setTaskDone(String plantId, String taskTitle, bool done);

  /// Rekomendasi tanaman untuk langkah 4 wizard.
  Future<List<PlantRecommendation>> getRecommendations({
    required String location,
    required SoilType soil,
  });

  /// Jenis tanah yang bisa dipilih di langkah 3.
  Future<List<SoilType>> getSoilTypes();
}

/// Implementasi contoh: seluruh data diambil dari [MockData] di memori.
///
/// Perubahan (tambah tanaman, tandai tugas) ikut tersimpan selama aplikasi
/// hidup sehingga alur wizard bisa dicoba sampai selesai.
class MockPlantRepository implements PlantRepository {
  MockPlantRepository();

  final List<Plant> _plants = [...MockData.plants];

  /// Jeda buatan supaya indikator loading benar-benar terlihat di layar
  /// "Menganalisis…" — tanpa ini prosesnya selesai terlalu cepat.
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
      scientificName: scientificName ?? source.scientificName,
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
      fertilizer: soil.name == 'Tanah Humus' ? 'NPK Organik' : 'NPK Daun',
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
