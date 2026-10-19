import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/state/auth_controller.dart';

void main() {
  const baseUrl = 'http://uji.test/api';

  const stubUser = AppUser(
    id: '1',
    name: 'Petani Uji',
    email: 'uji@agronoma.test',
    photoAsset: '',
    totalPlants: 0,
    harvestedThisSeason: 0,
  );

  ({ApiClient client, InMemoryTokenStore tokens, List<http.Request> calls})
  build(
    Future<http.Response> Function(http.Request request) handler, {
    String? token,
  }) {
    final calls = <http.Request>[];
    final tokens = InMemoryTokenStore(token);
    final client = ApiClient(
      httpClient: MockClient((request) {
        calls.add(request);
        return handler(request);
      }),
      tokenStore: tokens,
      baseUrl: baseUrl,
    );
    return (client: client, tokens: tokens, calls: calls);
  }

  HttpAuthRepository repo(ApiClient client, InMemoryTokenStore tokens) =>
      HttpAuthRepository(apiClient: client, tokenStore: tokens);

  group('ApiClient', () {
    test('selalu mengirim Accept: application/json', () async {
      final ctx = build((_) async => http.Response('{"data":[]}', 200));
      await ctx.client.get('plants');

      expect(ctx.calls.single.headers['Accept'], 'application/json');
    });

    test('menyisipkan token sebagai Bearer bila tersedia', () async {
      final ctx = build(
        (_) async => http.Response('{"data":[]}', 200),
        token: 'token-abc',
      );
      await ctx.client.get('plants');

      expect(ctx.calls.single.headers['Authorization'], 'Bearer token-abc');
    });

    test('tanpa token tidak mengirim header Authorization', () async {
      final ctx = build((_) async => http.Response('{"data":[]}', 200));
      await ctx.client.get('plants');

      expect(ctx.calls.single.headers.containsKey('Authorization'), isFalse);
    });

    test('401 menjadi ApiException terautentikasi gagal', () async {
      final ctx = build(
        (_) async => http.Response('{"message":"Tidak terautentikasi."}', 401),
      );

      await expectLater(
        ctx.client.get('plants'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('422 memecah errors per field', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Validasi gagal.',
            'errors': {
              'email': ['Email sudah dipakai.'],
              'password': ['Minimal 8 karakter.', 'Cadangan.'],
            },
          }),
          422,
        ),
      );

      try {
        await ctx.client.post('register', body: const {});
        fail('seharusnya melempar');
      } on ApiException catch (e) {
        expect(e.isValidationFailure, isTrue);
        expect(e.fieldErrors['email'], 'Email sudah dipakai.');

        expect(e.fieldErrors['password'], 'Minimal 8 karakter.');
      }
    });

    test('500 tidak membocorkan pesan server ke pengguna', () async {
      final ctx = build(
        (_) async =>
            http.Response('{"message":"Terjadi kesalahan internal."}', 500),
      );

      try {
        await ctx.client.get('plants');
        fail('seharusnya melempar');
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, isNot(contains('internal')));
      }
    });
  });

  group('HttpAuthRepository.login', () {
    test('menyimpan token dan memetakan pengguna', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'user': {
              'id': 7,
              'name': 'Siti Aminah',
              'email': 'siti@agronoma.test',
              'created_at': '2026-01-02T03:04:05.000000Z',
            },
            'token': '1|TOKENRAHASIA',
          }),
          200,
        ),
      );

      final result = await repo(
        ctx.client,
        ctx.tokens,
      ).login(email: 'siti@agronoma.test', password: 'rahasia123');

      expect(result.isSuccess, isTrue);
      expect(result.user!.id, '7');
      expect(result.user!.name, 'Siti Aminah');
      expect(result.user!.joinedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(await ctx.tokens.read(), '1|TOKENRAHASIA');

      expect(ctx.calls.single.url.path, '/api/login');
    });

    test('kredensial salah (422) mengembalikan kegagalan ber-field', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Kredensial salah.',
            'errors': {
              'credentials': ['Email atau password tidak cocok.'],
            },
          }),
          422,
        ),
      );

      final result = await repo(
        ctx.client,
        ctx.tokens,
      ).login(email: 'salah@agronoma.test', password: 'salahsekali');

      expect(result.isSuccess, isFalse);
      expect(
        result.error!.fieldErrors['credentials'],
        'Email atau password tidak cocok.',
      );
      expect(await ctx.tokens.read(), isNull);
    });

    test('token kosong dari server dianggap gagal', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'user': {'id': 1, 'name': 'A'},
          }),
          200,
        ),
      );

      final result = await repo(
        ctx.client,
        ctx.tokens,
      ).login(email: 'a@b.c', password: 'rahasia123');

      expect(result.isSuccess, isFalse);
      expect(await ctx.tokens.read(), isNull);
    });
  });

  group('HttpAuthRepository.register', () {
    test('mengirim password_confirmation sesuai kontrak backend', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'user': {'id': 2, 'name': 'Budi', 'email': 'budi@agronoma.test'},
            'token': '2|TOKEN',
          }),
          201,
        ),
      );

      await repo(ctx.client, ctx.tokens).register(
        name: 'Budi',
        email: 'budi@agronoma.test',
        password: 'rahasia123',
      );

      final body = jsonDecode(ctx.calls.single.body) as Map<String, dynamic>;
      expect(body['password_confirmation'], 'rahasia123');
      expect(body.containsKey('confirmation'), isFalse);
    });
  });

  group('HttpAuthRepository.currentUser', () {
    test('tanpa token tidak memanggil jaringan', () async {
      final ctx = build((_) async => http.Response('{}', 200));

      expect(await repo(ctx.client, ctx.tokens).currentUser(), isNull);
      expect(ctx.calls, isEmpty);
    });

    test('401 membuang token yang kedaluwarsa', () async {
      final ctx = build(
        (_) async => http.Response('{"message":"Tidak terautentikasi."}', 401),
        token: 'token-basi',
      );

      expect(await repo(ctx.client, ctx.tokens).currentUser(), isNull);
      expect(await ctx.tokens.read(), isNull);
    });
  });

  group('HttpAuthRepository.uploadPhoto', () {
    test('mengirim multipart dengan field image dan token bearer', () async {
      final ctx = build(
        (request) async {
          final text = latin1.decode(request.bodyBytes, allowInvalid: true);
          expect(text, contains('name="image"'));
          expect(text, contains('filename="avatar.jpg"'));
          return http.Response(
            jsonEncode({'photo_url': '/storage/photos/profile/baru.jpg'}),
            200,
          );
        },
        token: 'token-abc',
      );

      final dir = await Directory.systemTemp.createTemp('agronoma_photo');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/avatar.jpg');
      await file.writeAsBytes(const [0xFF, 0xD8, 0xFF, 0xD9]);

      final updated = await repo(
        ctx.client,
        ctx.tokens,
      ).uploadPhoto(stubUser, file.path);

      expect(ctx.calls.single.method, 'POST');
      expect(ctx.calls.single.url.path, '/api/profile/photo');
      expect(ctx.calls.single.headers['Authorization'], 'Bearer token-abc');
      expect(updated.photoUrl, '/storage/photos/profile/baru.jpg');
    });
  });

  group('Avatar preferensi pengingat', () {
    test('profil mengembalikan preferensi pengingat ke pengguna', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'total_plants': 2,
            'harvested_count': 1,
            'care_score_percent': 80,
            'preferences': {'watering_reminder_enabled': false},
          }),
          200,
        ),
      );

      final user = await repo(ctx.client, ctx.tokens).refreshStats(stubUser);

      expect(user.totalPlants, 2);
      expect(user.wateringReminderEnabled, isFalse);
      expect(ctx.calls.single.url.path, '/api/profile');
    });

    test('profil tanpa preferensi tidak menimpa nilai terakhir', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({'total_plants': 5, 'harvested_count': 0}),
          200,
        ),
      );

      final user = await repo(
        ctx.client,
        ctx.tokens,
      ).refreshStats(stubUser.copyWith(wateringReminderEnabled: false));

      expect(user.wateringReminderEnabled, isFalse);
    });

    test('menyimpan pengingat memanggil PATCH profile/preferences', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'preferences': {'watering_reminder_enabled': false},
          }),
          200,
        ),
      );

      final user = await repo(
        ctx.client,
        ctx.tokens,
      ).saveWateringReminder(stubUser, false);

      expect(user.wateringReminderEnabled, isFalse);

      final call = ctx.calls.single;
      expect(call.method, 'PATCH');
      expect(call.url.path, '/api/profile/preferences');
      expect(
        (jsonDecode(call.body) as Map<String, dynamic>)[
            'watering_reminder_enabled'],
        isFalse,
      );
    });

    test('AuthController menyimpan preferensi dan memberi tahu pendengar', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'preferences': {'watering_reminder_enabled': false},
          }),
          200,
        ),
      );
      final auth = AuthController(
        authSource: repo(ctx.client, ctx.tokens),
        initialUser: stubUser,
      );

      var notifications = 0;
      auth.addListener(() => notifications++);

      final ok = await auth.setWateringReminder(false);

      expect(ok, isTrue);
      expect(auth.user!.wateringReminderEnabled, isFalse);
      expect(notifications, greaterThan(0));
    });

    test('AuthController mengembalikan false saat server menolak', () async {
      final ctx = build(
        (_) async => http.Response('{"message":"Gagal."}', 500),
        token: null,
      );
      final auth = AuthController(
        authSource: repo(ctx.client, ctx.tokens),
        initialUser: stubUser,
      );

      final ok = await auth.setWateringReminder(false);

      expect(ok, isFalse);
      expect(auth.user!.wateringReminderEnabled, isTrue);
    });
  });

  group('AuthController', () {
    test('login berhasil mengisi sesi', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'user': {'id': 3, 'name': 'Rina', 'email': 'rina@agronoma.test'},
            'token': '3|TOKEN',
          }),
          200,
        ),
      );
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      final ok = await auth.signIn(
        email: 'rina@agronoma.test',
        password: 'rahasia123',
      );

      expect(ok, isTrue);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user!.name, 'Rina');
    });

    test('kredensial salah tidak menandai sesi masuk', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Kredensial salah.',
            'errors': {
              'credentials': ['Email atau password tidak cocok.'],
            },
          }),
          422,
        ),
      );
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      final ok = await auth.signIn(
        email: 'salah@agronoma.test',
        password: 'salahsekali',
      );

      expect(ok, isFalse);
      expect(auth.status, AuthStatus.signedOut);

      final errors = auth.consumeErrors();
      expect(errors['general'], 'Email atau password tidak cocok.');
      expect(errors.containsKey('credentials'), isFalse);
    });

    test('validasi backend per field tetap menempel di kolomnya', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'message': 'Validasi gagal.',
            'errors': {
              'email': ['The email has already been taken.'],
              'password': ['The password field must be at least 8 characters.'],
            },
          }),
          422,
        ),
      );
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      final ok = await auth.signUp(
        name: 'Budi',
        email: 'budi@agronoma.test',
        password: 'rahasia123',
        confirmation: 'rahasia123',
      );

      expect(ok, isFalse);
      final errors = auth.consumeErrors();
      expect(errors['email'], contains('already been taken'));
      expect(errors['password'], contains('at least 8'));
      expect(errors.containsKey('general'), isFalse);
    });

    test('validasi lokal berhenti sebelum memanggil jaringan', () async {
      final ctx = build((_) async => http.Response('{}', 200));
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      final ok = await auth.signIn(email: '  ', password: '');

      expect(ok, isFalse);
      expect(ctx.calls, isEmpty);
      final errors = auth.consumeErrors();
      expect(errors['email'], isNotNull);
      expect(errors['password'], isNotNull);
    });

    test('server tidak terjangkau muncul sebagai kesalahan umum', () async {
      final ctx = build((_) async => throw http.ClientException('mati'));
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      final ok = await auth.signIn(email: 'a@b.c', password: 'rahasia123');

      expect(ok, isFalse);
      expect(auth.consumeErrors()['general'], contains('terhubung'));
    });

    test('restoreSession mengisi sesi dari token tersimpan', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({
            'user': {'id': 9, 'name': 'Pulih', 'email': 'pulih@agronoma.test'},
          }),
          200,
        ),
        token: 'token-tersimpan',
      );
      final auth = AuthController(authSource: repo(ctx.client, ctx.tokens));

      await auth.restoreSession();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user!.name, 'Pulih');
      expect(ctx.calls.single.url.path, '/api/user');
    });

    test('signOut membersihkan token dan sesi', () async {
      final ctx = build(
        (_) async => http.Response('{"message":"Berhasil logout."}', 200),
        token: 'token-aktif',
      );
      final auth = AuthController(
        authSource: repo(ctx.client, ctx.tokens),
        initialUser: null,
      );
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedOut);

      await auth.signOut();

      expect(auth.user, isNull);
      expect(auth.status, AuthStatus.signedOut);
      expect(await ctx.tokens.read(), isNull);
    });
  });
}
