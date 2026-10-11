import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Memegang data yang dikumpulkan sepanjang wizard "Tambah Tanaman".
///
/// Wizard ini terdiri dari lima langkah yang masing-masing punya rutenya
/// sendiri. Dengan menyimpan pilihan di satu controller, tiap langkah bisa
/// membaca hasil langkah sebelumnya, dan rute cukup membawa sedikit argumen.
class AddPlantController extends ChangeNotifier {
  /// Nama parameter dibedakan dari nama field supaya lint
  /// `prefer_initializing_formals` tidak menyarankan `this._repository`
  /// (tidak mungkin untuk parameter bernama yang privat).
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

  // ── Langkah 1: lokasi ────────────────────────────────────────────────────

  void setLocation(String name, String address) {
    _draft = _draft.copyWith(locationName: name, locationAddress: address);
    notifyListeners();
  }

  void confirmLocation() {
    _draft = _draft.copyWith(locationConfirmed: true);
    notifyListeners();
  }

  // ── Langkah 2: media tanam ───────────────────────────────────────────────

  void setMedia(String media) {
    _draft = _draft.copyWith(media: media);
    notifyListeners();
  }

  // ── Langkah 3: tanah ─────────────────────────────────────────────────────

  /// Memuat daftar jenis tanah (sekali saja).
  Future<void> loadSoilTypes() async {
    if (_soilTypes.isNotEmpty || _loading) return;
    _loading = true;
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

  // ── Langkah 4: rekomendasi ───────────────────────────────────────────────

  /// Meminta rekomendasi tanaman sesuai lokasi + tanah yang dipilih.
  Future<void> loadRecommendations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recommendations = await _repository.getRecommendations(
        location: _draft.locationName ?? '-',
        soil: _draft.soil ?? _soilTypes.first,
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

  // ── Langkah 5: fase ──────────────────────────────────────────────────────

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
