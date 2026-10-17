import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';

/// Menyediakan daftar tanaman, cuaca **per lokasi**, dan tugas perawatan untuk
/// Home, Profile, dan Detail.
///
/// Cuaca tidak lagi satu untuk semua tanaman. Tanaman pengguna boleh berada di
/// beberapa tempat (dan backend menyimpan lokasi per tanaman), jadi:
///
/// - Beranda menampilkan **satu kartu cuaca per kota unik** — satu kartu untuk
///   tiap tempat tanaman benar-benar tumbuh, bukan kota yang ditebak aplikasi.
/// - Detail Tanaman memakai cuaca **kotanya sendiri** lewat [forecastFor].
/// - Permintaan cuaca di-dedup per kota, sehingga jumlah permintaan hanya
///   bertambah saat kota bertambah, bukan saat tanaman bertambah.
class PlantController extends ChangeNotifier {
  /// Parameter `plantRepository`/`weatherSource` sengaja berbeda nama dari
  /// field-nya karena Dart tidak mengizinkan *named initializing formal* untuk
  /// field privat (`prefer_initializing_formals`).
  PlantController({
    required PlantRepository plantRepository,
    required WeatherRepository weatherSource,
  }) : _repository = plantRepository,
       _weatherRepository = weatherSource;

  final PlantRepository _repository;
  final WeatherRepository _weatherRepository;

  List<Plant> _plants = const [];

  /// Kota → cuaca kota itu. Urutannya mengikuti kemunculan kota pada daftar
  /// tanaman supaya kartu di Beranda tidak berpindah-pindah saat muat ulang.
  Map<String, Weather> _weatherByCity = const {};

  /// Tanaman id → entri care-calendar bulan berjalan.
  ///
  /// Disimpan terpisah dari [Plant] karena bentuknya bukan daftar tugas: layar
  /// Detail memakainya untuk menggambar "Kalender Perawatan" (ikon siram/pupuk
  /// per hari), sedangkan [Plant.tasks] hanya berisi tugas hari ini.
  Map<String, List<CareDay>> _careDays = const {};

  bool _loading = false;
  Object? _error;

  List<Plant> get plants => _plants;

  /// Cuaca semua kota tanaman, siap ditampilkan sebagai kartu berurutan.
  List<Weather> get cityWeather => _weatherByCity.values.toList(growable: false);

  /// Cuaca untuk satu kota, atau `null` bila belum tersedia.
  Weather? weatherForCity(String city) => _weatherByCity[city];

  /// Ramalan cuaca untuk kota [city] — dipakai kartu "Perkiraan Cuaca" di
  /// Detail Tanaman, yang harus mengikuti lokasi tanaman itu sendiri.
  List<WeatherForecast> forecastFor(String city) =>
      _weatherByCity[city]?.forecast ?? const [];

  /// Entri care-calendar bulan berjalan untuk [plantId], atau kosong bila
  /// jadwalnya belum dimuat.
  List<CareDay> careDaysFor(String plantId) => _careDays[plantId] ?? const [];

  /// Tugas "Perawatan Hari Ini" milik [plantId].
  ///
  /// **Dihitung dari [careDaysFor], bukan dibaca dari `Plant.tasks`.** Jadwal
  /// bukan bagian dari resource tanaman di backend: `GET /plants` tidak
  /// memuatnya, dan setiap kali tanaman dimuat ulang (atau diperbarui lewat
  /// `PATCH`/selesai-perawatan) objek `Plant` yang baru akan membawa daftar
  /// tugas kosong. Menyimpannya di `Plant` membuat centang dan muat ulang
  /// saling menghapus; dihitung di sini, hasilnya selalu konsisten dengan
  /// kalender terakhir yang dibaca.
  ///
  /// Data contoh tidak punya kalender, jadi `Plant.tasks` tetap dipakai sebagai
  /// cadangan — itulah satu-satunya sumber tugas di mode contoh. Daftar hari
  /// yang kosong diperlakukan sama dengan "belum dimuat": backend selalu
  /// mengirim sebulan penuh (dengan status `none` untuk hari tanpa jadwal), jadi
  /// daftar kosong berarti memang tidak ada data yang bisa ditafsirkan.
  List<CareTask> tasksFor(String plantId) {
    final plant = findById(plantId);
    if (plant == null) return const [];
    final days = _careDays[plantId];
    if (days == null || days.isEmpty) return plant.tasks;
    return PlantSchedule.tasksForToday(
      days,
      today: DateTime.now(),
      dueFertilizer: plant.status == CareStatus.needsFertilizer,
    );
  }

