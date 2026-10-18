import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/http_disease_repository.dart';
import 'package:frontend/core/data/api/token_store.dart';

class _StubTokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'token-uji';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  late String imagePath;

  setUpAll(() {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}agro-disease-test.jpg',
    );
    file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    imagePath = file.path;
  });

  test('hasil hama dari server dipetakan, bukan hasil contoh', () async {
    http.BaseRequest? captured;
    var body = '';

    final repo = HttpDiseaseRepository(
      apiClient: ApiClient(
        tokenStore: _StubTokenStore(),
        baseUrl: 'http://127.0.0.1:8000/api',
        httpClient: MockClient((request) async {
          captured = request;
          body = utf8.decode(request.bodyBytes, allowMalformed: true);
          return http.Response(
            '{"detected_pest_name":"Kutu Daun",'
            '"ai_confidence":92,'
            '"recommended_action":"Semprot air sabun.",'
            '"is_healthy":false}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final disease = await repo.detect(imagePath: imagePath);

    expect(captured, isNotNull);
    expect(captured!.url.path, endsWith('/pest-scans'));
    expect(body, contains('name="image"'));

    expect(disease.name, 'Kutu Daun');
    expect(disease.confidence, closeTo(0.92, 0.001));
    expect(disease.confidenceLabel, '92%');
    expect(disease.steps.single.detail, 'Semprot air sabun.');
    expect(disease.severity, 'Berat');
  });

  test('tanaman sehat tidak diberi nama hama kosong', () async {
    final repo = HttpDiseaseRepository(
      apiClient: ApiClient(
        tokenStore: _StubTokenStore(),
        baseUrl: 'http://127.0.0.1:8000/api',
        httpClient: MockClient(
          (_) async => http.Response(
            '{"detected_pest_name":null,'
            '"ai_confidence":null,'
            '"recommended_action":"Tanaman tampak sehat.",'
            '"is_healthy":true}',
            201,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
    );

    final disease = await repo.detect(imagePath: imagePath);

    expect(disease.name, 'Tanaman Sehat');
    expect(disease.diseaseType, 'Sehat');
    expect(disease.severity, 'Sehat');
    expect(disease.steps.single.detail, 'Tanaman tampak sehat.');
  });

  test('id tanaman ikut dikirim sebagai field multipart', () async {
    var body = '';

    final repo = HttpDiseaseRepository(
      apiClient: ApiClient(
        tokenStore: _StubTokenStore(),
        baseUrl: 'http://127.0.0.1:8000/api',
        httpClient: MockClient((request) async {
          body = utf8.decode(request.bodyBytes, allowMalformed: true);
          return http.Response(
            '{"detected_pest_name":"Kutu Daun","ai_confidence":50,'
            '"recommended_action":"Semprot."}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      plantId: '4',
    );

    await repo.detect(imagePath: imagePath);

    expect(body, contains('name="user_plant_id"'));
    expect(body, contains('4'));
  });

  test('tanpa foto tidak memanggil server', () async {
    final repo = HttpDiseaseRepository(
      apiClient: ApiClient(
        tokenStore: _StubTokenStore(),
        baseUrl: 'http://127.0.0.1:8000/api',
        httpClient: MockClient(
          (_) async => fail('server tidak boleh dipanggil'),
        ),
      ),
    );

    await expectLater(
      repo.detect(imagePath: null),
      throwsA(isA<ApiException>()),
    );
  });

  test('foto yang tidak ada di perangkat dilaporkan, bukan crash', () async {
    final repo = HttpDiseaseRepository(
      apiClient: ApiClient(
        tokenStore: _StubTokenStore(),
        baseUrl: 'http://127.0.0.1:8000/api',
        httpClient: MockClient(
          (_) async => fail('server tidak boleh dipanggil'),
        ),
      ),
    );

    await expectLater(
      repo.detect(imagePath: '/tidak/ada/foto.jpg'),
      throwsA(isA<ApiException>()),
    );
  });
}
