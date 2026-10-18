import 'package:flutter/foundation.dart';

@immutable
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.plantId,
    required this.pestName,
    required this.confidence,
    required this.scannedAt,
    required this.action,
    required this.imageUrl,
  });

  final int id;
  final int? plantId;
  final String pestName;
  final double confidence;
  final DateTime scannedAt;
  final String action;
  final String imageUrl;

  bool get isHealthy => pestName.isEmpty;

  String get confidenceLabel => '${(confidence * 100).round()}%';

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    final rawConfidence = json['ai_confidence'];

    return ScanRecord(
      id: (json['id'] as num).toInt(),
      plantId: json['user_plant_id'] is num
          ? (json['user_plant_id'] as num).toInt()
          : null,
      pestName: (json['detected_pest_name'] as String?)?.trim() ?? '',
      confidence: rawConfidence is num
          ? (rawConfidence.toDouble() / 100).clamp(0.0, 1.0)
          : 0.0,
      scannedAt:
          DateTime.tryParse(json['scanned_at'] as String? ?? '') ??
          DateTime.now(),
      action: (json['recommended_action'] as String? ?? '').trim(),
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
