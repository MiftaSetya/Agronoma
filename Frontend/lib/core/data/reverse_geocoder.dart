import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

@immutable
class GeocodedPlace {
  const GeocodedPlace({
    required this.city,
    required this.province,
    this.displayName,
  });

  final String city;
  final String province;
  final String? displayName;

  bool get isEmpty => city.isEmpty && province.isEmpty;
}

class ReverseGeocoder {
  ReverseGeocoder({http.Client? httpClient}) : _http = httpClient;

  static const String _endpoint = 'https://nominatim.openstreetmap.org/reverse';

  final http.Client? _http;

  Future<GeocodedPlace?> lookup(LatLng point) async {
    final client = _http ?? http.Client();
    final ownsClient = _http == null;

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': point.latitude.toStringAsFixed(6),
        'lon': point.longitude.toStringAsFixed(6),
        'accept-language': 'id',
        'zoom': '14',
      },
    );

    try {
      final response = await client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Agronoma/1.0 (mobile app)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final address = body['address'];
      if (address is! Map<String, dynamic>) return null;

      final place = GeocodedPlace(
        city: _firstOf(address, const [
          'city',
          'town',
          'village',
          'municipality',
          'county',
        ]),
        province: _firstOf(address, const ['state', 'region']),
        displayName: (body['display_name'] as String?)?.trim(),
      );

      return place.isEmpty ? null : place;
    } catch (_) {
      return null;
    } finally {
      if (ownsClient) client.close();
    }
  }

  String _firstOf(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
