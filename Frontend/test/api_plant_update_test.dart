import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/http_plant_repository.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';

class _StubTokenStore implements TokenStore {
  @override
  Future<String?> read() async => 'token-uji';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

Map<String, dynamic> _plantJson() => {
  'id': 6,
  'plant_name': 'Kangkung',
  'planting_medium': 'pot',
  'soil_type': 'fertile',
  'current_phase': 'seedling',
  'planting_date': '2026-10-17',
  'status': 'active',
  'badge_status': 'kondisi_aman',
  'location': {
    'id': 9,
    'label': 'Rumah',
    'city': 'Surabaya',
    'province': 'Jawa Timur',
  },
};

/// Merekam body `PATCH` yang benar-benar dikirim ke backend.
void main() {
  late List<Map<String, dynamic>> patches;

  HttpPlantRepository build() {
    patches = [];

    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'PATCH') {
          patches.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(
            jsonEncode({'plant': _plantJson()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'plant': _plantJson()}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      tokenStore: _StubTokenStore(),
      baseUrl: 'http://127.0.0.1:8000/api',
    );

    return HttpPlantRepository(apiClient: client);
  }

  test('nama, media tanam, dan jenis tanah benar-benar dikirim', () async {
    final repo = build();

    await repo.updatePlant(
      '6',
      name: 'Bayam Merah',
      place: PlantingMedia.openField.label,
      phase: GrowthPhase.vegetativeEarly,
      soilName: SoilCatalog.byCode('volcanic').name,
    );

    expect(patches, hasLength(1));

    final body = patches.single;
    expect(body['plant_name'], 'Bayam Merah');
    expect(body['planting_medium'], 'open_land');
    expect(body['soil_type'], 'volcanic');
    expect(body['current_phase'], 'early_vegetative');
  });

  test('nama kosong tidak dikirim, jadi tidak menimpa nama lama', () async {
    final repo = build();

    await repo.updatePlant('6', name: '   ');

    // Tidak ada yang berubah → tidak perlu PATCH sama sekali.
    expect(patches, isEmpty);
  });

  test('nama jenis tanah tak dikenal tidak dikirim', () async {
    final repo = build();

    await repo.updatePlant('6', soilName: 'Tanah Bulan');

    expect(patches, isEmpty);
  });

  test('setiap nilai enum media tanam dipetakan ke kode backend', () async {
    for (final media in PlantingMedia.values) {
      final repo = build();
      await repo.updatePlant('6', place: media.label);

      expect(patches, hasLength(1), reason: 'media ${media.label}');
      expect(
        patches.single['planting_medium'],
        isIn(['home_yard', 'open_land', 'pot']),
        reason: 'media ${media.label} menghasilkan kode yang tidak dikenal',
      );
    }
  });
}
