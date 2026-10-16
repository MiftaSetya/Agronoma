import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Alamat backend API.
///
/// Nilai bawaan sengaja tidak ditulis mati di dalam widget, tetapi bisa
/// ditimpa saat compile-time:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
/// ```
///
/// Android emulator tidak bisa menjangkau `127.0.0.1` milik host, sehingga
/// alamat khusus `10.0.2.2` dipakai sebagai bawaan di sana.
class ApiConfig {
  ApiConfig._();

  /// Basis URL lengkap, termasuk segmen `/api`.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int port = 8000;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:$port/api';
    }
    return 'http://127.0.0.1:$port/api';
  }
}
