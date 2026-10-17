import 'package:frontend/core/models/weather.dart';

/// Antarmuka sumber data cuaca — dipisah dari `PlantRepository` karena cuaca
/// datang dari layanan lain (API cuaca lewat cache backend), bukan dari tabel
/// tanaman.
///
/// **Bentuk antarmukanya berbasis tanaman, bukan kota.** Backend hanya punya
/// `GET /plants/{id}/weather`, yang mengambil kota dari lokasi tanaman itu.
/// Karena tanaman bisa berada di beberapa tempat, cuaca yang benar adalah cuaca
/// **lokasi tanaman tersebut**; nama kota hanya dipakai sebagai kunci cache di
/// sisi aplikasi supaya dua tanaman di kota yang sama tidak memicu dua
/// permintaan.
abstract class WeatherRepository {
  /// Cuaca hari ini + ramalan untuk lokasi [plantId].
  ///
  /// [city] hanya dipakai sebagai label pada [Weather] dan kunci cache;
  /// sumber kota yang sebenarnya tetap lokasi tanaman di backend.
  ///
  /// Mengembalikan `null` bila belum ada data cuaca untuk lokasi itu (mis.
  /// cache backend belum terisi) — pemanggil memperlakukannya sebagai "jangan
  /// tampilkan kartu", bukan sebagai galat.
  Future<Weather?> forPlant({required String plantId, required String city});
}
