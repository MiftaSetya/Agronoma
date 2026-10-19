import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/scan_history_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
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
  _FakePlantRepository({this.awaitingRain = false});

  final bool awaitingRain;

  int completed = 0;
  final List<bool> rainConfirms = [];

  @override
  Future<List<Plant>> getPlants() async => [_plant()];

  @override
  Future<Plant> getPlant(String id) async => _plant();

  @override
  Future<List<CareDay>> careDays(
    Plant plant, {
    DateTime? today,
    String? month,
  }) async => [
    CareDay(
      date: PlantSchedule.isoDate(today ?? DateTime.now()),
      wateringStatus: completed > 0
          ? 'watered'
          : awaitingRain
          ? 'skip_rain'
          : 'need_water',
      fertilizingStatus: 'none',
      wateringLogId: awaitingRain ? 42 : null,
      rainConfirmed: awaitingRain ? 'not_answered' : null,
    ),
  ];

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    completed++;
    return _plant();
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
  Future<void> confirmRain(int wateringLogId, {required bool rained}) async {
    rainConfirms.add(rained);
  }

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

void main() {
  Future<_FakePlantRepository> pumpDetail(
    WidgetTester tester, {
    required Size screen,
    bool awaitingRain = false,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakePlantRepository(awaitingRain: awaitingRain);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlantController>(
            create: (_) => PlantController(
              plantRepository: repo,
              weatherSource: _FakeWeatherRepository(),
            ),
          ),
          ChangeNotifierProvider<ScanHistoryController>(
            create: (_) => ScanHistoryController(
              const SampleScanHistoryRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlantDetailScreen(plantId: '6', initialTab: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Finder verticalList() => find.byWidgetPredicate(
    (w) => w is ListView && w.scrollDirection == Axis.vertical,
  );

  testWidgets(
    'baris tugas terakhir bisa digulir keluar dari balik tombol bulat',
    (tester) async {
      await pumpDetail(tester, screen: const Size(440, 740));

      final list = verticalList();
      expect(list, findsOne);

      for (var i = 0; i < 6; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      final fab = tester.getRect(find.byKey(plantDetailChatFabKey));
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text(CareTaskKind.watering.actionLabel),
              matching: find.byType(InkWell),
            )
            .first,
      );

      expect(
        row.bottom,
        lessThanOrEqualTo(fab.top),
        reason:
            'baris tugas (bawah ${row.bottom}) tertutup tombol obrolan '
            '(atas ${fab.top})',
      );
    },
  );

  testWidgets('tombol bulat tetap di dalam layar pada layar pendek', (
    tester,
  ) async {
    await pumpDetail(tester, screen: const Size(440, 600), awaitingRain: true);

    final screenHeight = tester.view.physicalSize.height;
    final fab = tester.getRect(find.byKey(plantDetailChatFabKey));
    final rain = tester.getRect(find.byKey(plantDetailRainFabKey));

    expect(fab.bottom, lessThanOrEqualTo(screenHeight));
    expect(fab.top, greaterThan(0));
    expect(rain.top, greaterThan(0));
  });

  testWidgets('tombol hujan disembunyikan bila tidak ada konfirmasi tertunda', (
    tester,
  ) async {
    await pumpDetail(tester, screen: const Size(440, 740));

    expect(find.byKey(plantDetailRainFabKey), findsNothing);
    expect(find.byKey(plantDetailChatFabKey), findsOne);
  });

  testWidgets('menekan tombol hujan mengirim rain-confirm sesuai pilihan', (
    tester,
  ) async {
    final repo = await pumpDetail(
      tester,
      screen: const Size(440, 740),
      awaitingRain: true,
    );

    expect(find.byKey(plantDetailRainFabKey), findsOne);

    await tester.tap(find.byKey(plantDetailRainFabKey));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Hujan'), findsOne);

    await tester.tap(find.text('Ya, Hujan'));
    await tester.pumpAndSettle();

    expect(repo.rainConfirms, [true]);
  });

  testWidgets(
    'mengetuk baris tugas mencatat penyiraman, bukan membuka obrolan',
    (tester) async {
      final repo = await pumpDetail(tester, screen: const Size(440, 740));

      final row = find.byKey(const Key('task-row-watering'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: verticalList(),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.tap(row, warnIfMissed: true);
      await tester.pumpAndSettle();

      expect(repo.completed, 1);
    },
  );
}