  bool get isLoading => _loading;
  Object? get error => _error;

  bool get isEmpty => !_loading && _plants.isEmpty;

  /// Tanaman hasil `POST /plants` dari wizard yang ditempel lebih dulu ke daftar
  /// supaya Beranda langsung menampilkannya tanpa menunggu muat ulang.
  ///
  /// Pada jalur HTTP ini hanya jaring pengaman: `GET /plants` sudah
  /// mengembalikan tanaman yang baru disimpan (diverifikasi langsung ke server),
  /// dan penggabungan berdasarkan id membuatnya tidak dobel. Yang benar-benar
  /// bergantung padanya adalah **mode contoh** (`useSampleData`), yang
  /// repositorinya tidak menyimpan tanaman baru sehingga tanpa daftar ini
  /// tanaman hasil wizard akan hilang begitu Beranda dimuat ulang.
  List<Plant> _adopted = const [];

  /// Memuat tanaman dan cuaca tiap lokasi. Aman dipanggil berkali-kali.
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _plants.isNotEmpty && _weatherByCity.isNotEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _repository.getPlants();
      // Tanaman yang baru disimpan wizard digabung kembali: muat ulang tidak
      // boleh menghapus tanaman yang sudah benar-benar tersimpan. Digabung
      // berdasarkan id, dan yang terbaca dari backend selalu menang, supaya
      // tanaman yang sudah ikut terbaca tidak muncul dua kali sebagai data
      // lama.
      final fetchedIds = {for (final p in fetched) p.id};
      _plants = [
        ...fetched,
        for (final p in _adopted)
          if (!fetchedIds.contains(p.id)) p,
      ];
      _weatherByCity = await _loadWeatherPerCity(_plants);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Mengambil cuaca sekali per kota unik.
  ///
  /// Wakil tiap kota adalah tanaman pertama di kota itu, karena endpoint
  /// backend menerima id tanaman (kotanya diambil dari lokasi tanaman
  /// tersebut). Kegagalan satu kota tidak menggagalkan yang lain — cuaca
  /// bersifat pelengkap, jadi kota yang belum punya data cukup dilewati.
  Future<Map<String, Weather>> _loadWeatherPerCity(List<Plant> plants) async {
    final representatives = <String, Plant>{};
    for (final plant in plants) {
      representatives.putIfAbsent(plant.location, () => plant);
    }
    if (representatives.isEmpty) return const {};

    final cities = representatives.keys.toList(growable: false);
    final results = await Future.wait([
      for (final city in cities)
        _weatherRepository
            .forPlant(plantId: representatives[city]!.id, city: city)
            .catchError((Object _) => null),
    ]);

    final weather = <String, Weather>{};
    for (var i = 0; i < cities.length; i++) {
      final entry = results[i];
      if (entry != null) weather[cities[i]] = entry;
    }
    return weather;
  }

