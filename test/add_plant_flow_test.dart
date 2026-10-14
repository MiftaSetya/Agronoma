import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';

/// Uji logika [AddPlantController] dan alur langkah wizard (bukan piksel) —
/// kesetiaan visual dijaga pipeline tangkapan layar di `docs/testing.md`.
class _FakeRepository implements PlantRepository {
  @override
  Future<List<SoilType>> getSoilTypes() async => MockData.soilTypes;

  @override
  Future<List<PlantRecommendation>> getRecommendations({
    required String location,
    required SoilType soil,
  }) async => MockData.recommendations;

  // Sisanya tidak dipakai uji ini.
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Cuaca tiruan; `PlantController.addPlant` tidak memakainya.
class _FakeWeather implements WeatherRepository {
  @override
  Future<Weather> current(String city) async => MockData.weather;

  @override
  Future<List<WeatherForecast>> forecast(String city) async => MockData.forecast;
}

void main() {
  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider<PlantRepository>.value(value: _FakeRepository()),
      ChangeNotifierProvider<AddPlantController>(
        create: (_) => AddPlantController(dataSource: _FakeRepository()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );

  group('AddPlantController', () {
    test('setMedia menyimpan nama enum PlantingMedia', () {
      final c = AddPlantController(dataSource: _FakeRepository());
      c.setMedia(PlantingMedia.pot.name);
      expect(c.draft.media, 'pot');
      // Nama media memang key enum, bukan teks bebas.
      expect(
        PlantingMedia.values.map((m) => m.name),
        contains(c.draft.media),
      );
    });

    test('markSoilDetected tanpa argumen memakai jenis tanah pertama', () {
      final c = AddPlantController(dataSource: _FakeRepository());
      c.markSoilDetected(soil: MockData.soilTypes.first);
      expect(c.draft.soilDetected, isTrue);
      expect(c.draft.soil, same(MockData.soilTypes.first));
    });

    test('draft reset mengosongkan semua pilihan', () {
      final c = AddPlantController(dataSource: _FakeRepository());
      c.setMedia(PlantingMedia.ground.name);
      c.setLocation('Surabaya', 'Jl. Contoh 1');
      c.markSoilDetected(soil: MockData.soilTypes.first);
      c.reset();
      expect(c.draft.media, isNull);
      expect(c.draft.locationName, isNull);
      expect(c.draft.soilDetected, isFalse);
    });
  });

  group('PlantController.addPlant', () {
    test('meneruskan media tanam pilihan ke tanaman baru', () async {
      final plants = PlantController(
        plantRepository: MockPlantRepository(),
        weatherSource: _FakeWeather(),
      );

      final plant = await plants.addPlant(
        name: 'Sirih Gading',
        location: 'Surabaya',
        soil: MockData.soilTypes.first,
        media: PlantingMedia.openField,
      );

      // Dulu media pilihan langkah 2 dibuang dan selalu jadi `pot`.
      expect(plant.media, PlantingMedia.openField);
      expect(plant.place, PlantingMedia.openField.label);
    });
  });

  group('AddPlantFlow — langkah', () {
    testWidgets('langkah 1: konfirmasi lokasi pindah ke langkah media tanam', (
      tester,
    ) async {
      // Kanvas design 440x956; layar uji bawaan lebih kecil sehingga tombol
      // di bawah kartu konfirmasi keluar dari layar.
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konfirmasi Lokasi'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Media Tanam'), findsOneWidget);
      for (final media in PlantingMedia.values) {
        expect(find.text(media.label), findsOneWidget);
      }
    });

    testWidgets('langkah 3: memilih "Saya Tahu Jenis Tanah" membuka daftar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Lokasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya Tahu Jenis Tanah'));
      // Daftar tanah dimuat asinkron (~400 ms) setelah langkah terpasang.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text(MockData.soilTypes.first.name), findsOneWidget);
      expect(find.text(MockData.soilTypes.first.description), findsOneWidget);
    });

    testWidgets('langkah 3: "Bantu Saya Scan Tanah" membuka kamera deteksi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Lokasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bantu Saya Scan Tanah'));
      await tester.pumpAndSettle();

      // Dulu ini membuka bottom sheet _DetectSoilSheet; sekarang layar
      // penuh frame `101:701` yang memakai kamera sungguhan.
      expect(find.byType(SoilDetectionScreen), findsOneWidget);
      expect(find.text('Deteksi Jenis Tanah'), findsOneWidget);
    });

    testWidgets('alur manual lengkap sampai rekomendasi terisi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Lokasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya Tahu Jenis Tanah'));
      // Daftar tanah dimuat asinkron (~400 ms) setelah langkah terpasang.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(MockData.soilTypes.first.name),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockData.soilTypes.first.name).first);
      await tester.pumpAndSettle();

      final controller = tester
          .element(find.byType(AddPlantFlow))
          .read<AddPlantController>();
      expect(controller.draft.soil, isNotNull);

      await controller.loadRecommendations();
      expect(controller.recommendations, isNotEmpty);
      expect(controller.recommendations.first, isA<PlantRecommendation>());
    });
  });
}
