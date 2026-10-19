import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/plant_controller.dart';

class _FakePlantRepository implements PlantRepository {
  _FakePlantRepository(this._batches);

  final List<List<Plant>> _batches;
  int calls = 0;

  @override
  Future<List<Plant>> getPlants() async {
    final batch = _batches[calls.clamp(0, _batches.length - 1)];
    calls++;
    return batch;
  }

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async => const [];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWeatherRepository implements WeatherRepository {
  _FakeWeatherRepository({this.failing = const {}});

  final Set<String> failing;
  final List<String> requested = [];

  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async {
    requested.add('$plantId@$city');
    if (failing.contains(city)) return null;
    return Weather(
      city: city,
      condition: 'Cerah',
      temperature: 30,
      forecast: [
        WeatherForecast(day: 'Hari ini', condition: 'Cerah', high: 32, low: 24),
      ],
    );
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Plant _plant(String id, String name, {String city = 'Surabaya'}) => Plant(
  id: id,
  name: name,
  photoAsset: AppAssets.photoPotSoil,
  location: city,
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 16),
  description: 'Deskripsi $name.',
    careScore: 100,
);

void main() {
  group('PlantController.adopt', () {
    testWidgets('tanaman yang baru disimpan tetap ada setelah muat ulang', (
      tester,
    ) async {
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

      await controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);

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
      await controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);

      await controller.load(force: true);
      expect(controller.plants.map((p) => p.id), ['1', '99']);
    });

    testWidgets('adopt dua kali untuk id yang sama tidak menggandakan', (
      tester,
    ) async {
      final repo = _FakePlantRepository([
        [_plant('1', 'Cabai Rawit')],
      ]);
      final controller = PlantController(
        plantRepository: repo,
        weatherSource: _FakeWeatherRepository(),
      );

      await controller.load();
      await controller.adopt(_plant('99', 'Kangkung'));
      await controller.adopt(_plant('99', 'Kangkung'));
      expect(controller.plants.map((p) => p.id), ['1', '99']);
    });
  });

  group('PlantController — cuaca per lokasi', () {
    testWidgets('satu kartu per kota, bukan per tanaman', (tester) async {
      final weather = _FakeWeatherRepository();
      final controller = PlantController(
        plantRepository: _FakePlantRepository([
          [
            _plant('1', 'Cabai Rawit', city: 'Surabaya'),
            _plant('2', 'Tomat Ceri', city: 'Surabaya'),
            _plant('3', 'Kangkung', city: 'Malang'),
          ],
        ]),
        weatherSource: weather,
      );

      await controller.load();

      expect(controller.cityWeather.map((w) => w.city), ['Surabaya', 'Malang']);
      expect(weather.requested, ['1@Surabaya', '3@Malang']);
    });

    testWidgets('tanaman baru di kota baru menambah kartu cuacanya', (
      tester,
    ) async {
      final weather = _FakeWeatherRepository();
      final controller = PlantController(
        plantRepository: _FakePlantRepository([
          [_plant('1', 'Cabai Rawit', city: 'Surabaya')],
        ]),
        weatherSource: weather,
      );

      await controller.load();
      expect(controller.cityWeather.map((w) => w.city), ['Surabaya']);

      await controller.adopt(_plant('9', 'Selada', city: 'Batu'));
      expect(controller.cityWeather.map((w) => w.city), ['Surabaya', 'Batu']);
      expect(controller.weatherForCity('Batu')?.city, 'Batu');
    });

    testWidgets('kota tanpa data cuaca dilewati, daftar tanaman tetap ada', (
      tester,
    ) async {
      final controller = PlantController(
        plantRepository: _FakePlantRepository([
          [
            _plant('1', 'Cabai Rawit', city: 'Surabaya'),
            _plant('2', 'Tomat Ceri', city: 'Malang'),
          ],
        ]),
        weatherSource: _FakeWeatherRepository(failing: {'Malang'}),
      );

      await controller.load();

      expect(controller.plants, hasLength(2));
      expect(controller.cityWeather.map((w) => w.city), ['Surabaya']);
    });

    testWidgets('ramalan Detail mengikuti kota tanaman itu sendiri', (
      tester,
    ) async {
      final controller = PlantController(
        plantRepository: _FakePlantRepository([
          [
            _plant('1', 'Cabai Rawit', city: 'Surabaya'),
            _plant('2', 'Tomat Ceri', city: 'Malang'),
          ],
        ]),
        weatherSource: _FakeWeatherRepository(),
      );

      await controller.load();

      expect(controller.forecastFor('Malang'), isNotEmpty);
      expect(controller.forecastFor('Malang').first.condition, 'Cerah');
      expect(controller.forecastFor('Jakarta'), isEmpty);
    });
  });
}