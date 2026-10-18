import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/scan_history_repository.dart';
import 'package:frontend/core/models/scan_record.dart';
import 'package:frontend/core/state/scan_history_controller.dart';

class _FakeScanHistoryRepository implements ScanHistoryRepository {
  _FakeScanHistoryRepository(this.items);

  final List<ScanRecord> items;

  int? lastPlantId;

  @override
  Future<List<ScanRecord>> getHistory({int? plantId}) async {
    lastPlantId = plantId;
    return items;
  }
}

void main() {
  test('ScanRecord.fromJson membaca payload PestScanResource', () {
    final record = ScanRecord.fromJson({
      'id': 7,
      'user_plant_id': 4,
      'detected_pest_name': 'Kutu Daun',
      'ai_confidence': 88,
      'recommended_action': 'Semprot insektisida alami.',
      'scanned_at': '2026-10-18T09:30:00Z',
      'image_url': 'http://10.0.2.2:8000/storage/scans/pest/7.jpg',
    });

    expect(record.id, 7);
    expect(record.plantId, 4);
    expect(record.pestName, 'Kutu Daun');
    expect(record.confidence, closeTo(0.88, 0.001));
    expect(record.confidenceLabel, '88%');
    expect(record.action, 'Semprot insektisida alami.');
    expect(record.isHealthy, isFalse);
  });

  test('ScanRecord.fromJson untuk hama kosong dianggap tanaman sehat', () {
    final record = ScanRecord.fromJson({
      'id': 8,
      'user_plant_id': 4,
      'detected_pest_name': '',
      'ai_confidence': null,
      'recommended_action': '',
      'scanned_at': '2026-10-18T09:30:00Z',
      'image_url': '',
    });

    expect(record.isHealthy, isTrue);
    expect(record.confidence, 0);
  });

  test('ScanRecord.fromJson mengganti host localhost ke host baseUrl', () {
    final record = ScanRecord.fromJson({
      'id': 9,
      'detected_pest_name': 'Kutu Daun',
      'ai_confidence': 80,
      'scanned_at': '2026-10-18T09:30:00Z',
      'image_url': 'http://localhost:8000/storage/scans/pest/9.jpg',
    });

    expect(
      record.imageUrl,
      startsWith('http://127.0.0.1:8000/storage/scans/pest/9.jpg'),
    );
  });

  test('ScanRecord.fromJson mempertahankan host selain localhost', () {
    final record = ScanRecord.fromJson({
      'id': 10,
      'detected_pest_name': 'Kutu Daun',
      'ai_confidence': 80,
      'scanned_at': '2026-10-18T09:30:00Z',
      'image_url': 'https://api.agronoma.id/storage/scans/pest/10.jpg',
    });

    expect(record.imageUrl, 'https://api.agronoma.id/storage/scans/pest/10.jpg');
  });

  test('load menyimpan riwayat per plantId dan meneruskan filter plant', () async {
    final source = _FakeScanHistoryRepository(const []);
    final controller = ScanHistoryController(source);

    await controller.load('4');

    expect(source.lastPlantId, 4);
    expect(controller.historyFor('4'), isEmpty);
    expect(controller.error, isNull);
  });

  test('reset mengosongkan semua riwayat', () async {
    final source = _FakeScanHistoryRepository([
      ScanRecord(
        id: 1,
        plantId: 4,
        pestName: 'Kutu Daun',
        confidence: 0.9,
        scannedAt: DateTime(2026, 10, 18),
        action: '',
        imageUrl: '',
      ),
    ]);
    final controller = ScanHistoryController(source);
    await controller.load('4');

    controller.reset();

    expect(controller.historyFor('4'), isEmpty);
    expect(controller.error, isNull);
  });
}
