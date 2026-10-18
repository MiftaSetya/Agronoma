import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/api/plant_mapper.dart';
import 'package:frontend/core/models/plant.dart';

Map<String, dynamic> _json({
  int id = 6,
  String name = 'Cabai Rawit',
  String medium = 'pot',
  String soil = 'fertile',
  String phase = 'seedling',
  String badge = 'kondisi_aman',
  String? city = 'Surabaya',
  String? label = 'Rumah',
  dynamic plantingDate = '2026-10-17',
}) => {
  'id': id,
  'plant_name': name,
  'planting_medium': medium,
  'soil_type': soil,
  'current_phase': phase,
  'planting_date': plantingDate,
  'status': 'active',
  'badge_status': badge,
  'location': {'id': 9, 'label': label, 'city': city, 'province': 'Jawa Timur'},
};

void main() {
  group('PlantMapper — identitas tanaman', () {
    test('id dan nama dibaca apa adanya', () {
      final plant = PlantMapper.fromBackend(_json(id: 42, name: 'Selada'));
      expect(plant.id, '42');
      expect(plant.name, 'Selada');
    });

    test('nama kosong memakai sebutan netral, bukan string kosong', () {
      final plant = PlantMapper.fromBackend(_json(name: '   '));
      expect(plant.name, 'Tanaman');
    });
  });

  group('PlantMapper — lokasi', () {
    test('kota dipakai sebagai lokasi karena menjadi kunci cuaca', () {
      final plant = PlantMapper.fromBackend(_json(city: 'Malang'));
      expect(plant.location, 'Malang');
    });

    test('tanpa kota memakai kota cadangan dari wizard', () {
      final plant = PlantMapper.fromBackend(
        _json(city: null),
        fallbackCity: 'Batu',
      );
      expect(plant.location, 'Batu');
    });

    test('tanpa kota dan tanpa cadangan memakai label lokasi', () {
      final plant = PlantMapper.fromBackend(
        _json(city: null, label: 'Kebun Belakang'),
      );
      expect(plant.location, 'Kebun Belakang');
    });

    test('tanpa lokasi sama sekali tidak menghasilkan string kosong', () {
      final json = _json(city: null, label: null)..remove('location');
      final plant = PlantMapper.fromBackend(json);
      expect(plant.location, 'Lokasi Tanam');
      expect(plant.location, isNotEmpty);
    });
  });

  group('PlantMapper — kode backend', () {
    test('dua media tanam dipetakan ke enum design', () {
      expect(
        PlantMapper.fromBackend(_json(medium: 'pot')).media,
        PlantingMedia.pot,
      );
      expect(
        PlantMapper.fromBackend(_json(medium: 'home_yard')).media,
        PlantingMedia.ground,
      );
      expect(
        PlantMapper.fromBackend(_json(medium: 'open_land')).media,
        PlantingMedia.openField,
      );
    });

    test('empat fase pertumbuhan dipetakan ke enum design', () {
      const expected = {
        'seedling': GrowthPhase.seedling,
        'early_vegetative': GrowthPhase.vegetativeEarly,
        'late_vegetative': GrowthPhase.vegetativeLate,
        'generative': GrowthPhase.generative,
      };
      for (final entry in expected.entries) {
        expect(
          PlantMapper.fromBackend(_json(phase: entry.key)).phase,
          entry.value,
          reason: 'fase ${entry.key}',
        );
      }
    });

    test('tiga badge_status dipetakan ke kondisi perawatan', () {
      expect(
        PlantMapper.fromBackend(_json(badge: 'perlu_disiram')).status,
        CareStatus.needsWater,
      );
      expect(
        PlantMapper.fromBackend(_json(badge: 'perlu_pupuk')).status,
        CareStatus.needsFertilizer,
      );
      expect(
        PlantMapper.fromBackend(_json(badge: 'kondisi_aman')).status,
        CareStatus.safe,
      );
    });

    test('kode asing tidak membuat aplikasi gagal', () {
      final plant = PlantMapper.fromBackend(
        _json(
          medium: 'hidroponik',
          soil: 'pasir',
          phase: 'unknown',
          badge: 'x',
        ),
      );
      expect(plant.media, isA<PlantingMedia>());
      expect(plant.soilName, isNotEmpty);
      expect(plant.phase, isA<GrowthPhase>());
      expect(plant.status, isA<CareStatus>());
    });
  });

  group('PlantMapper — data yang tidak dikirim backend', () {
    test('deskripsi AI dipakai bila ada', () {
      final plant = PlantMapper.fromBackend(
        _json(),
        description: 'Cocok di pot karena akarnya pendek.',
      );
      expect(plant.description, 'Cocok di pot karena akarnya pendek.');
    });

    test('deskripsi kosong disusun dari media dan tanah, bukan dikarang', () {
      final plant = PlantMapper.fromBackend(_json());
      expect(plant.description, contains('pot'));
      expect(plant.description, contains('tanah'));
    });

    test('jadwal perawatan tidak dikarang dari resource tanaman', () {
      final plant = PlantMapper.fromBackend(_json());

      expect(plant.tasks, isEmpty);
      expect(plant.timeline, isEmpty);
    });

    test('nama ilmiah hanya terisi bila pemanggil memberikannya', () {
      expect(PlantMapper.fromBackend(_json()).scientificName, isNull);
      expect(
        PlantMapper.fromBackend(
          _json(),
          scientificName: 'Capsicum annuum',
        ).scientificName,
        'Capsicum annuum',
      );
    });

    test('tanggal tanam rusak tidak membuat aplikasi gagal', () {
      final plant = PlantMapper.fromBackend(_json(plantingDate: null));
      expect(plant.plantedAt, isA<DateTime>());
    });
  });
}
