import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';

/// Antarmuka sumber data **daftar tanaman** — satu-satunya tempat yang tahu
/// asal data; cukup tukar implementasinya di `app.dart` tanpa menyentuh widget
/// mana pun.
///
/// Data khusus wizard "Tambah Tanaman" (scan tanah, rekomendasi AI, simpan
/// tanaman) sengaja tidak ada di sini melainkan di `AddPlantRepository`, karena
/// operasi itu milik alur wizard.
///
/// [AddPlantRepository]: ./add_plant_repository.dart
abstract class PlantRepository {
  Future<List<Plant>> getPlants();
  Future<Plant> getPlant(String id);

  /// Entri care-calendar bulan berjalan untuk [plant].
  ///
  /// Terpisah dari [getPlants] karena butuh satu permintaan tambahan per
  /// tanaman, sedangkan Beranda hanya perlu `badge_status` yang sudah ikut di
  /// daftar. Dipisah juga supaya daftar tanaman tetap cepat saat jumlahnya
  /// bertambah.
  ///
  /// Yang dikembalikan adalah **hari mentah**, bukan tugas: layar Detail
  /// memakainya untuk dua hal sekaligus (daftar tugas hari ini dan kartu
  /// "Kalender Perawatan"), dan menurunkan keduanya dari satu sumber membuat
  /// centang serta kalender tidak mungkin berbeda pendapat.
  Future<List<CareDay>> careDays(Plant plant, {required DateTime today});

  Future<Plant> setTaskDone(String plantId, CareTaskKind kind, bool done);
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

  /// Data contoh tidak punya riwayat kalender: daftar tugasnya sudah ada di
  /// [Plant.tasks]. Mengembalikan daftar kosong membuat controller memakai
  /// `Plant.tasks` apa adanya (lihat `PlantController.tasksFor`), sehingga teks
  /// tugas contoh tidak berubah menjadi versi generik.
  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    required DateTime today,
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