  /// Satu tanaman dari daftar yang sudah dimuat (tanpa memanggil jaringan),
  /// dipakai layar Detail agar perpindahan dari Home terasa instan. Kalau id
  /// tidak ada di daftar, repositori dipanggil sekali via [fetch].
  Plant? findById(String id) {
    for (final p in _plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Mengambil satu tanaman, memuat dari repositori bila belum ada di daftar.
  Future<Plant> fetch(String id) async {
    final cached = findById(id);
    if (cached != null) return cached;
    final plant = await _repository.getPlant(id);
    _plants = [..._plants, plant];
    notifyListeners();
    return plant;
  }

  /// Memuat kalender bulan berjalan milik [plantId] (sumber tugas hari ini dan
  /// kartu "Kalender Perawatan" sekaligus).
  ///
  /// Berbeda dari [load]: ini satu permintaan tambahan untuk satu tanaman dan
  /// hanya dipanggil saat tab Perawatan benar-benar dibuka, sehingga daftar
  /// tanaman di Beranda tidak ikut melambat saat jumlahnya bertambah.
  Future<void> loadTasks(String plantId) async {
    final plant = findById(plantId);
    if (plant == null) return;
    try {
      final days = await _repository.careDays(plant, today: DateTime.now());
      // Daftar kosong tidak menimpa apa pun: pada mode contoh memang tidak ada
      // kalender, dan menimpanya akan menghapus tugas contoh yang tersimpan di
      // `Plant.tasks`.
      if (days.isNotEmpty) {
        _careDays = {..._careDays, plantId: days};
      }
      notifyListeners();
    } catch (e) {
      // Jadwal hanya pelengkap tampilan tab Perawatan; kegagalannya dibiarkan
      // terlihat lewat [error] tanpa mengosongkan daftar tanaman.
      _error = e;
      notifyListeners();
    }
  }

  /// Menandai tugas perawatan selesai.
  ///
  /// Setelah backend mencatat aksinya, kalender dibaca ulang: status hari ini
  /// (`need_water` → `watered`) hanya bisa diketahui dari sana, dan tugas yang
  /// tercentang berasal dari kalender itu — bukan dari `Plant.tasks`.
  Future<void> toggleTask(String plantId, CareTaskKind kind, bool done) async {
    try {
      final updated = await _repository.setTaskDone(plantId, kind, done);
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      notifyListeners();
      await loadTasks(plantId);
    } catch (e) {
      // Ditangkap agar kegagalan simpan (mis. saat fetch) tidak melempar dari
      // handler ketukan; pemanggil bisa membaca [error].
      _error = e;
      notifyListeners();
    }
  }

  /// Menyimpan hasil drawer "Setelan Tanaman".
  Future<void> updatePlant(
    String plantId, {
    String? name,
    String? location,
    String? place,
    GrowthPhase? phase,
    String? soilName,
  }) async {
    _error = null;
    try {
      final updated = await _repository.updatePlant(
        plantId,
        name: name,
        location: location,
        place: place,
        phase: phase,
        soilName: soilName,
      );
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  /// Menambahkan tanaman yang **sudah disimpan** wizard ke daftar di memori.
  ///
  /// Penyimpanannya sendiri diurus `AddPlantRepository` (`POST /plants`),
  /// bukan [PlantRepository]; di sini tanaman itu hanya ditempel ke daftar
  /// supaya Home dan Detail langsung bisa membukanya tanpa menunggu muat ulang.
  ///
  /// Kalau tanaman itu berada di kota yang belum punya kartu cuaca, cuacanya
  /// ikut diambil supaya Beranda tidak menampilkan kota tanpa kartu.
  Future<void> adopt(Plant plant) async {
    // Sudah dikenal — mis. sudah ikut terbaca `GET /plants`, atau `adopt`
    // dipanggil dua kali: jangan digandakan.
    if (_plants.any((p) => p.id == plant.id)) return;
    _adopted = [..._adopted, plant];
    _plants = [..._plants, plant];
    notifyListeners();

    if (!_weatherByCity.containsKey(plant.location)) {
      final weather = await _weatherRepository
          .forPlant(plantId: plant.id, city: plant.location)
          .catchError((Object _) => null);
      if (weather != null) {
        _weatherByCity = {..._weatherByCity, plant.location: weather};
        notifyListeners();
      }
    }
  }
}
