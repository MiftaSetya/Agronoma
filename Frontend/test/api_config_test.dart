import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/api/api_config.dart';

void main() {
  group('ApiConfig.normalizeHost', () {
    test('localhost diganti host dari baseUrl', () {
      final normalized = ApiConfig.normalizeHost(
        'http://localhost:8000/storage/photos/abc.jpg',
      );

      final base = Uri.parse(ApiConfig.baseUrl);
      expect(normalized, startsWith('${base.scheme}://${base.host}'));
      expect(normalized, endsWith('/storage/photos/abc.jpg'));
    });

    test('127.0.0.1 diganti host dari baseUrl', () {
      final normalized = ApiConfig.normalizeHost(
        'http://127.0.0.1:8000/storage/photos/abc.jpg',
      );

      final base = Uri.parse(ApiConfig.baseUrl);
      expect(normalized, startsWith('${base.scheme}://${base.host}'));
      expect(normalized, endsWith('/storage/photos/abc.jpg'));
    });

    test('host lain dibiarkan apa adanya', () {
      const url = 'https://cdn.example.com/storage/a.jpg';

      expect(ApiConfig.normalizeHost(url), url);
    });

    test('path dan query dipertahankan', () {
      final normalized = ApiConfig.normalizeHost(
        'http://localhost:8000/storage/a.jpg?v=2',
      );

      final base = Uri.parse(ApiConfig.baseUrl);
      expect(normalized, contains('/storage/a.jpg?v=2'));
      expect(
        normalized.startsWith('${base.scheme}://${base.host}'),
        isTrue,
      );
    });
  });
}
