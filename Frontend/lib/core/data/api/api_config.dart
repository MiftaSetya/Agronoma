class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const String productionBaseUrl = 'https://agronoma.dbx.web.id/api';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return productionBaseUrl;
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
