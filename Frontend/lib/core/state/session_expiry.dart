import 'package:flutter/foundation.dart';

class SessionExpiry extends ChangeNotifier {
  bool _expired = false;

  bool get expired => _expired;

  void markExpired() {
    if (_expired) return;
    _expired = true;
    notifyListeners();
  }

  void acknowledge() {
    if (!_expired) return;
    _expired = false;
    notifyListeners();
  }
}
