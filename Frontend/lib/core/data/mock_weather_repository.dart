import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/weather.dart';

/// Cuaca contoh dari [MockData].
class MockWeatherRepository implements WeatherRepository {
  const MockWeatherRepository();

  @override
  Future<Weather> current(String city) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.weather;
  }

  @override
  Future<List<WeatherForecast>> forecast(String city) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.forecast;
  }
}
