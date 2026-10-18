import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_location.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/plant_suitability.dart';
import 'package:frontend/core/models/soil_type.dart';

class AddPlantController extends ChangeNotifier {
  AddPlantController({required AddPlantRepository dataSource})
    : _repository = dataSource;

  final AddPlantRepository _repository;

  static const String fallbackCity = 'Surabaya';
  static const String fallbackProvince = 'Jawa Timur';

  AddPlantDraft _draft = const AddPlantDraft();
  List<PlantRecommendation> _recommendations = const [];
  List<SoilType> _soilTypes = const [];
  List<PlantLocation> _locations = const [];
  PlantSuitability? _suitability;
  bool _loadingSuitability = false;
  bool _loading = false;
  bool _loadingLocations = false;
  Object? _error;

  AddPlantDraft get draft => _draft;
  List<PlantRecommendation> get recommendations => _recommendations;
  List<SoilType> get soilTypes => _soilTypes;
  List<PlantLocation> get locations => _locations;
  PlantSuitability? get suitability => _suitability;
  bool get isLoadingSuitability => _loadingSuitability;
  bool get isLoading => _loading;
  bool get isLoadingLocations => _loadingLocations;
  Object? get error => _error;

  PlantingMedia get media => _draft.media == null
      ? PlantingMedia.pot
      : PlantingMedia.values.byName(_draft.media!);

  SoilType get soil => _draft.soil ?? SoilCatalog.types[1];

  String get city => _draft.locationCity ?? fallbackCity;
  String get province => _draft.locationProvince ?? fallbackProvince;

  void setLocation(
    String name,
    String address, {
    LatLng? position,
    String? city,
    String? province,
    int? locationId,
  }) {
    _draft = _draft.copyWith(
      locationName: name,
      locationAddress: address,
      locationPosition: position,
      locationCity: city,
      locationProvince: province,
      locationId: locationId,
    );
    notifyListeners();
  }

  void selectLocation(PlantLocation location) {
    _draft = _draft.copyWith(
      locationName: location.label,
      locationAddress: location.region,
      locationCity: location.city,
      locationProvince: location.province,
      locationId: location.id,
      locationConfirmed: true,
    );
    notifyListeners();
  }

  Future<void> loadLocations() async {
    if (_loadingLocations) return;
    _loadingLocations = true;
    _error = null;
    notifyListeners();
    try {
      _locations = await _repository.getLocations();
    } catch (e) {
      _error = e;
    } finally {
      _loadingLocations = false;
      notifyListeners();
    }
  }

  Future<PlantLocation?> createLocation({
    required String label,
    required String city,
    required String province,
  }) async {
    _error = null;
    try {
      final created = await _repository.createLocation(
        label: label,
        city: city,
        province: province,
      );
      _locations = [created, ..._locations];
      selectLocation(created);
      return created;
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  Future<PlantLocation?> updateLocation(
    int id, {
    required String label,
    required String city,
    required String province,
  }) async {
    _error = null;
    try {
      final updated = await _repository.updateLocation(
        id,
        label: label,
        city: city,
        province: province,
      );
      _locations = [
        for (final l in _locations)
          if (l.id == id) updated else l,
      ];
      if (_draft.locationId == id) {
        _draft = _draft.copyWith(
          locationName: updated.label,
          locationAddress: updated.region,
          locationCity: updated.city,
          locationProvince: updated.province,
        );
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteLocation(int id) async {
    _error = null;
    try {
      await _repository.deleteLocation(id);
      _locations = [
        for (final l in _locations)
          if (l.id != id) l,
      ];
      if (_draft.locationId == id) {
        _draft = _draft.copyWith(
          locationId: null,
          locationConfirmed: false,
          clearLocation: true,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  void confirmLocation() {
    _draft = _draft.copyWith(locationConfirmed: true);
    notifyListeners();
  }

  Future<PlantSuitability?> checkSuitability() async {
    if (_loadingSuitability) return null;
    final plantName = _draft.resolvedName;
    final locationId = _draft.locationId;
    PlantLocation? location;
    for (final l in _locations) {
      if (l.id == locationId) {
        location = l;
        break;
      }
    }

    _loadingSuitability = true;
    _suitability = null;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.checkSuitability(
        plantName: plantName,
        media: media,
        soil: soil,
        city: location?.city ?? city,
        province: location?.province ?? province,
      );
      _suitability = result;
      return result;
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    } finally {
      _loadingSuitability = false;
      notifyListeners();
    }
  }

  void setMedia(String media) {
    _draft = _draft.copyWith(media: media);
    notifyListeners();
  }

  Future<void> loadSoilTypes() async {
    if (_soilTypes.isNotEmpty || _loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _soilTypes = await _repository.getSoilTypes();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectSoil(SoilType soil) {
    _draft = _draft.copyWith(soil: soil);
    notifyListeners();
  }

  Future<SoilScanResult?> scanSoil({String? imagePath}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.scanSoil(imagePath: imagePath);
      _draft = _draft.copyWith(
        soilDetected: true,
        soil: result.soil,
        soilPhotoPath: imagePath,
      );
      return result;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void markSoilDetected({SoilType? soil, String? photoPath}) {
    _draft = _draft.copyWith(
      soilDetected: true,
      soil: soil ?? _soilTypes.firstOrNull,
      soilPhotoPath: photoPath,
    );
    notifyListeners();
  }

  Future<void> loadRecommendations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recommendations = await _repository.getRecommendations(
        media: media,
        soil: soil,
        city: city,
        province: province,
      );
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectRecommendation(PlantRecommendation recommendation) {
    _draft = _draft.copyWith(
      recommendation: recommendation,
      clearManualName: true,
    );
    notifyListeners();
  }

  void setManualPlant(String name, String? scientificName) {
    _draft = _draft.copyWith(
      manualName: name.trim(),
      manualScientificName: scientificName?.trim(),
      clearRecommendation: true,
    );
    notifyListeners();
  }

  void setPhase(String phase) {
    _draft = _draft.copyWith(phase: phase);
    notifyListeners();
  }

  Future<Plant> savePlant({DateTime? plantingDate}) {
    final locationId = _draft.locationId;
    if (locationId == null) {
      throw StateError('Lokasi tanam belum dipilih.');
    }

    return _repository.createPlant(
      name: _draft.resolvedName,
      scientificName: _draft.manualScientificName,
      media: media,
      soil: soil,
      locationId: locationId,
      city: city,
      province: province,
      locationLabel: _draft.locationName ?? 'Lokasi Tanam',
      phase: _draft.phase == null
          ? GrowthPhase.seedling
          : GrowthPhase.values.byName(_draft.phase!),
      description: _draft.recommendation?.description,
      plantingDate: plantingDate,
    );
  }

  void reset() {
    _draft = const AddPlantDraft();
    _recommendations = const [];
    _suitability = null;
    _loadingSuitability = false;
    _error = null;
    notifyListeners();
  }
}
