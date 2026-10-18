import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/models/scan_record.dart';

abstract class ScanHistoryRepository {
  Future<List<ScanRecord>> getHistory({int? plantId});
}

class HttpScanHistoryRepository implements ScanHistoryRepository {
  HttpScanHistoryRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<List<ScanRecord>> getHistory({int? plantId}) async {
    final body = await _api.get(
      'pest-scans',
      query: plantId == null ? null : {'user_plant_id': plantId},
    );
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) ScanRecord.fromJson(item),
    ];
  }
}

class SampleScanHistoryRepository implements ScanHistoryRepository {
  const SampleScanHistoryRepository();

  @override
  Future<List<ScanRecord>> getHistory({int? plantId}) async => const [];
}
