import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/plant_controller.dart';

Plant _plant(String id, String name) => Plant(
  id: id,
  name: name,
  photoAsset: AppAssets.photoPotSoil,
  location: 'Surabaya',
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 17),
  careScore: 100,
  description: 'Deskripsi $name.',
);

class _ArchiveFakeRepository implements PlantRepository {
  _ArchiveFakeRepository({
    this.failTaskDone = false,
    this.failArchive = false,
    this.failDelete = false,
    this.rainDays = false,
  });

  final bool failTaskDone;
  final bool failArchive;
  final bool failDelete;
  final bool rainDays;

  final List<Plant> active = [_plant('6', 'Kangkung')];
  final List<Plant> archived = [_plant('8', 'Bayam')];

  int archiveCalls = 0;
  int deleteCalls = 0;
  int tailConfirms = 0;

  @override
  Future<List<Plant>> getPlants() async => List.of(active);

  @override
  Future<List<Plant>> getArchivedPlants() async => List.of(archived);

  @override
  Future<Plant> getPlant(String id) async =>
      [...active, ...archived].firstWhere((p) => p.id == id);

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async => [
    CareDay(
      date: PlantSchedule.isoDate(today ?? DateTime.now()),
      wateringStatus: rainDays ? 'skip_rain' : 'need_water',
      fertilizingStatus: 'none',
      wateringLogId: rainDays ? 42 : null,
      rainConfirmed: rainDays ? 'not_answered' : null,
    ),
  ];

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    if (failTaskDone) throw Exception('jaringan putus');
    return getPlant(plantId);
  }

  @override
  Future<void> setArchived(String plantId, {required bool archived}) async {
    if (failArchive) throw Exception('jaringan putus');
    archiveCalls++;
    if (archived) {
      final moved = active.firstWhere((p) => p.id == plantId);
      active.removeWhere((p) => p.id == plantId);
      this.archived.add(moved);
    } else {
      final moved = this.archived.firstWhere((p) => p.id == plantId);
      this.archived.removeWhere((p) => p.id == plantId);
      active.add(moved);
    }
  }

  @override
  Future<void> deletePlant(String plantId) async {
    if (failDelete) throw Exception('jaringan putus');
    deleteCalls++;
    active.removeWhere((p) => p.id == plantId);
    archived.removeWhere((p) => p.id == plantId);
  }

  @override
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {
    tailConfirms++;
  }

  @override
  Future<void> moistureFeedback(int wateringLogId, {required bool moist}) async {}

  @override
  Future<void> postponeWatering(String plantId) async {}

  @override
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    int? locationId,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async => getPlant(plantId);

  @override
  Future<Plant> uploadPhoto(String plantId, String imagePath) async =>
      getPlant(plantId);
}

class _NoWeather implements WeatherRepository {
  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async => null;
}

void main() {
  PlantController build(_ArchiveFakeRepository repo) => PlantController(
    plantRepository: repo,
    weatherSource: _NoWeather(),
  );

  test('toggleTask mengembalikan true saat berhasil', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.load();

    expect(await controller.toggleTask('6', CareTaskKind.watering, true), isTrue);
  });

  test('toggleTask mengembalikan false dan menyimpan galat saat gagal', () async {
    final repo = _ArchiveFakeRepository(failTaskDone: true);
    final controller = build(repo);

    await controller.load();

    final ok = await controller.toggleTask('6', CareTaskKind.watering, true);

    expect(ok, isFalse);
    expect(controller.error, isNotNull);
  });

  test('mengarsipkan tanaman memindahkannya dari daftar aktif', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.load();
    expect(controller.plants.map((p) => p.id), contains('6'));

    final ok = await controller.archive('6');

    expect(ok, isTrue);
    expect(controller.plants.map((p) => p.id), isNot(contains('6')));
    expect(controller.archivedPlants.map((p) => p.id), contains('6'));
    expect(repo.archiveCalls, 1);
  });

  test('mengarsipkan yang gagal tidak mengubah daftar aktif', () async {
    final repo = _ArchiveFakeRepository(failArchive: true);
    final controller = build(repo);

    await controller.load();

    final ok = await controller.archive('6');

    expect(ok, isFalse);
    expect(controller.plants.map((p) => p.id), contains('6'));
    expect(controller.error, isNotNull);
  });

  test('mengembalikan tanaman arsip memasukkan kembali ke daftar aktif', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.loadArchived();
    expect(controller.archivedPlants.map((p) => p.id), contains('8'));

    final ok = await controller.restore('8');

    expect(ok, isTrue);
    expect(controller.archivedPlants.map((p) => p.id), isNot(contains('8')));
    expect(repo.active.map((p) => p.id), contains('8'));
    expect(
      controller.plants.map((p) => p.id),
      contains('8'),
      reason: 'tanaman yang dikembalikan harus tampil di daftar aktif',
    );
  });

  test('menghapus tanaman mengosongkan daftar aktif dan arsip', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.load();
    await controller.loadArchived();
    expect(controller.plants.map((p) => p.id), contains('6'));
    expect(controller.archivedPlants.map((p) => p.id), contains('8'));

    final ok = await controller.deletePlant('6');

    expect(ok, isTrue);
    expect(controller.plants.map((p) => p.id), isNot(contains('6')));
    expect(repo.deleteCalls, 1);
  });

  test('menghapus tanaman yang gagal tidak mengubah daftar aktif', () async {
    final repo = _ArchiveFakeRepository(failDelete: true);
    final controller = build(repo);

    await controller.load();

    final ok = await controller.deletePlant('6');

    expect(ok, isFalse);
    expect(controller.plants.map((p) => p.id), contains('6'));
    expect(controller.error, isNotNull);
  });

  test('reset mengosongkan daftar arsip', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.loadArchived();
    expect(controller.archivedPlants, isNotEmpty);

    controller.reset();

    expect(controller.archivedPlants, isEmpty);
  });

  test('confirmRain memakai id log dari kalender hari ini', () async {
    final repo = _ArchiveFakeRepository(rainDays: true);
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');

    expect(controller.todayCare('6')!.awaitsRainConfirmation, isTrue);

    final ok = await controller.confirmRain('6', rained: true);

    expect(ok, isTrue);
    expect(repo.tailConfirms, 1);
  });

  test('confirmRain tanpa log hari ini tidak memanggil jaringan', () async {
    final repo = _ArchiveFakeRepository();
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');

    final ok = await controller.confirmRain('6', rained: true);

    expect(ok, isFalse);
    expect(repo.tailConfirms, 0);
  });
}
