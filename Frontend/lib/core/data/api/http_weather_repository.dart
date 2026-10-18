import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/weather_codes.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/weather.dart';

class HttpWeatherRepository implements WeatherRepository {
  HttpWeatherRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  final Map<String, Weather> _cache = {};

  final Map<String, Future<Weather?>> _inFlight = {};

  @override
  Future<Weather?> forPlant({required String plantId, required String city}) {
    final cached = _cache[city];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[city];
    if (pending != null) return pending;

    final request = _load(plantId: plantId, city: city);
    _inFlight[city] = request;
    return request.whenComplete(() => _inFlight.remove(city));
  }

  Future<Weather?> _load({
    required String plantId,
    required String city,
  }) async {
    try {
      final body = await _api.get('plants/$plantId/weather');
      final raw = body is Map<String, dynamic> ? body['forecast'] : null;
      final weather = WeatherCodes.todayFrom(
        city: city,
        forecast: WeatherCodes.forecastFrom(raw),
      );
      if (weather != null) _cache[city] = weather;
      return weather;
    } catch (_) {
      return null;
    }
  }
}
