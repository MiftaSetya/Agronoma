import 'package:frontend/core/models/weather.dart';

abstract class WeatherRepository {
  Future<Weather?> forPlant({required String plantId, required String city});
}
