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

  String? _greeting;

  Map<String, Weather> _weatherByCity = const {};

  Map<String, List<CareDay>> _careDays = const {};

  Map<String, List<CareDay>> _careDaysByMonth = const {};

  bool _loading = false;
  Object? _error;

  List<Plant> get plants => _plants;

  String? get greeting => _greeting;

  List<Weather> get cityWeather =>
      _weatherByCity.values.toList(growable: false);

  Weather? weatherForCity(String city) => _weatherByCity[city];

  List<WeatherForecast> forecastFor(String city) =>
      _weatherByCity[city]?.forecast ?? const [];

  List<CareDay> careDaysFor(String plantId) => _careDays[plantId] ?? const [];

  List<CareDay> calendarDaysFor(String plantId, DateTime month) {
    return _careDaysByMonth['$plantId|${_monthKey(month)}'] ?? const [];
  }

  bool isCalendarLoading(String plantId, DateTime month) =>
      _calendarLoading == '$plantId|${_monthKey(month)}';

  String? _calendarLoading;

  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  Future<void> loadCalendarMonth(String plantId, DateTime month) async {
    final plant = findById(plantId);
    if (plant == null) return;
    final key = '$plantId|${_monthKey(month)}';
    if (_calendarLoading == key) return;
    _calendarLoading = key;
    notifyListeners();
    try {
      final days = await _repository.careDays(plant, month: _monthKey(month));
      _careDaysByMonth = {..._careDaysByMonth, key: days};
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _calendarLoading = null;
      notifyListeners();
    }
  }

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
    _greeting = null;
    _weatherByCity = const {};
    _careDays = const {};
    _careDaysByMonth = const {};
    _calendarLoading = null;
    _adopted = const [];
    _archived = const [];
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _plants.isNotEmpty && _weatherByCity.isNotEmpty) {
      _refreshWeather();
      return;
    }

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
      _greeting = await _repository.dashboardGreeting();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshWeather() async {
    final plants = _plants;
    if (plants.isEmpty) return;
    final refreshed = await _loadWeatherPerCity(plants);
    if (refreshed.isEmpty) return;
    _weatherByCity = refreshed;
    notifyListeners();
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
        _careDaysByMonth = {
          ..._careDaysByMonth,
          '$plantId|${_monthKey(DateTime.now())}': days,
        };
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

  bool _uploadingPhoto = false;

  bool get isUploadingPhoto => _uploadingPhoto;

  Future<bool> uploadPhoto(String plantId, String imagePath) async {
    if (_uploadingPhoto) return false;

    _uploadingPhoto = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.uploadPhoto(plantId, imagePath);
      _plants = [
        for (final p in _plants)
          if (p.id == plantId) updated else p,
      ];
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _uploadingPhoto = false;
      notifyListeners();
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

  Future<bool> postponeWatering(String plantId) async {
    try {
      await _repository.postponeWatering(plantId);
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
      if (!archived) await load(force: true);
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }
}
