import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/plant_controller.dart';

Plant _plant({CareStatus status = CareStatus.safe}) => Plant(
  id: '6',
  name: 'Cabai Rawit',
  photoAsset: AppAssets.photoPotSoil,
  location: 'Surabaya',
  place: 'Pot tanaman',
  media: PlantingMedia.pot,
  status: status,
  phase: GrowthPhase.seedling,
  plantedAt: DateTime(2026, 10, 17),
  careScore: 100,
  description: 'Cabai rawit di pot.',
);

class _ScheduleFakeRepository implements PlantRepository {
  _ScheduleFakeRepository(this._plant, {this.fixedDays});

  final Plant _plant;

  final List<CareDay>? fixedDays;

  final String today = PlantSchedule.isoDate(DateTime.now());

  bool watered = false;
  int careDaysCalls = 0;

  @override
  Future<List<Plant>> getPlants() async => [_plant];

  @override
  Future<Plant> getPlant(String id) async => _plant;

  @override
  Future<List<CareDay>> careDays(Plant plant, {required DateTime today}) async {
    careDaysCalls++;
    final fixed = fixedDays;
    if (fixed != null) return fixed;
    return [
      CareDay(
        date: this.today,
        wateringStatus: watered ? 'watered' : 'need_water',
        fertilizingStatus: 'none',
      ),
    ];
  }

  @override
  Future<Plant> setTaskDone(
    String plantId,
    CareTaskKind kind,
    bool done,
  ) async {
    watered = done;

    return _plant;
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
  PlantController build(_ScheduleFakeRepository repo) => PlantController(
    plantRepository: repo,
    weatherSource: _FakeWeatherRepository(),
  );

  testWidgets('tugas hari ini diambil dari care-calendar, bukan Plant.tasks', (
    tester,
  ) async {
    final repo = _ScheduleFakeRepository(_plant());
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');

    final tasks = controller.tasksFor('6');
    expect(tasks, hasLength(1));
    expect(tasks.single.kind, CareTaskKind.watering);
    expect(tasks.single.done, isFalse);
  });

  testWidgets('mencentang tugas tidak menghapusnya, melainkan menjadikannya '
      'selesai', (tester) async {
    final repo = _ScheduleFakeRepository(_plant());
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');
    expect(controller.tasksFor('6').single.done, isFalse);

    await controller.toggleTask('6', CareTaskKind.watering, true);

    final tasks = controller.tasksFor('6');
    expect(tasks, hasLength(1));
    expect(tasks.single.done, isTrue);
  });

  testWidgets('muat ulang tanaman tidak mengosongkan jadwal', (tester) async {
    final repo = _ScheduleFakeRepository(_plant());
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');
    expect(controller.tasksFor('6'), hasLength(1));

    await controller.load(force: true);

    expect(controller.tasksFor('6'), hasLength(1));
  });

  testWidgets('kalender bulan berjalan tersedia untuk kartu Detail', (
    tester,
  ) async {
    final repo = _ScheduleFakeRepository(_plant());
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');

    expect(controller.careDaysFor('6'), hasLength(1));
    expect(controller.careDaysFor('6').single.date, repo.today);
  });

  testWidgets('badge perlu pupuk menambah tugas pupuk walau kalender kosong', (
    tester,
  ) async {
    final repo = _ScheduleFakeRepository(
      _plant(status: CareStatus.needsFertilizer),
    );
    final controller = build(repo);

    await controller.load();
    await controller.loadTasks('6');

    final kinds = controller.tasksFor('6').map((t) => t.kind);
    expect(kinds, contains(CareTaskKind.fertilizing));
  });

  testWidgets('tanaman contoh tanpa kalender tetap memakai Plant.tasks', (
    tester,
  ) async {
    final sample = _plant().copyWith(
      tasks: const [
        CareTask(
          title: 'Siram Tanaman',
          description: 'Siram hingga tanah lembap.',
          date: 'Hari ini',
          done: false,
        ),
      ],
    );
    final controller = build(
      _ScheduleFakeRepository(sample, fixedDays: const []),
    );

    await controller.load();
    await controller.loadTasks('6');

    final tasks = controller.tasksFor('6');
    expect(tasks, hasLength(1));

    expect(tasks.single.description, 'Siram hingga tanah lembap.');
  });
}
