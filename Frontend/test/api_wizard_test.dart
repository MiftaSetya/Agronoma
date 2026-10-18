import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/plant_catalog.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';

void main() {
  const baseUrl = 'http://uji.test/api';

  ({HttpAddPlantRepository repo, List<http.Request> calls}) build(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final calls = <http.Request>[];
    final repo = HttpAddPlantRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) {
          calls.add(request);
          return handler(request);
        }),
        tokenStore: InMemoryTokenStore('token-abc'),
        baseUrl: baseUrl,
      ),
    );
    return (repo: repo, calls: calls);
  }

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  group('BackendCodes', () {
    test('media tanam diterjemahkan ke kode backend', () {
      expect(BackendCodes.plantingMedium(PlantingMedia.pot), 'pot');
      expect(BackendCodes.plantingMedium(PlantingMedia.ground), 'home_yard');
      expect(BackendCodes.plantingMedium(PlantingMedia.openField), 'open_land');

      expect(
        BackendCodes.plantingMedium(PlantingMedia.ground),
        isNot('ground'),
      );
    });

    test('fase pertumbuhan diterjemahkan bolak-balik', () {
      expect(
        BackendCodes.phase(GrowthPhase.vegetativeEarly),
        'early_vegetative',
      );
      expect(
        BackendCodes.phaseFrom('early_vegetative'),
        GrowthPhase.vegetativeEarly,
      );
      expect(
        BackendCodes.phaseFrom(BackendCodes.phase(GrowthPhase.generative)),
        GrowthPhase.generative,
      );
    });

    test('badge backend dipetakan ke kondisi kartu Home', () {
      expect(BackendCodes.badgeStatus('perlu_disiram'), CareStatus.needsWater);
      expect(
        BackendCodes.badgeStatus('perlu_pupuk'),
        CareStatus.needsFertilizer,
      );
      expect(BackendCodes.badgeStatus('kondisi_aman'), CareStatus.safe);
    });

    test('kode tanah tak dikenal jatuh ke jenis paling umum', () {
      expect(BackendCodes.soilTypeFrom('volcanic').code, 'volcanic');

      expect(BackendCodes.soilTypeFrom('entah_apa'), SoilCatalog.types[1]);
    });
  });

  group('PlantCatalog', () {
    test('nama dengan keterangan tanda kurung tetap dikenali', () {
      expect(
        PlantCatalog.find('Lidah Mertua (Sansevieria)')?.photoAsset,
        AppAssets.photoLidahMertua,
      );
      expect(
        PlantCatalog.find('cabai rawit merah')?.photoAsset,
        AppAssets.photoCabaiRawit,
      );
    });

    test('nama tak dikenal tidak diberi chip ruang', () {
      expect(PlantCatalog.find('Tanaman Ajaib'), isNull);
    });
  });

  group('HttpAddPlantRepository.getRecommendations', () {
    test(
      'mengirim media, tanah, kota, dan provinsi lalu memetakan balasan',
      () async {
        final ctx = build(
          (_) async => http.Response(
            jsonEncode({
              'recommendations': [
                {
                  'rank': 1,
                  'plant_name': 'Cabai Rawit',
                  'scores': {
                    'location_climate_fit': 9,
                    'productivity': 8,
                    'ease_of_care': 7,
                  },
                  'reasoning': 'Suhu terik Surabaya cocok untuk cabai rawit.',
                  'estimated_harvest_days': 90,
                },
                {
                  'rank': 2,
                  'plant_name': 'Lidah Mertua (Sansevieria)',
                  'scores': {
                    'location_climate_fit': 8,
                    'productivity': 6,
                    'ease_of_care': 9,
                  },
                  'reasoning': 'Minim perawatan.',
                  'estimated_harvest_days': null,
                },
              ],
            }),
            200,
          ),
        );

        final result = await ctx.repo.getRecommendations(
          media: PlantingMedia.ground,
          soil: SoilCatalog.types[1],
          city: 'Surabaya',
          province: 'Jawa Timur',
        );

        final sent = bodyOf(ctx.calls.single);
        expect(sent['planting_medium'], 'home_yard');
        expect(sent['soil_type'], 'fertile');
        expect(sent['city'], 'Surabaya');
        expect(sent['province'], 'Jawa Timur');

        expect(result.first.name, 'Cabai Rawit');
        expect(result.first.description, contains('Surabaya'));
        expect(result.first.photoAsset, AppAssets.photoCabaiRawit);

        expect(result.first.tags, contains(PlantRecommendation.bestForTag));
        expect(
          result.last.tags,
          isNot(contains(PlantRecommendation.bestForTag)),
        );

        expect(result.first.id, 'ai-1-cabai rawit');
      },
    );

    test('balasan tanpa rekomendasi menghasilkan daftar kosong', () async {
      final ctx = build(
        (_) async => http.Response(jsonEncode({'recommendations': []}), 200),
      );

      expect(
        await ctx.repo.getRecommendations(
          media: PlantingMedia.pot,
          soil: SoilCatalog.types[2],
          city: 'Surabaya',
          province: 'Jawa Timur',
        ),
        isEmpty,
      );
    });
  });

  group('HttpAddPlantRepository.scanSoil', () {
    test('mengunggah foto dan memetakan jenis tanah + keyakinan', () async {
      final ctx = build(
        (_) async => http.Response(
          jsonEncode({'detected_soil_type': 'volcanic', 'ai_confidence': 95}),
          200,
        ),
      );

      final file = _tempImage();
      addTearDown(() => file.deleteSync());

      final result = await ctx.repo.scanSoil(imagePath: file.path);

      final request = ctx.calls.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/soil-scan');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(latin1.decode(request.bodyBytes), contains('name="image"'));
      expect(request.headers['Authorization'], 'Bearer token-abc');

      expect(result.soil, SoilCatalog.byCode('volcanic'));

      expect(result.confidence, closeTo(0.95, 0.0001));
      expect(result.confidencePercent, 95);
    });

    test('tanpa berkas jepretan tidak memanggil server', () async {
      final ctx = build((_) async => http.Response('{}', 200));

      await expectLater(
        ctx.repo.scanSoil(imagePath: null),
        throwsA(isA<ApiException>()),
      );
      expect(ctx.calls, isEmpty);
    });
  });

  group('HttpAddPlantRepository.createPlant', () {
    Map<String, dynamic> plantReply(int locationId) => {
      'id': 12,
      'plant_name': 'Cabai Rawit',
      'planting_medium': 'home_yard',
      'soil_type': 'fertile',
      'current_phase': 'seedling',
      'planting_date': '2026-10-16',
      'status': 'active',
      'badge_status': 'kondisi_aman',
      'location': {
        'id': locationId,
        'label': 'Rumah Kaca Sukolilo',
        'city': 'Surabaya',
        'province': 'Jawa Timur',
      },
    };

    test('locationId terpilih dikirim apa adanya tanpa membuat lokasi', () async {
      final ctx = build((request) async => http.Response(
        jsonEncode({'plant': plantReply(7)}),
        201,
      ));

      final plant = await ctx.repo.createPlant(
        name: 'Cabai Rawit',
        media: PlantingMedia.ground,
        soil: SoilCatalog.types[1],
        locationId: 7,
        city: 'Surabaya',
        province: 'Jawa Timur',
        locationLabel: 'Rumah Kaca Sukolilo',
        phase: GrowthPhase.seedling,
        description: 'Suhu terik Surabaya cocok untuk cabai rawit.',
        plantingDate: DateTime(2026, 10, 16),
      );

      expect(ctx.calls, hasLength(1));
      expect(ctx.calls.single.url.path, '/api/plants');

      final sent = bodyOf(ctx.calls.single);
      expect(sent['location_id'], 7);
      expect(sent['plant_name'], 'Cabai Rawit');
      expect(sent['planting_medium'], 'home_yard');
      expect(sent['soil_type'], 'fertile');
      expect(sent['current_phase'], 'seedling');
      expect(sent['planting_date'], '2026-10-16');

      expect(plant.id, '12');
      expect(plant.name, 'Cabai Rawit');
      expect(plant.media, PlantingMedia.ground);
      expect(plant.place, PlantingMedia.ground.label);
      expect(plant.location, 'Surabaya');
      expect(plant.locationId, 7);
      expect(plant.soilName, SoilCatalog.types[1].name);
      expect(plant.phase, GrowthPhase.seedling);
      expect(plant.status, CareStatus.safe);
      expect(plant.photoAsset, AppAssets.photoCabaiRawit);
      expect(plant.description, contains('Surabaya'));
      expect(plant.plantedAt, DateTime(2026, 10, 16));
    });

    test('getLocations memetakan daftar lokasi milik pengguna', () async {
      final ctx = build((request) async {
        expect(request.url.path, '/api/locations');
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 7,
                'label': 'Rumah Kaca Sukolilo',
                'city': 'Surabaya',
                'province': 'Jawa Timur',
              },
              {'id': 8, 'label': 'Rumah', 'city': 'Malang'},
            ],
          }),
          200,
        );
      });

      final locations = await ctx.repo.getLocations();

      expect(ctx.calls, hasLength(1));
      expect(locations, hasLength(2));
      expect(locations.first.id, 7);
      expect(locations.first.label, 'Rumah Kaca Sukolilo');
      expect(locations.first.city, 'Surabaya');
      expect(locations.first.province, 'Jawa Timur');
      expect(locations.first.region, 'Surabaya, Jawa Timur');
      expect(locations.last.id, 8);
      expect(locations.last.region, 'Malang');
    });

    test('createLocation mengirim label, kota, dan provinsi', () async {
      final ctx = build((request) async {
        expect(request.url.path, '/api/locations');
        expect(request.method, 'POST');
        final body = bodyOf(request);
        expect(body['label'], 'Pekarangan Belakang');
        expect(body['city'], 'Surabaya');
        expect(body['province'], 'Jawa Timur');
        return http.Response(
          jsonEncode({
            'location': {
              'id': 9,
              'label': 'Pekarangan Belakang',
              'city': 'Surabaya',
              'province': 'Jawa Timur',
            },
          }),
          201,
        );
      });

      final created = await ctx.repo.createLocation(
        label: 'Pekarangan Belakang',
        city: 'Surabaya',
        province: 'Jawa Timur',
      );

      expect(ctx.calls, hasLength(1));
      expect(created.id, 9);
      expect(created.label, 'Pekarangan Belakang');
    });

    test(
      'tanpa deskripsi AI, deskripsi disusun dari media dan tanah',
      () async {
        final ctx = build((request) async => http.Response(
          jsonEncode({
            'plant': {
              'id': 12,
              'plant_name': 'Tanaman Baru',
              'planting_medium': 'pot',
              'soil_type': 'clay',
              'current_phase': 'seedling',
              'planting_date': '2026-10-16',
              'badge_status': 'kondisi_aman',
            },
          }),
          201,
        ));

        final plant = await ctx.repo.createPlant(
          name: 'Tanaman Baru',
          media: PlantingMedia.pot,
          soil: SoilCatalog.byCode('clay'),
          locationId: 7,
          city: 'Surabaya',
          province: 'Jawa Timur',
          locationLabel: 'Rumah Kaca Sukolilo',
          phase: GrowthPhase.seedling,
        );

        expect(plant.description, isNotEmpty);
        expect(
          plant.description,
          contains(PlantingMedia.pot.label.toLowerCase()),
        );

        expect(plant.photoAsset, PlantCatalog.fallbackPhoto);
      },
    );
  });
}

File _tempImage() {
  final file = File(
    '${Directory.systemTemp.path}/agro-soil-${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  file.writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
  return file;
}
