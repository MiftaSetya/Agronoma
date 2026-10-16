import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/data/weather_repository.dart';

/// Menyediakan daftar tanaman dan cuaca untuk Home, Profile, dan Detail.
class PlantController extends ChangeNotifier {
  /// Parameter `plantRepository`/`weatherRepository` sengaja berbeda nama dari
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
  Weather? _weather;
  List<WeatherForecast> _forecast = const [];
  bool _loading = false;
  Object? _error;

  List<Plant> get plants => _plants;
  Weather? get weather => _weather;

  /// Ramalan cuaca untuk kartu "Perkiraan Cuaca" di Detail Tanaman.
  List<WeatherForecast> get forecast => _forecast;
  bool get isLoading => _loading;
  Object? get error => _error;

  bool get isEmpty => !_loading && _plants.isEmpty;

  /// Jumlah tugas yang belum selesai di seluruh tanaman.
  int get pendingTaskCount =>
      _plants.fold(0, (sum, p) => sum + p.tasks.where((t) => !t.done).length);

  /// Memuat tanaman dan cuaca. Aman dipanggil berkali-kali.
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _plants.isNotEmpty && _weather != null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getPlants(),
        _weatherRepository.current('Surabaya'),
        _weatherRepository.forecast('Surabaya'),
      ]);
      _plants = results[0] as List<Plant>;
      _weather = results[1] as Weather;
      _forecast = results[2] as List<WeatherForecast>;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
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

  /// Menandai tugas perawatan selesai/belum.
  Future<void> toggleTask(String plantId, String taskTitle, bool done) async {
    try {
      final updated = await _repository.setTaskDone(plantId, taskTitle, done);
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      notifyListeners();
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
  /// Catatan masa peralihan: daftar Home masih berasal dari data contoh, jadi
  /// setelah `load(force: true)` tanaman yang baru ditempel ini belum ikut
  /// terbaca (baru muncul lagi setelah `GET /plants` disambungkan).
  void adopt(Plant plant) {
    _plants = [..._plants, plant];
    notifyListeners();
  }
}
