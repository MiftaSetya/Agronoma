import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/data/weather_repository.dart';

/// Menyediakan daftar tanaman dan cuaca untuk Home, Profile, dan Detail.
class PlantController extends ChangeNotifier {
  /// Parameter sengaja diberi nama `plantRepository`/`weatherRepository`
  /// (bukan `repository`) supaya berbeda dari nama field-nya. Kalau namanya
  /// sama, analyzer menyarankan `this._repository`, padahal Dart tidak
  /// mengizinkan *named initializing formal* untuk field privat.
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

  /// Apakah daftar tanaman masih kosong setelah pemuatan pertama.
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

  /// Satu tanaman dari daftar yang sudah dimuat (tanpa memanggil jaringan).
  ///
  /// Dipakai layar Detail supaya perpindahan dari Home terasa instan; kalau
  /// id tidak ada di daftar, repositori dipanggil sekali.
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
    final updated = await _repository.setTaskDone(plantId, taskTitle, done);
    _plants = [
      for (final p in _plants)
        if (p.id == plantId) updated else p,
    ];
    notifyListeners();
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
  }

  /// Menambahkan tanaman baru hasil wizard, lalu mengembalikannya.
  Future<Plant> addPlant({
    required String name,
    String? scientificName,
    required String location,
    required SoilType soil,
    String? phase,
  }) async {
    final plant = await _repository.addPlant(
      name: name,
      scientificName: scientificName,
      location: location,
      soil: soil,
      phase: phase,
    );
    _plants = [..._plants, plant];
    notifyListeners();
    return plant;
  }
}
