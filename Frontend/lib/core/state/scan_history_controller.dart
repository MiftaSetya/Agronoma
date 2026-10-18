import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/scan_history_repository.dart';
import 'package:frontend/core/models/scan_record.dart';

class ScanHistoryController extends ChangeNotifier {
  ScanHistoryController(this._source);

  final ScanHistoryRepository _source;

  final Map<String, List<ScanRecord>> _byPlant = {};
  bool _loading = false;
  Object? _error;

  bool get isLoading => _loading;
  Object? get error => _error;

  List<ScanRecord> historyFor(String plantId) =>
      List.unmodifiable(_byPlant[plantId] ?? const []);

  Future<void> load(String plantId) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final parsed = int.tryParse(plantId);
      _byPlant[plantId] = await _source.getHistory(
        plantId: parsed == 0 ? null : parsed,
      );
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void invalidate(String plantId) {
    _byPlant.remove(plantId);
  }

  void reset() {
    _byPlant.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
