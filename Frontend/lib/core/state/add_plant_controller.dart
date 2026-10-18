import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
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
  bool _loading = false;
  Object? _error;

  AddPlantDraft get draft => _draft;
  List<PlantRecommendation> get recommendations => _recommendations;
  List<SoilType> get soilTypes => _soilTypes;
  bool get isLoading => _loading;
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
  }) {
    _draft = _draft.copyWith(
      locationName: name,
      locationAddress: address,
      locationPosition: position,
      locationCity: city,
      locationProvince: province,
    );
    notifyListeners();
  }

  void confirmLocation() {
    _draft = _draft.copyWith(locationConfirmed: true);
    notifyListeners();
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
    return _repository.createPlant(
      name: _draft.resolvedName,
      scientificName: _draft.manualScientificName,
      media: media,
      soil: soil,
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
    _error = null;
    notifyListeners();
  }
}
