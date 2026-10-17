import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/weather.dart';

/// Penerjemah kode cuaca backend → teks + ikon design.
///
/// Backend **tidak** mengirim teks cuaca: `WeatherApiService::normalizeDay()`
/// meringkasnya menjadi enam kode (`sunny`, `partly_cloudy`, `cloudy`,
/// `light_rain`, `moderate_rain`, `heavy_rain`) supaya mesin keputusan
/// penyiraman tidak bergantung pada kalimat Inggris WeatherAPI. Label Indonesia
/// dan ikonnya karena itu dipetakan di sini.
///
/// Design hanya menyediakan enam berkas ikon cuaca, jadi `moderate_rain`
/// memakai [AppAssets.weatherRain] yang sama dengan `light_rain`; keduanya
/// sama-sama hujan dan tidak ada ikon hujan sedang di aset.
class WeatherCodes {
  WeatherCodes._();

  /// Kode backend → label Indonesia pada kartu cuaca & tile ramalan.
  static String label(String? code) => switch (code) {
    'sunny' => 'Cerah',
    'partly_cloudy' => 'Sebagian Berawan',
    'cloudy' => 'Berawan',
    'light_rain' => 'Hujan Ringan',
    'moderate_rain' => 'Hujan Sedang',
    'heavy_rain' => 'Hujan Lebat',
    _ => 'Cuaca Tidak Diketahui',
  };

  /// Kode backend → aset ikon design.
  ///
  /// `cloudy` sengaja memakai [AppAssets.weatherPartlyCloudy]: tidak ada ikon
  /// "berawan penuh" di aset, dan ikon itu masih lebih tepat daripada ikon
  /// hujan. `null`/kode asing jatuh ke ikon yang sama dengan label "Cuaca
  /// Tidak Diketahui", supaya ikon tidak pernah berbohong soal kondisi.
  static String icon(String? code) => switch (code) {
    'sunny' => AppAssets.weatherClear,
    'cloudy' => AppAssets.weatherPartlyCloudy,
    'light_rain' => AppAssets.weatherRain,
    'moderate_rain' => AppAssets.weatherRainAlt,
    'heavy_rain' => AppAssets.weatherRainHeavy,
    _ => AppAssets.weatherPartlyCloudy,
  };

  /// `forecast` pada `GET /plants/{id}/weather` → [WeatherForecast].
  ///
  /// Endpoint itu mengirim `date`, `condition`, `temp_min`, dan `temp_max` per
  /// hari — tanpa teks kondisi maupun nama hari, jadi keduanya diturunkan di
  /// sini.
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

  /// Baris `forecast` pertama (hari ini) → [Weather] untuk kartu Home.
  ///
  /// `null` bila daftar kosong — artinya backend belum punya baris cache cuaca
  /// untuk kota itu hari ini (mis. cronjob `agronoma:daily-processing` belum
  /// jalan), dan pemanggil sebaiknya tidak menampilkan kartu.
  static Weather? todayFrom({
    required String city,
    required List<WeatherForecast> forecast,
  }) {
    if (forecast.isEmpty) return null;
    final today = forecast.first;
    return Weather(
      city: city,
      condition: today.condition,
      // Kartu Home hanya muat satu angka suhu, sedangkan backend mengirim
      // rentang harian. Titik tengah dipakai supaya angkanya mewakili hari itu,
      // bukan puncak siang atau dinginnya subuh.
      temperature: ((today.high + today.low) / 2).round(),
      iconAsset: today.iconAsset,
      // Kelembapan & kecepatan angin tidak ada di `weather_cache`, jadi
      // dibiarkan kosong alih-alih dikarang.
      forecast: forecast,
    );
  }

  static int _temp(Object? value) =>
      value is num ? value.round() : 0;

  /// Tanggal `YYYY-MM-DD` → nama hari singkat Indonesia ("Sen", "Sel", …).
  ///
  /// Dihitung di perangkat, bukan diambil dari backend, karena backend hanya
  /// mengirim tanggal. Tanggal yang tidak bisa diurai dikembalikan apa adanya
  /// supaya tile-nya tidak kosong.
  static String dayLabel(String? isoDate) {
    const names = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final date = DateTime.tryParse(isoDate ?? '');
    if (date == null) return isoDate ?? '';
    // `DateTime.weekday`: Senin = 1 … Minggu = 7.
    return names[date.weekday - 1];
  }
}
