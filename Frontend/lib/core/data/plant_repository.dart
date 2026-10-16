import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';

/// Antarmuka sumber data **daftar tanaman** — satu-satunya tempat yang tahu
/// asal data; nanti cukup tambahkan `HttpPlantRepository` dan tukar di `app.dart`
/// tanpa menyentuh widget mana pun.
///
/// Data khusus wizard "Tambah Tanaman" (scan tanah, rekomendasi AI, simpan
/// tanaman) sengaja tidak ada di sini melainkan di `AddPlantRepository`, karena
/// keempat operasi itu sudah tersambung backend sedangkan daftar tanaman baru
/// menyusul.
///
/// [AddPlantRepository]: ./add_plant_repository.dart
abstract class PlantRepository {
  Future<List<Plant>> getPlants();
  Future<Plant> getPlant(String id);
  Future<Plant> setTaskDone(String plantId, String taskTitle, bool done);
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  });
}

/// Implementasi contoh dari [MockData] di memori; perubahan (tandai tugas,
/// ubah setelan) tersimpan selama aplikasi hidup.
class MockPlantRepository implements PlantRepository {
  MockPlantRepository();

  final List<Plant> _plants = [...MockData.plants];

  /// Jeda buatan supaya indikator loading benar-benar terlihat.
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
}
