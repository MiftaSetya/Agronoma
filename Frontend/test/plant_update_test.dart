import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/plant_controller.dart';

class _FakePlantRepository implements PlantRepository {
  _FakePlantRepository(this.plant, {this.failUpdates = false});

  final Plant plant;
  bool failUpdates;
  int updateCalls = 0;
  int postponeCalls = 0;
  int uploadCalls = 0;
  bool failUpload = false;
  bool failPostpone = false;

  @override
  Future<List<Plant>> getPlants() async => [plant];

  @override
  Future<Plant> getPlant(String id) async => plant;

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async => const [];

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async => plant;

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
    updateCalls++;

    if (failUpdates) throw Exception('jaringan putus');

    return plant.copyWith(name: name, place: place, phase: phase);
  }

  @override
  Future<List<Plant>> getArchivedPlants() async => const [];

  @override
  Future<void> setArchived(
    String plantId, {
    required bool archived,
    bool markHarvested = false,
  }) async {}

  @override
  Future<void> deletePlant(String plantId) async {}

  @override
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {}

  @override
  Future<void> moistureFeedback(int wateringLogId, {required bool moist}) async {}

  @override
  Future<void> postponeWatering(String plantId) async {
    postponeCalls++;
    if (failPostpone) throw Exception('jaringan putus');
  }

  @override
  Future<Plant> uploadPhoto(String plantId, String imagePath) async {
    uploadCalls++;
    if (failUpload) throw Exception('jaringan putus');
    return plant.copyWith(photoUrl: 'file://$imagePath');
  }
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async => null;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Plant _plant() => Plant(
  id: '6',
  name: 'Kangkung',
  photoAsset: 'assets/images/plants/kangkung.png',
  location: 'Surabaya',
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 17),
  description: 'Kangkung di pot.',
    careScore: 100,
);

PlantController build(PlantRepository repo) => PlantController(
  plantRepository: repo,
  weatherSource: _FakeWeatherRepository(),
);

void main() {
  test('simpan yang berhasil melaporkan true', () async {
    final repo = _FakePlantRepository(_plant());
    final controller = build(repo);
    await controller.load();

    final ok = await controller.updatePlant('6', name: 'Kangkung Uji');

    expect(ok, isTrue);
    expect(controller.findById('6')!.name, 'Kangkung Uji');
  });

  test(
    'simpan yang gagal melaporkan false, bukan menutup seolah berhasil',
    () async {
      final repo = _FakePlantRepository(_plant(), failUpdates: true);
      final controller = build(repo);
      await controller.load();

      final ok = await controller.updatePlant('6', name: 'Kangkung Uji');

      expect(ok, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.findById('6')!.name, 'Kangkung');
    },
  );

  test('simpan yang gagal tidak mengubah daftar tanaman', () async {
    final repo = _FakePlantRepository(_plant(), failUpdates: true);
    final controller = build(repo);
    await controller.load();

    await controller.updatePlant('6', name: 'Nama Baru');

    expect(controller.plants, hasLength(1));
    expect(controller.plants.single.name, 'Kangkung');
  });

  test('tunda penyiraman memanggil endpoint sekali dan laporan true', () async {
    final repo = _FakePlantRepository(_plant());
    final controller = build(repo);
    await controller.load();

    final ok = await controller.postponeWatering('6');

    expect(ok, isTrue);
    expect(repo.postponeCalls, 1);
    expect(controller.error, isNull);
  });

  test('tunda penyiraman yang gagal melaporkan false', () async {
    final repo = _FakePlantRepository(_plant())..failPostpone = true;
    final controller = build(repo);
    await controller.load();

    final ok = await controller.postponeWatering('6');

    expect(ok, isFalse);
    expect(repo.postponeCalls, 1);
    expect(controller.error, isNotNull);
  });

  test('unggah foto tanaman memperbarui photoUrl', () async {
    final repo = _FakePlantRepository(_plant());
    final controller = build(repo);
    await controller.load();

    final ok = await controller.uploadPhoto('6', '/tmp/foto.jpg');

    expect(ok, isTrue);
    expect(repo.uploadCalls, 1);
    expect(controller.findById('6')!.photoUrl, 'file:///tmp/foto.jpg');
    expect(controller.isUploadingPhoto, isFalse);
  });

  test('unggah foto tanaman yang gagal melaporkan false', () async {
    final repo = _FakePlantRepository(_plant())..failUpload = true;
    final controller = build(repo);
    await controller.load();

    final ok = await controller.uploadPhoto('6', '/tmp/foto.jpg');

    expect(ok, isFalse);
    expect(controller.error, isNotNull);
    expect(controller.findById('6')!.photoUrl, isNull);
  });
}