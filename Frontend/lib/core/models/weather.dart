import 'package:flutter/material.dart';

@immutable
class Weather {
  const Weather({
    required this.city,
    required this.condition,
    required this.temperature,
    this.iconAsset,
    this.forecast = const [],
  });

  final String city;

  final String condition;

  final int temperature;

  final String? iconAsset;

  final List<WeatherForecast> forecast;

  String get temperatureLabel => '$temperature°C';

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
    city: json['city'] as String,
    condition: json['condition'] as String,
    temperature: (json['temperature'] as num).toInt(),
    iconAsset: json['iconAsset'] as String?,
    forecast: (json['forecast'] as List? ?? const [])
        .map((e) => WeatherForecast.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'city': city,
    'condition': condition,
    'temperature': temperature,
    'iconAsset': iconAsset,
    'forecast': forecast.map((e) => e.toJson()).toList(),
  };
}

@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.day,
    required this.condition,
    required this.high,
    required this.low,
    this.iconAsset,
  });

  final String day;

  final String condition;

  final int high;
  final int low;
  final String? iconAsset;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      WeatherForecast(
        day: json['day'] as String,
        condition: json['condition'] as String,
        high: (json['high'] as num).toInt(),
        low: (json['low'] as num).toInt(),
        iconAsset: json['iconAsset'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'day': day,
    'condition': condition,
    'high': high,
    'low': low,
    'iconAsset': iconAsset,
  };
}
