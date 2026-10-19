import 'dart:io';

import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_config.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/models/disease.dart';

class HttpDiseaseRepository implements DiseaseRepository {
  HttpDiseaseRepository({required ApiClient apiClient, String? plantId})
    : _client = apiClient,
      _defaultPlantId = plantId;

  final ApiClient _client;

  final String? _defaultPlantId;

  static const Duration _aiTimeout = Duration(seconds: 120);

  static const String _healthyName = 'Tanaman Sehat';

  @override
  Future<Disease> detect({String? imagePath, String? plantId}) async {
    final path = imagePath;

    if (path == null || path.isEmpty) {
      throw const ApiException(
        message: 'Foto tidak tersedia. Ambil ulang gambar tanaman.',
      );
    }

    final file = File(path);

    if (!await file.exists()) {
      throw const ApiException(
        message: 'Foto tidak ditemukan di perangkat. Ambil ulang gambar.',
      );
    }

    final bytes = await file.readAsBytes();

    final targetPlant = plantId ?? _defaultPlantId;

    final raw = await _client.postMultipart(
      'pest-scans',
      field: 'image',
      bytes: bytes,
      filename: _filename(path),
      timeout: _aiTimeout,
      fields: {
        if (targetPlant != null && targetPlant.isNotEmpty)
          'user_plant_id': targetPlant,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Balasan server tidak dikenali.',
        statusCode: 500,
      );
    }

    return _toDisease(raw);
  }

  String _filename(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;

    return name.isEmpty ? 'foto-tanaman.jpg' : name;
  }

  Disease _toDisease(Map<String, dynamic> json) {
    final rawName = (json['detected_pest_name'] as String?)?.trim();

    final pestName = rawName == null || rawName.isEmpty
        ? _healthyName
        : rawName;

    final rawConfidence = json['ai_confidence'];

    final confidence = rawConfidence is num
        ? (rawConfidence.toDouble() / 100).clamp(0.0, 1.0)
        : 0.0;

    final action = (json['recommended_action'] as String? ?? '').trim();

    return Disease(
      name: pestName,
      scientificName: '',
      diseaseType: pestName == _healthyName ? 'Sehat' : 'Hama',
      cause: '',
      symptoms: const [],
      steps: [
        DiseaseStep(
          title: pestName == _healthyName
              ? 'Tidak perlu tindakan'
              : 'Penanganan',
          detail: action.isEmpty
              ? 'Tidak ada saran penanganan dari server.'
              : action,
        ),
      ],
      confidence: confidence,
      severity: _severityFor(pestName, confidence),
      photoAsset: _normalizeUrl(json['image_url'] as String?),
    );
  }

  static String? _normalizeUrl(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return ApiConfig.normalizeHost(trimmed);
  }

  String _severityFor(String pestName, double confidence) {
    if (pestName == _healthyName) return 'Sehat';
    if (confidence >= 0.8) return 'Berat';
    if (confidence >= 0.5) return 'Sedang';

    return 'Ringan';
  }
}
