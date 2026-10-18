import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'package:frontend/core/data/api/api_config.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/state/session_expiry.dart';

/// Klien HTTP tipis untuk backend Agronoma.
///
/// Tanggung jawabnya sengaja sempit: menyusun URL, memasang header, menyisipkan
/// token, lalu mengubah kesalahan HTTP menjadi [ApiException] berbahasa
/// Indonesia. Bentuk data tiap domain diurus repositori.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStore? tokenStore,
    String? baseUrl,
    SessionExpiry? sessionExpiry,
  }) : _http = httpClient ?? http.Client(),
       _tokens = tokenStore ?? const SecureTokenStore(),
       baseUrl = baseUrl ?? ApiConfig.baseUrl {
    _sessionExpiry = sessionExpiry;
  }

  final http.Client _http;
  final TokenStore _tokens;
  late final SessionExpiry? _sessionExpiry;
  final String baseUrl;

  /// Waktu tunggu standar; endpoint AI bisa lebih lama, jadi pemanggil boleh
  /// menaikkannya lewat [timeout].
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Header `Accept: application/json` wajib: tanpa itu Laravel menganggap
  /// permintaan sebagai navigasi browser dan middleware `auth` mencoba
  /// mengalihkan ke rute `login` (yang tidak ada) sehingga balasannya 500.
  Map<String, String> _headers({String? contentType, String? bearer}) {
    return {
      'Accept': 'application/json',
      'Content-Type': ?contentType,
      'Authorization': ?(bearer == null ? null : 'Bearer $bearer'),
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$baseUrl/$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query.map((k, v) => MapEntry(k, '$v')));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send(
    () async => _http.get(_uri(path, query), headers: await _bearerHeaders()),
  );

  Future<dynamic> delete(String path) => _send(
    () async => _http.delete(_uri(path), headers: await _bearerHeaders()),
  );

  Future<dynamic> post(String path, {Object? body, Duration? timeout}) => _send(
    () async => _http.post(
      _uri(path),
      headers: await _bearerHeaders(contentType: 'application/json'),
      body: body == null ? null : jsonEncode(body),
    ),
    timeout: timeout,
  );

  Future<dynamic> patch(String path, {Object? body}) => _send(
    () async => _http.patch(
      _uri(path),
      headers: await _bearerHeaders(contentType: 'application/json'),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  /// Unggah satu berkas (multipart) — dipakai scan tanah & scan hama.
  Future<dynamic> postMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    Duration? timeout,
  }) => _send(() async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(await _bearerHeaders())
      ..fields.addAll(fields ?? const <String, String>{})
      ..files.add(
        http.MultipartFile.fromBytes(field, bytes, filename: filename),
      );
    final streamed = await _http.send(request);
    return http.Response.fromStream(streamed);
  }, timeout: timeout);

  Future<Map<String, String>> _bearerHeaders({String? contentType}) async {
    final token = await _tokens.read();
    return _headers(contentType: contentType, bearer: token);
  }

  /// Menjalankan permintaan lalu menormalkan hasil/kesalahan.
  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout ?? defaultTimeout);
    } on TimeoutException {
      throw const ApiException(
        message: 'Server tidak merespons. Coba lagi sebentar lagi.',
      );
    } on SocketException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa jaringan Anda.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa jaringan Anda.',
      );
    }

    final body = response.body.isEmpty
        ? null
        : (() {
            try {
              return jsonDecode(response.body) as Object?;
            } on FormatException {
              return null;
            }
          })();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw _toException(response.statusCode, body);
  }

  ApiException _toException(int statusCode, Object? body) {
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};

    if (statusCode == 401) {
      _sessionExpiry?.markExpired();
      _tokens.clear();
    }

    final message = switch (statusCode) {
      401 => 'Sesi Anda berakhir. Silakan masuk kembali.',
      403 => 'Anda tidak berhak mengakses data ini.',
      404 => 'Data yang diminta tidak ditemukan.',
      422 => 'Periksa kembali isian Anda.',
      >= 500 => 'Terjadi gangguan di server. Coba lagi nanti.',
      _ => (map['message'] as String?) ?? 'Permintaan gagal diproses.',
    };

    return ApiException(
      message: message,
      statusCode: statusCode,
      fieldErrors: _parseFieldErrors(map['errors']),
    );
  }

  /// `errors` dari Laravel berbentuk `{field: [pesan, ...]}`; UI hanya perlu
  /// pesan pertama tiap field.
  Map<String, String> _parseFieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, String>{};
    raw.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        result['$key'] = '${value.first}';
      } else if (value is String) {
        result['$key'] = value;
      }
    });
    return result;
  }
}
