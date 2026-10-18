import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/weather.dart';

class WeatherCodes {
  WeatherCodes._();

  static String label(String? code) => switch (code) {
    'sunny' => 'Cerah',
    'partly_cloudy' => 'Sebagian Berawan',
    'cloudy' => 'Berawan',
    'light_rain' => 'Hujan Ringan',
    'moderate_rain' => 'Hujan Sedang',
    'heavy_rain' => 'Hujan Lebat',
    _ => 'Cuaca Tidak Diketahui',
  };

  static String icon(String? code) => switch (code) {
    'sunny' => AppAssets.weatherClear,
    'cloudy' => AppAssets.weatherPartlyCloudy,
    'light_rain' => AppAssets.weatherRain,
    'moderate_rain' => AppAssets.weatherRainAlt,
    'heavy_rain' => AppAssets.weatherRainHeavy,
    _ => AppAssets.weatherPartlyCloudy,
  };

  static List<WeatherForecast> forecastFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          WeatherForecast(
            day: dayLabel(item['date'] as String?),
            condition: label(item['condition'] as String?),
            high: _temp(item['temp_max']),
            low: _temp(item['temp_min']),
            iconAsset: icon(item['condition'] as String?),
          ),
    ];
  }

  static Weather? todayFrom({
    required String city,
    required List<WeatherForecast> forecast,
  }) {
    if (forecast.isEmpty) return null;
    final today = forecast.first;
    return Weather(
      city: city,
      condition: today.condition,

      temperature: ((today.high + today.low) / 2).round(),
      iconAsset: today.iconAsset,

      forecast: forecast,
    );
  }

  static int _temp(Object? value) => value is num ? value.round() : 0;

  static String dayLabel(String? isoDate) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final date = DateTime.tryParse(isoDate ?? '');
    if (date == null) return isoDate ?? '';

    return names[date.weekday - 1];
  }
}
