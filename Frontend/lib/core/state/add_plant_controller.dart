import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Menyimpan isian wizard "Tambah Tanaman" yang terbagi atas lima langkah
/// dengan rute masing-masing, sehingga tiap langkah bisa membaca hasil
/// langkah sebelumnya dari satu controller yang sama.
class AddPlantController extends ChangeNotifier {
  /// Nama parameter dibedakan dari field agar lint
  /// `prefer_initializing_formals` tidak menyarankan `this._repository`.
  AddPlantController({required PlantRepository dataSource})
    : _repository = dataSource;

  final PlantRepository _repository;

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

  void setLocation(String name, String address, {LatLng? position}) {
    _draft = _draft.copyWith(
      locationName: name,
      locationAddress: address,
      locationPosition: position,
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

  /// Dipakai setelah analisis kamera berhasil.
  void markSoilDetected({SoilType? soil}) {
    _draft = _draft.copyWith(
      soilDetected: true,
      soil: soil ?? _soilTypes.firstOrNull,
    );
    notifyListeners();
  }

  // Wizard bisa dibuka langsung di langkah 4 tanpa melewati langkah 3,
  // jadi _soilTypes bisa kosong (fallback MockData mencegah lemparan .first).
  Future<void> loadRecommendations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recommendations = await _repository.getRecommendations(
        location: _draft.locationName ?? '-',
        soil: _draft.soil ??
            (_soilTypes.isNotEmpty ? _soilTypes.first : MockData.soilTypes.first),
      );
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectRecommendation(PlantRecommendation recommendation) {
    _draft = _draft.copyWith(recommendation: recommendation);
    notifyListeners();
  }

  /// Mengisi tanaman secara manual (sheet "Tambah manual tanaman").
  void setManualPlant(String name, String? scientificName) {
    _draft = _draft.copyWith(
      manualName: name.trim(),
      manualScientificName: scientificName?.trim(),
    );
    notifyListeners();
  }

  void setPhase(String phase) {
    _draft = _draft.copyWith(phase: phase);
    notifyListeners();
  }

  /// Mengosongkan seluruh draft, dipakai saat memulai wizard dari awal.
  void reset() {
    _draft = const AddPlantDraft();
    _recommendations = const [];
    _error = null;
    notifyListeners();
  }
}
