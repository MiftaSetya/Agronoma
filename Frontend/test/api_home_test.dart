import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/http_plant_repository.dart';
import 'package:frontend/core/data/api/http_weather_repository.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/api/weather_codes.dart';
import 'package:frontend/core/models/plant.dart';

class _StubTokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'token-uji';

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(
      httpClient: MockClient(handler),
      tokenStore: _StubTokenStore(),
      baseUrl: 'http://127.0.0.1:8000/api',
    );

Map<String, dynamic> _plantJson({
  required int id,
  required String name,
  String city = 'Surabaya',
  String badge = 'kondisi_aman',
}) => {
  'id': id,
  'plant_name': name,
  'planting_medium': 'pot',
  'soil_type': 'fertile',
  'current_phase': 'seedling',
  'planting_date': '2026-10-17',
  'status': 'active',
  'badge_status': badge,
  'location': {
    'id': 9,
    'label': 'Rumah',
    'city': city,
    'province': 'Jawa Timur',
  },
};

void main() {
  group('HttpPlantRepository', () {
    test('GET /plants dipetakan menjadi daftar tanaman', () async {
      final requests = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          requests.add(request);
          expect(request.url.path, '/api/plants');
          return http.Response(
            jsonEncode({
              'data': [_plantJson(id: 6, name: 'Cabai Rawit')],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final plants = await repo.getPlants();
      expect(plants, hasLength(1));
      expect(plants.single.id, '6');
      expect(plants.single.name, 'Cabai Rawit');

      expect(plants.single.location, 'Surabaya');
      expect(plants.single.media, PlantingMedia.pot);

      expect(requests.single.url.queryParameters['status'], 'active');
    });

    test('badge_status backend menentukan kondisi pada kartu', () async {
      final repo = HttpPlantRepository(
        apiClient: _client(
          (request) async => http.Response(
            jsonEncode({
              'data': [
                _plantJson(id: 7, name: 'Tomat', badge: 'perlu_disiram'),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final plants = await repo.getPlants();
      expect(plants.single.status, CareStatus.needsWater);
    });

    test('care-calendar hari ini menjadi tugas "Perawatan Hari Ini"', () async {
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          expect(request.url.path, '/api/plants/6/care-calendar');
          return http.Response(
            '{"days":[{"date":"2026-10-17","watering_status":"need_water",'
            '"fertilizing_status":"none"}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final plant = Plant(
        id: '6',
        name: 'Cabai Rawit',
        photoAsset: AppAssets.photoPotSoil,
        location: 'Surabaya',
        place: 'Pot tanaman',
        media: PlantingMedia.pot,
        status: CareStatus.safe,
        phase: GrowthPhase.seedling,
        plantedAt: DateTime(2026, 10, 17),
        description: '',
    careScore: 100,
      );

      final days = await repo.careDays(plant, today: DateTime(2026, 10, 17));
      expect(days, hasLength(1));
      expect(days.single.wateringStatus, 'need_water');

      final tasks = PlantSchedule.tasksForToday(
        days,
        today: DateTime(2026, 10, 17),
      );
      expect(tasks, hasLength(1));
      expect(tasks.single.kind, CareTaskKind.watering);
      expect(tasks.single.done, isFalse);
    });

    test('menandai tugas selesai memanggil endpoint penyiraman', () async {
      final paths = <String>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/watering/complete')) {
            return http.Response('{}', 200);
          }
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.setTaskDone('6', CareTaskKind.watering, true);
      expect(paths, contains('/api/plants/6/watering/complete'));
    });

    test('tugas pupuk memakai endpoint pemupukan', () async {
      final paths = <String>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/complete')) {
            return http.Response('{}', 200);
          }
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.setTaskDone('6', CareTaskKind.fertilizing, true);
      expect(paths, contains('/api/plants/6/fertilizing/complete'));
    });

    test('membatalkan centang ditolak tanpa menyentuh jaringan', () async {
      var requests = 0;
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          requests++;
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        repo.setTaskDone('6', CareTaskKind.watering, false),
        throwsA(isA<ApiException>()),
      );

      expect(requests, 0);
    });

    test('arsip memakai PATCH status=archived', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.setArchived('6', archived: true);

      expect(calls.single.method, 'PATCH');
      expect(calls.single.url.path, '/api/plants/6');
      expect((jsonDecode(calls.single.body) as Map)['status'], 'archived');
    });

    test('mengembalikan tanaman dari arsip memakai status=active', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.setArchived('6', archived: false);

      expect((jsonDecode(calls.single.body) as Map)['status'], 'active');
    });

    test('menandai panen memakai PATCH status=harvested', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({'plant': _plantJson(id: 6, name: 'Cabai Rawit')}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.setArchived('6', archived: true, markHarvested: true);

      expect(calls.single.method, 'PATCH');
      expect(calls.single.url.path, '/api/plants/6');
      expect((jsonDecode(calls.single.body) as Map)['status'], 'harvested');
    });

    test('daftar arsip meminta status=archived', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response(
            jsonEncode({
              'data': [_plantJson(id: 8, name: 'Bayam')],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final plants = await repo.getArchivedPlants();

      expect(plants, hasLength(1));
      expect(plants.single.name, 'Bayam');
      expect(calls.single.url.queryParameters['status'], 'archived');
    });

    test('hapus tanaman memanggil DELETE /plants/{id}', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response('', 204);
        }),
      );

      await repo.deletePlant('6');

      expect(calls.single.method, 'DELETE');
      expect(calls.single.url.path, '/api/plants/6');
    });

    test('konfirmasi hujan memanggil rain-confirm dengan yes/no', () async {
      final calls = <http.Request>[];
      final repo = HttpPlantRepository(
        apiClient: _client((request) async {
          calls.add(request);
          return http.Response('{}', 200);
        }),
      );

      await repo.confirmRain(42, rained: true);
      await repo.confirmRain(42, rained: false);

      expect(calls.first.url.path, '/api/watering-logs/42/rain-confirm');
      expect((jsonDecode(calls.first.body) as Map)['rain_confirmed'], 'yes');
      expect((jsonDecode(calls.last.body) as Map)['rain_confirmed'], 'no');
    });

    test('care-calendar meneruskan id log dan status konfirmasi hujan', () async {
      final repo = HttpPlantRepository(
        apiClient: _client(
          (request) async => http.Response(
            '{"days":[{"date":"2026-10-17","watering_status":"skip_rain",'
            '"fertilizing_status":"none","watering_log_id":42,'
            '"rain_confirmed":"not_answered"}]}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final plant = Plant(
        id: '6',
        name: 'Cabai Rawit',
        photoAsset: AppAssets.photoPotSoil,
        location: 'Surabaya',
        place: 'Pot tanaman',
        media: PlantingMedia.pot,
        status: CareStatus.safe,
        phase: GrowthPhase.seedling,
        plantedAt: DateTime(2026, 10, 17),
        description: '',
    careScore: 100,
      );

      final days = await repo.careDays(plant, today: DateTime(2026, 10, 17));

      expect(days.single.wateringLogId, 42);
      expect(days.single.awaitsRainConfirmation, isTrue);
    });
  });

  group('HttpWeatherRepository', () {
    test('ramalan hari ini menjadi kartu cuaca kota tanaman', () async {
      final repo = HttpWeatherRepository(
        apiClient: _client((request) async {
          expect(request.url.path, '/api/plants/6/weather');
          return http.Response(
            '{"forecast":[{"date":"2026-10-17","condition":"partly_cloudy",'
            '"temp_min":25.4,"temp_max":35.2,"rainfall_mm":0},'
            '{"date":"2026-10-18","condition":"light_rain",'
            '"temp_min":24.0,"temp_max":31.0,"rainfall_mm":2.31}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final weather = await repo.forPlant(plantId: '6', city: 'Surabaya');
      expect(weather, isNotNull);
      expect(weather!.city, 'Surabaya');
      expect(weather.condition, 'Sebagian Berawan');

      expect(weather.temperature, 30);
      expect(weather.forecast, hasLength(2));
      expect(weather.forecast.first.day, 'Sab');
      expect(weather.forecast[1].condition, 'Hujan Ringan');
    });

    test('dua tanaman di kota yang sama hanya satu permintaan', () async {
      var requests = 0;
      final repo = HttpWeatherRepository(
        apiClient: _client((request) async {
          requests++;
          return http.Response(
            '{"forecast":[{"date":"2026-10-17","condition":"sunny",'
            '"temp_min":25.0,"temp_max":35.0,"rainfall_mm":0}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await repo.forPlant(plantId: '6', city: 'Surabaya');
      await repo.forPlant(plantId: '7', city: 'Surabaya');

      expect(requests, 1);
    });

    test('kota berbeda memakai permintaan berbeda sesuai tanamannya', () async {
      final requestedPlantIds = <String>[];
      final repo = HttpWeatherRepository(
        apiClient: _client((request) async {
          requestedPlantIds.add(request.url.pathSegments[2]);
          final city = request.url.pathSegments[2] == '6'
              ? 'sunny'
              : 'heavy_rain';
          return http.Response(
            '{"forecast":[{"date":"2026-10-17","condition":"$city",'
            '"temp_min":25.0,"temp_max":35.0,"rainfall_mm":0}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final surabaya = await repo.forPlant(plantId: '6', city: 'Surabaya');
      final malang = await repo.forPlant(plantId: '9', city: 'Malang');

      expect(requestedPlantIds, ['6', '9']);
      expect(surabaya!.condition, 'Cerah');
      expect(malang!.condition, 'Hujan Lebat');
      expect(malang.city, 'Malang');
    });

    test('cache cuaca kosong menghasilkan null, bukan galat', () async {
      final repo = HttpWeatherRepository(
        apiClient: _client(
          (request) async => http.Response('{"forecast":[]}', 200),
        ),
      );

      expect(await repo.forPlant(plantId: '6', city: 'Surabaya'), isNull);
    });
  });

  group('PlantSchedule', () {
    test('hujan diperkirakan menahan penyiraman tapi tetap jadi tugas', () {
      final tasks = PlantSchedule.tasksForToday(const [
        CareDay(
          date: '2026-10-17',
          wateringStatus: 'skip_rain',
          fertilizingStatus: 'none',
        ),
      ], today: DateTime(2026, 10, 17));

      expect(tasks, hasLength(1));
      expect(tasks.single.kind, CareTaskKind.watering);
      expect(tasks.single.done, isFalse);
    });

    test('penundaan karena hujan tidak membuat tugas hari ini', () {
      final tasks = PlantSchedule.tasksForToday(const [
        CareDay(
          date: '2026-10-17',
          wateringStatus: 'delayed_rain_expected',
          fertilizingStatus: 'none',
        ),
      ], today: DateTime(2026, 10, 17));

      expect(tasks, isEmpty);
    });

    test('badge perlu_pupuk menambah tugas pupuk tanpa baris kalender', () {
      final tasks = PlantSchedule.tasksForToday(
        const [
          CareDay(
            date: '2026-10-17',
            wateringStatus: 'watered',
            fertilizingStatus: 'none',
          ),
        ],
        today: DateTime(2026, 10, 17),
        dueFertilizer: true,
      );

      expect(tasks.map((t) => t.kind), [
        CareTaskKind.watering,
        CareTaskKind.fertilizing,
      ]);
      expect(tasks.first.done, isTrue);
      expect(tasks.last.done, isFalse);
    });

    test('hari tanpa jadwal tidak menghasilkan tugas', () {
      final tasks = PlantSchedule.tasksForToday(const [
        CareDay(
          date: '2026-10-18',
          wateringStatus: 'need_water',
          fertilizingStatus: 'none',
        ),
      ], today: DateTime(2026, 10, 17));

      expect(tasks, isEmpty);
    });
  });

  group('WeatherCodes', () {
    test('enam kode backend punya label dan ikon', () {
      for (final code in [
        'sunny',
        'partly_cloudy',
        'cloudy',
        'light_rain',
        'moderate_rain',
        'heavy_rain',
      ]) {
        expect(WeatherCodes.label(code), isNot('Cuaca Tidak Diketahui'));
        expect(WeatherCodes.icon(code), isNotEmpty);
      }
    });

    test('kode asing memakai label netral, bukan menebak', () {
      expect(WeatherCodes.label('badai_salju'), 'Cuaca Tidak Diketahui');
      expect(WeatherCodes.label(null), 'Cuaca Tidak Diketahui');
    });

    test('tanggal ISO menjadi nama hari Indonesia', () {
      expect(WeatherCodes.dayLabel('2026-10-17'), 'Sab');
      expect(WeatherCodes.dayLabel('2026-10-19'), 'Sen');
    });
  });
}