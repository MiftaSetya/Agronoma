import 'package:flutter/material.dart';

/// Cuaca hari ini, ditampilkan di kartu cuaca pada Home dan langkah wizard.
@immutable
class Weather {
  const Weather({
    required this.city,
    required this.condition,
    required this.temperature,
    this.iconAsset,
    this.humidity,
    this.windSpeed,
  });

  /// Nama kota, mis. "Surabaya".
  final String city;

  /// Kondisi singkat, mis. "Sebagian Berawan".
  final String condition;

  /// Suhu dalam derajat Celsius.
  final int temperature;

  /// Aset SVG ikon cuaca (opsional — kalau null dipakai ikon bawaan).
  final String? iconAsset;

  /// Kelembapan dalam persen.
  final int? humidity;

  /// Kecepatan angin, mis. "12 km/j".
  final String? windSpeed;

  /// Teks suhu siap tampil, mis. "28°C".
  String get temperatureLabel => '$temperature°C';

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
    city: json['city'] as String,
    condition: json['condition'] as String,
    temperature: (json['temperature'] as num).toInt(),
    iconAsset: json['iconAsset'] as String?,
    humidity: (json['humidity'] as num?)?.toInt(),
    windSpeed: json['windSpeed'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'city': city,
    'condition': condition,
    'temperature': temperature,
    'iconAsset': iconAsset,
    'humidity': humidity,
    'windSpeed': windSpeed,
  };
}

/// Satu hari pada ramalan cuaca.
@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.day,
    required this.condition,
    required this.high,
    required this.low,
    this.iconAsset,
  });

  /// Nama hari, mis. "Sen".
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
