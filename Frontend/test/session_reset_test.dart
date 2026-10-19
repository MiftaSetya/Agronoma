import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/state/session_expiry.dart';

class _MemTokenStore implements TokenStore {
  String? _token;
  int clearCalls = 0;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async {
    clearCalls++;
    _token = null;
  }
}

void main() {
  test('401 menandai sesi berakhir dan membuang token', () async {
    final tokens = _MemTokenStore();
    await tokens.write('token-lama');

    final expiry = SessionExpiry();

    final client = ApiClient(
      tokenStore: tokens,
      sessionExpiry: expiry,
      baseUrl: 'http://127.0.0.1:8000/api',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(client.get('plants'), throwsA(isA<ApiException>()));

    expect(expiry.expired, isTrue);
    expect(tokens.clearCalls, 1);
  });

  test('401 kedua tidak memberi tahu dua kali', () async {
    final expiry = SessionExpiry();
    var notifications = 0;
    expiry.addListener(() => notifications++);

    expiry.markExpired();
    expiry.markExpired();
    expiry.markExpired();

    expect(notifications, 1);
  });

  test('acknowledge mengembalikan ke keadaan normal', () async {
    final expiry = SessionExpiry()..markExpired();
    expect(expiry.expired, isTrue);

    expiry.acknowledge();
    expect(expiry.expired, isFalse);
  });

  test('403 tidak dianggap sesi berakhir', () async {
    final tokens = _MemTokenStore();
    await tokens.write('token-ok');
    final expiry = SessionExpiry();

    final client = ApiClient(
      tokenStore: tokens,
      sessionExpiry: expiry,
      baseUrl: 'http://127.0.0.1:8000/api',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Forbidden.'}),
          403,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(client.get('plants'), throwsA(isA<ApiException>()));

    expect(expiry.expired, isFalse);
    expect(tokens.clearCalls, 0);
  });

  testWidgets('keluar mengosongkan tanaman yang tersisa', (tester) async {
    final controller = PlantController(
      plantRepository: _OnePlantRepository(),
      weatherSource: _NoWeatherRepository(),
    );

    await controller.load();
    expect(controller.plants, hasLength(1));

    controller.reset();

    expect(controller.plants, isEmpty);
    expect(controller.cityWeather, isEmpty);
    expect(controller.error, isNull);
  });

  testWidgets('statistik profil tersimpan setelah refresh', (tester) async {
    final auth = AuthController(
      authSource: _StatsAuthRepository(),
      initialUser: _user(totalPlants: 0, harvested: 0, score: 0),
    );

    await auth.refreshStats();

    expect(auth.user!.totalPlants, 3);
    expect(auth.user!.harvestedThisSeason, 1);
    expect(auth.user!.careScore, 67);
  });

  testWidgets(
    'clearLocalSession mengosongkan pengguna tanpa memanggil server',
    (tester) async {
      final repo = _StatsAuthRepository();
      final auth = AuthController(
        authSource: repo,
        initialUser: _user(totalPlants: 0, harvested: 0, score: 0),
      );

      expect(auth.isSignedIn, isTrue);

      auth.clearLocalSession();

      expect(auth.isSignedIn, isFalse);
      expect(repo.logoutCalls, 0);
    },
  );
}

AppUser _user({
  required int totalPlants,
  required int harvested,
  required double score,
}) => AppUser(
  id: '1',
  name: 'Petani Uji',
  email: 'uji@agronoma.test',
  photoAsset: '',
  totalPlants: totalPlants,
  harvestedThisSeason: harvested,
  careScore: score,
);

class _StatsAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<AppUser> uploadPhoto(AppUser user, String imagePath) async => user;

  @override
  Future<AppUser?> currentUser() async =>
      _user(totalPlants: 0, harvested: 0, score: 0);

  @override
  Future<AppUser> refreshStats(AppUser user) async =>
      user.copyWith(totalPlants: 3, harvestedThisSeason: 1, careScore: 67);

  @override
  Future<AppUser> saveWateringReminder(AppUser user, bool enabled) async =>
      user.copyWith(wateringReminderEnabled: enabled);

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<void> registerDeviceToken(String token) async {}
}

class _OnePlantRepository implements PlantRepository {
  @override
  Future<List<Plant>> getPlants() async => [
    Plant(
      id: '7',
      name: 'Kangkung',
      photoAsset: 'assets/images/plants/kangkung.png',
      location: 'Surabaya',
      place: 'Pot tanaman',
      media: PlantingMedia.pot,
      status: CareStatus.safe,
      phase: GrowthPhase.seedling,
      plantedAt: DateTime(2026, 10, 17),
      careScore: 100,
      description: 'Kangkung.',
    ),
  ];

  @override
  Future<Plant> getPlant(String id) async => (await getPlants()).first;

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
  ) async => (await getPlants()).first;

  @override
  Future<Plant> updatePlant(
    String plantId, {
    String? name,
    String? location,
    int? locationId,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async => (await getPlants()).first;

  @override
  Future<Plant> uploadPhoto(String plantId, String imagePath) async =>
      (await getPlants()).first;

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
  Future<void> postponeWatering(String plantId) async {}
}

class _NoWeatherRepository implements WeatherRepository {
  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async => null;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
