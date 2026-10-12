import 'package:frontend/core/models/weather.dart';

/// Antarmuka sumber data cuaca — dipisah dari [PlantRepository] karena cuaca
/// datang dari layanan lain (API cuaca, bukan database kita).
abstract class WeatherRepository {
  Future<Weather> current(String city);
  Future<List<WeatherForecast>> forecast(String city);
}
