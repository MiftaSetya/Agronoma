import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/weather_codes.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/weather.dart';

/// Cuaca dari cache backend, satu permintaan per kota.
///
/// Backend menyajikan cuaca **per tanaman** (`GET /plants/{id}/weather`) dengan
/// kota diambil dari lokasi tanaman itu. Karena itu antarmukanya menerima
/// `plantId`; `city` hanya dipakai sebagai label dan kunci cache.
///
/// Cache di sini penting untuk penghematan: Beranda menampilkan satu kartu per
/// kota, jadi tanpa cache sepuluh tanaman di satu kota akan menghasilkan
/// sepuluh permintaan untuk data yang identik (backend menyimpan cache dengan
/// kunci `(city, province, date)`).
class HttpWeatherRepository implements WeatherRepository {
  HttpWeatherRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Kota → cuaca yang sudah dibaca pada sesi ini.
  final Map<String, Weather> _cache = {};

  /// Kota → permintaan yang sedang berjalan, supaya Beranda dan Detail yang
  /// dibuka hampir bersamaan tidak mengirim dua permintaan untuk kota yang
  /// sama.
  final Map<String, Future<Weather?>> _inFlight = {};

  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) {
    final cached = _cache[city];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[city];
    if (pending != null) return pending;

    final request = _load(plantId: plantId, city: city);
    _inFlight[city] = request;
    return request.whenComplete(() => _inFlight.remove(city));
  }

  Future<Weather?> _load({required String plantId, required String city}) async {
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
      // Cuaca bersifat pelengkap: satu kota tanpa cache (cronjob belum jalan)
      // tidak boleh menggagalkan Beranda.
      return null;
    }
  }
}
