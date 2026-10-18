import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_location.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';

class _FakeRepository implements AddPlantRepository {
  @override
  Future<List<SoilType>> getSoilTypes() async => MockData.soilTypes;

  @override
  Future<List<PlantLocation>> getLocations() async => const [
    PlantLocation(
      id: 1,
      label: 'Politeknik Elektronika Negeri Surabaya',
      city: 'Surabaya',
      province: 'Jawa Timur',
    ),
  ];

  @override
  Future<PlantLocation> createLocation({
    required String label,
    required String city,
    required String province,
  }) async => PlantLocation(id: 2, label: label, city: city, province: province);

  @override
  Future<List<PlantRecommendation>> getRecommendations({
    required PlantingMedia media,
    required SoilType soil,
    required String city,
    required String province,
  }) async => MockData.recommendations;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider<AddPlantRepository>.value(value: _FakeRepository()),
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

      expect(PlantingMedia.values.map((m) => m.name), contains(c.draft.media));
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

    test('tambah manual membuang pilihan kartu AI', () {
      final c = AddPlantController(dataSource: _FakeRepository());
      c.selectRecommendation(MockData.recommendations.first);
      expect(c.draft.hasPlant, isTrue);

      c.setManualPlant('Daun Bawang', null);
      expect(c.draft.recommendation, isNull);
      expect(c.draft.manualName, 'Daun Bawang');
      expect(c.draft.resolvedName, 'Daun Bawang');
    });

    test('memilih kartu AI membuang nama manual', () {
      final c = AddPlantController(dataSource: _FakeRepository());
      c.setManualPlant('Daun Bawang', null);

      c.selectRecommendation(MockData.recommendations.first);
      expect(c.draft.manualName, isNull);
      expect(c.draft.resolvedName, MockData.recommendations.first.name);
    });
  });

  group('SampleAddPlantRepository.createPlant', () {
    test('meneruskan media tanam pilihan ke tanaman baru', () async {
      final plant = await SampleAddPlantRepository().createPlant(
        name: 'Sirih Gading',
        media: PlantingMedia.openField,
        soil: MockData.soilTypes.first,
        locationId: 1,
        city: 'Surabaya',
        province: 'Jawa Timur',
        locationLabel: 'Rumah Kaca Sukolilo',
        phase: GrowthPhase.seedling,
      );

      expect(plant.media, PlantingMedia.openField);
      expect(plant.place, PlantingMedia.openField.label);

      expect(plant.tasks, isEmpty);
      expect(plant.timeline, isEmpty);
    });

    test('kota dan provinsi contoh dipakai bila lokasi belum dipilih', () {
      final c = AddPlantController(dataSource: _FakeRepository());

      expect(c.city, AddPlantController.fallbackCity);
      expect(c.province, AddPlantController.fallbackProvince);
    });
  });

  group('AddPlantFlow — langkah', () {
    Future<void> pilihLokasiPertama(WidgetTester tester) async {
      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Politeknik Elektronika Negeri Surabaya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Lokasi'));
      await tester.pumpAndSettle();
    }

    testWidgets('langkah 1: konfirmasi lokasi pindah ke langkah media tanam', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pilihLokasiPertama(tester);

      expect(find.text('Pilih Media Tanam'), findsOneWidget);
      for (final media in PlantingMedia.values) {
        expect(find.text(media.label), findsOneWidget);
      }
    });

    testWidgets('langkah 1: tombol konfirmasi mati sebelum lokasi dipilih', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const AddPlantFlow()));
      await tester.pumpAndSettle();

      final button = tester.widget<AgroButton>(
        find.widgetWithText(AgroButton, 'Konfirmasi Lokasi'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('langkah 3: memilih "Saya Tahu Jenis Tanah" membuka daftar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pilihLokasiPertama(tester);
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya Tahu Jenis Tanah'));

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

      await pilihLokasiPertama(tester);
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bantu Saya Scan Tanah'));
      await tester.pumpAndSettle();

      expect(find.byType(SoilDetectionScreen), findsOneWidget);
      expect(find.text('Deteksi Jenis Tanah'), findsOneWidget);
    });

    testWidgets('alur manual lengkap sampai rekomendasi terisi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pilihLokasiPertama(tester);
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya Tahu Jenis Tanah'));

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

    testWidgets('langkah 4: tanaman manual tampil bersama daftar AI', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pilihLokasiPertama(tester);
      await tester.tap(find.text(PlantingMedia.pot.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saya Tahu Jenis Tanah'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(MockData.soilTypes.first.name),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockData.soilTypes.first.name).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text(MockData.recommendations.first.name), findsWidgets);

      await tester.tap(find.text('Tambah manual tanaman'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Daun Bawang');
      await tester.tap(find.text('Tambah Tanaman'));
      await tester.pumpAndSettle();

      expect(find.text('Ditambahkan manual'), findsOneWidget);
      expect(find.text('Daun Bawang'), findsOneWidget);

      expect(find.text(MockData.recommendations.first.name), findsWidgets);
    });
  });
}
