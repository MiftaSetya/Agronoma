import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/weather.dart';

/// Cuaca contoh dari [MockData].
///
/// Dipakai mode contoh (`useSampleData`) dan pengujian. Kota yang diminta
/// dipakai apa adanya sebagai label, supaya kartu Home tetap menampilkan kota
/// tanaman pemiliknya walau datanya contoh.
class MockWeatherRepository implements WeatherRepository {
  const MockWeatherRepository();

  @override
  Future<Weather?> forPlant({
    required String plantId,
    required String city,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return Weather(
      city: city,
      condition: MockData.weather.condition,
      temperature: MockData.weather.temperature,
      iconAsset: MockData.weather.iconAsset,
      humidity: MockData.weather.humidity,
      windSpeed: MockData.weather.windSpeed,
      forecast: MockData.forecast,
    );
  }
}
