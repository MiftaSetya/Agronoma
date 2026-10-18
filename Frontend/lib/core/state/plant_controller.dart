import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/api/plant_schedule.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';

class PlantController extends ChangeNotifier {
  PlantController({
    required PlantRepository plantRepository,
    required WeatherRepository weatherSource,
  }) : _repository = plantRepository,
       _weatherRepository = weatherSource;

  final PlantRepository _repository;
  final WeatherRepository _weatherRepository;

  List<Plant> _plants = const [];

  Map<String, Weather> _weatherByCity = const {};

  Map<String, List<CareDay>> _careDays = const {};

  bool _loading = false;
  Object? _error;

  List<Plant> get plants => _plants;

  List<Weather> get cityWeather =>
      _weatherByCity.values.toList(growable: false);

  Weather? weatherForCity(String city) => _weatherByCity[city];

  List<WeatherForecast> forecastFor(String city) =>
      _weatherByCity[city]?.forecast ?? const [];

  List<CareDay> careDaysFor(String plantId) => _careDays[plantId] ?? const [];

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

  List<Plant> _adopted = const [];

  void reset() {
    _plants = const [];
    _weatherByCity = const {};
    _careDays = const {};
    _adopted = const [];
    _archived = const [];
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _plants.isNotEmpty && _weatherByCity.isNotEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _repository.getPlants();

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

  Plant? findById(String id) {
    for (final p in _plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<Plant> fetch(String id) async {
    final cached = findById(id);
    if (cached != null) return cached;
    final plant = await _repository.getPlant(id);
    _plants = [..._plants, plant];
    notifyListeners();
    return plant;
  }

  Future<void> loadTasks(String plantId) async {
    final plant = findById(plantId);
    if (plant == null) return;
    try {
      final days = await _repository.careDays(plant, today: DateTime.now());

      if (days.isNotEmpty) {
        _careDays = {..._careDays, plantId: days};
      }
      notifyListeners();
    } catch (e) {
      _error = e;
      notifyListeners();
    }
  }

  Future<bool> toggleTask(String plantId, CareTaskKind kind, bool done) async {
    try {
      final updated = await _repository.setTaskDone(plantId, kind, done);
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      _error = null;
      notifyListeners();
      await loadTasks(plantId);
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlant(
    String plantId, {
    String? name,
    String? location,
    int? locationId,
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
        locationId: locationId,
        place: place,
        phase: phase,
        soilName: soilName,
      );
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<void> adopt(Plant plant) async {
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

  List<Plant> _archived = const [];
  List<Plant> get archivedPlants => _archived;

  CareDay? todayCare(String plantId) {
    final days = _careDays[plantId];
    if (days == null || days.isEmpty) return null;
    final key = PlantSchedule.isoDate(DateTime.now());
    for (final day in days) {
      if (day.date == key) return day;
    }
    return null;
  }

  Future<bool> confirmRain(String plantId, {required bool rained}) async {
    final day = todayCare(plantId);
    final logId = day?.wateringLogId;
    if (logId == null) return false;

    try {
      await _repository.confirmRain(logId, rained: rained);
      _error = null;
      notifyListeners();
      await loadTasks(plantId);
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmMoisture(String plantId, {required bool moist}) async {
    final day = todayCare(plantId);
    final logId = day?.wateringLogId;
    if (logId == null) return false;

    try {
      await _repository.moistureFeedback(logId, moist: moist);
      _error = null;
      notifyListeners();
      await loadTasks(plantId);
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadArchived() async {
    try {
      _archived = await _repository.getArchivedPlants();
      _error = null;
    } catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  Future<bool> archive(String plantId) => _setArchived(plantId, true);

  Future<bool> restore(String plantId) => _setArchived(plantId, false);

  Future<bool> _setArchived(String plantId, bool archived) async {
    try {
      await _repository.setArchived(plantId, archived: archived);
      _plants = [
        for (final p in _plants)
          if (p.id != plantId) p,
      ];
      _adopted = [
        for (final p in _adopted)
          if (p.id != plantId) p,
      ];
      _careDays = {..._careDays}..remove(plantId);
      _error = null;
      notifyListeners();
      await loadArchived();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
