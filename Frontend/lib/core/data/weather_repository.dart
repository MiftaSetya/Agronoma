import 'package:frontend/core/models/weather.dart';

/// Sumber data cuaca.
///
/// Dipisahkan dari [PlantRepository] karena cuaca datang dari layanan lain
/// (di produksi nanti: API cuaca, bukan database kita sendiri).
abstract class WeatherRepository {
  /// Cuaca terkini untuk sebuah kota.
  Future<Weather> current(String city);

  /// Ramalan beberapa hari ke depan.
  Future<List<WeatherForecast>> forecast(String city);
}
