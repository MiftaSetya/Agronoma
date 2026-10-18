import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int port = 8000;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:$port/api';
    }
    return 'http://127.0.0.1:$port/api';
  }

  static String normalizeHost(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty) return url;
    if (parsed.host != 'localhost' && parsed.host != '127.0.0.1') return url;
    final base = Uri.parse(baseUrl);
    final buffer = StringBuffer('${base.scheme}://${base.host}');
    if (base.hasPort) {
      buffer.write(':${base.port}');
    }
    buffer.write(parsed.path);
    if (parsed.hasQuery) {
      buffer.write('?${parsed.query}');
    }
    return buffer.toString();
  }
}
