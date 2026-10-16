import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/plant_controller.dart';

/// Repositori tiruan yang bisa diubah hasilnya antar-panggilan, supaya muat
/// ulang bisa dibedakan dari muat pertama (tanaman contoh vs daftar kosong).
class _FakePlantRepository implements PlantRepository {
  _FakePlantRepository(this._batches);

  /// Daftar balasan berurutan; panggilan terakhir dipakai terus sesudahnya.
  final List<List<Plant>> _batches;
  int calls = 0;

  @override
  Future<List<Plant>> getPlants() async {
    final batch = _batches[calls.clamp(0, _batches.length - 1)];
    calls++;
    return batch;
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<Weather> current(String city) async => MockData.weather;

  @override
  Future<List<WeatherForecast>> forecast(String city) async => const [];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Tanaman contoh seadanya — hanya `id`/`name` yang dibedakan uji ini.
Plant _plant(String id, String name) => Plant(
  id: id,
  name: name,
  photoAsset: AppAssets.photoPotSoil,
  location: 'Surabaya',
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 16),
  careScore: 100,
  description: 'Deskripsi $name.',
);

void main() {
  group('PlantController.adopt', () {
    testWidgets('tanaman yang baru disimpan tetap ada setelah muat ulang', (
      tester,
    ) async {
      // Muat pertama mengembalikan satu tanaman contoh; muat ulang (force)
      // mengembalikan daftar kosong — meniru repositori Home yang belum tahu
      // tentang tanaman hasil `POST /plants`.
      final repo = _FakePlantRepository([
        [_plant('1', 'Cabai Rawit')],
        const [],
      ]);
      final controller = PlantController(
        plantRepository: repo,
        weatherSource: _FakeWeatherRepository(),
      );

      await controller.load();
      expect(controller.plants.map((p) => p.id), ['1']);

      controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);

      // Inti perbaikan: muat ulang tidak boleh menghapus tanaman yang sudah
      // benar-benar tersimpan di backend.
      await controller.load(force: true);
      expect(controller.plants.map((p) => p.id), ['99']);
      expect(controller.findById('99')?.name, 'Kangkung');
    });

    testWidgets('tanaman yang sudah terbaca dari backend tidak digandakan', (
      tester,
    ) async {
      final repo = _FakePlantRepository([
        [_plant('1', 'Cabai Rawit'), _plant('99', 'Kangkung')],
      ]);
      final controller = PlantController(
        plantRepository: repo,
        weatherSource: _FakeWeatherRepository(),
      );

      await controller.load();
      controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);

      await controller.load(force: true);
      expect(controller.plants.map((p) => p.id), ['1', '99']);
    });

    testWidgets('adopt dua kali untuk id yang sama tidak menggandakan', (
      tester,
    ) async {
      final repo = _FakePlantRepository([[_plant('1', 'Cabai Rawit')]]);
      final controller = PlantController(
        plantRepository: repo,
        weatherSource: _FakeWeatherRepository(),
      );

      await controller.load();
      controller.adopt(_plant('99', 'Kangkung'));
      controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);
    });
  });
}
