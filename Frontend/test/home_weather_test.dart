import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/features/home/home_screen.dart';

/// Tanaman dua kota: inilah situasi yang membuat satu kartu cuaca "Surabaya"
/// untuk semua tanaman menjadi salah.
Plant _plant(String id, String name, String city) => Plant(
  id: id,
  name: name,
  photoAsset: AppAssets.photoPotSoil,
  location: city,
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 16),
  careScore: 100,
  description: 'Deskripsi $name.',
);

class _FakePlantRepository implements PlantRepository {
  _FakePlantRepository(this._plants);

  final List<Plant> _plants;

  @override
  Future<List<Plant>> getPlants() async => _plants;

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    required DateTime today,
  }) async => const [];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Cuaca tiruan yang mencatat tanaman mana yang diminta untuk tiap kota.
class _FakeWeatherRepository implements WeatherRepository {
  final List<String> requested = [];

  /// Kondisi per kota; kota yang tidak ada di peta ini tidak punya data.
  final Map<String, String> conditions;

  _FakeWeatherRepository(this.conditions);

  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async {
    requested.add('$plantId@$city');
    final condition = conditions[city];
    if (condition == null) return null;
    return Weather(
      city: city,
      condition: condition,
      temperature: 30,
      iconAsset: AppAssets.weatherClear,
      forecast: [
        WeatherForecast(
          day: 'Hari ini',
          condition: condition,
          high: 32,
          low: 24,
          iconAsset: AppAssets.weatherClear,
        ),
      ],
    );
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  Future<_FakeWeatherRepository> pumpHome(
    WidgetTester tester,
    List<Plant> plants,
    Map<String, String> conditions,
  ) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final weather = _FakeWeatherRepository(conditions);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(
            create: (_) => AuthController(
              authSource: SampleAuthRepository(),
              initialUser: MockData.user,
            ),
          ),
          ChangeNotifierProvider<PlantController>(
            create: (_) => PlantController(
              plantRepository: _FakePlantRepository(plants),
              weatherSource: weather,
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return weather;
  }

  testWidgets('Beranda menampilkan satu kartu cuaca per kota tanaman', (
    tester,
  ) async {
    final weather = await pumpHome(
      tester,
      [
        _plant('1', 'Cabai Rawit', 'Surabaya'),
        _plant('2', 'Tomat Ceri', 'Surabaya'),
        _plant('3', 'Selada', 'Malang'),
      ],
      {'Surabaya': 'Cerah', 'Malang': 'Hujan Ringan'},
    );

    // Dua kota → dua kartu, masing-masing dengan nama kotanya sendiri. Nama
    // kota juga muncul di kartu tanaman, jadi pencarian dibatasi ke WeatherCard.
    final cards = tester.widgetList<WeatherCard>(find.byType(WeatherCard));
    expect(cards.map((c) => c.city), ['Surabaya', 'Malang']);
    expect(cards.map((c) => c.condition), ['Cerah', 'Hujan Ringan']);

    // Tiga tanaman di dua kota → hanya dua permintaan cuaca.
    expect(weather.requested, ['1@Surabaya', '3@Malang']);
  });

  testWidgets('kota tanpa data cuaca tidak menampilkan kartu kosong', (
    tester,
  ) async {
    await pumpHome(
      tester,
      [
        _plant('1', 'Cabai Rawit', 'Surabaya'),
        _plant('3', 'Selada', 'Malang'),
      ],
      // Malang sengaja tidak punya data: meniru cache backend yang belum
      // terisi karena cronjob belum jalan untuk kota itu.
      {'Surabaya': 'Cerah'},
    );

    final cards = tester.widgetList<WeatherCard>(find.byType(WeatherCard));
    expect(cards.map((c) => c.city), ['Surabaya']);
    // Daftar tanaman tetap utuh walau cuaca satu kota kosong.
    expect(find.text('Cabai Rawit'), findsOneWidget);
    expect(find.text('Selada'), findsOneWidget);
  });
}
