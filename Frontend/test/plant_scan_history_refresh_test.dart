import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/scan_history_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/scan_record.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/state/scan_history_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/plant_detail/plant_detail_screen.dart';

Plant _plant() => Plant(
  id: '6',
  name: 'Kangkung',
  photoAsset: AppAssets.photoPotSoil,
  location: 'Surabaya',
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: CareStatus.safe,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 17),
  careScore: 100,
  description: 'Ditanam di pot tanaman dengan media tanam campuran.',
);

class _FakePlantRepository implements PlantRepository {
  @override
  Future<List<Plant>> getPlants() async => [_plant()];

  @override
  Future<Plant> getPlant(String id) async => _plant();

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async => [];

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async => _plant();

  @override
  Future<List<Plant>> getArchivedPlants() async => const [];

  @override
  Future<void> setArchived(
    String plantId, {
    required bool archived,
    bool markHarvested = false,
  }) async {}

  @override
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
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

class _CountingScanHistoryRepository implements ScanHistoryRepository {
  int calls = 0;

  @override
  Future<List<ScanRecord>> getHistory({int? plantId}) async {
    calls++;
    return [
      ScanRecord(
        id: calls,
        plantId: plantId ?? 0,
        pestName: calls == 1 ? '' : 'Kutu Daun',
        confidence: calls == 1 ? 0 : 0.88,
        scannedAt: DateTime(2026, 10, 18),
        action: '',
        imageUrl: '',
      ),
    ];
  }
}

class _ScanRoute extends StatelessWidget {
  const _ScanRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Kesehatan')),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('kembali'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('riwayat pemindaian dimuat ulang setelah kembali dari scan', (
    tester,
  ) async {
    final source = _CountingScanHistoryRepository();
    tester.view.physicalSize = const Size(440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlantController>(
            create: (_) => PlantController(
              plantRepository: _FakePlantRepository(),
              weatherSource: _FakeWeatherRepository(),
            ),
          ),
          ChangeNotifierProvider<ScanHistoryController>(
            create: (_) => ScanHistoryController(source),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          routes: {Routes.diseaseDetection: (_) => const _ScanRoute()},
          home: const PlantDetailScreen(plantId: '6', initialTab: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(source.calls, 1);

    await tester.tap(find.text('Pindai Kesehatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('kembali'));
    await tester.pumpAndSettle();

    expect(source.calls, 2);
    expect(find.text('Kutu Daun'), findsOneWidget);
  });
}
