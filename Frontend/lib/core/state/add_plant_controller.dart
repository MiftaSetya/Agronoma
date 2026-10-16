import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/models/soil_type.dart';

/// Menyimpan isian wizard "Tambah Tanaman" yang terbagi atas lima langkah
/// dengan rute masing-masing, sehingga tiap langkah bisa membaca hasil
/// langkah sebelumnya dari satu controller yang sama.
class AddPlantController extends ChangeNotifier {
  /// Nama parameter dibedakan dari field agar lint
  /// `prefer_initializing_formals` tidak menyarankan `this._repository`.
  AddPlantController({required AddPlantRepository dataSource})
    : _repository = dataSource;

  final AddPlantRepository _repository;

  /// Dipakai saat wizard dibuka langsung di langkah 3/4 (pratinjau design dan
  /// widget test) sehingga kota/provinsi belum pernah dipilih: lokasi contoh
  /// design semuanya berada di Surabaya.
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

  /// Media tanam pilihan langkah 2; `pot` dipakai bila langkah itu dilewati.
  PlantingMedia get media =>
      _draft.media == null
          ? PlantingMedia.pot
          : PlantingMedia.values.byName(_draft.media!);

  /// Jenis tanah pilihan langkah 3; "Tanah gembur" dipakai bila dilewati
  /// (langkah 3 bisa dilompati lewat tautan langsung ke langkah 4).
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

  /// Menganalisis foto tanah lewat `POST /soil-scan`, lalu menyimpan jenis
  /// tanahnya ke draft. Mengembalikan `null` bila gagal — pesannya bisa dibaca
  /// dari [error] dan layar kamera menampilkannya tanpa ikut ditutup.
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

  /// Dipakai pratinjau design yang menyemai keadaan hasil analisis tanpa
  /// memanggil kamera; [soil] boleh kosong (memakai jenis tanah pertama).
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

  /// Memilih kartu rekomendasi AI; kartu manual dibuang karena hanya satu
  /// tanaman yang bisa dipilih.
  void selectRecommendation(PlantRecommendation recommendation) {
    _draft = _draft.copyWith(
      recommendation: recommendation,
      clearManualName: true,
    );
    notifyListeners();
  }

  /// Mengisi tanaman secara manual (sheet "Tambah manual tanaman"). Pilihan
  /// kartu rekomendasi dibuang supaya kartu manual menggantikan pilihan AI,
  /// bukan tersembunyi di belakangnya.
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

  /// Menyimpan tanaman ke backend (`POST /plants`), termasuk membuat lokasi
  /// bila belum ada dan meminta jadwal perawatan dari AI. Deskripsi diambil
  /// dari kalimat `reasoning` rekomendasi supaya Detail Tanaman tidak kosong.
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

  /// Mengosongkan seluruh draft, dipakai saat memulai wizard dari awal.
  void reset() {
    _draft = const AddPlantDraft();
    _recommendations = const [];
    _error = null;
    notifyListeners();
  }
}
