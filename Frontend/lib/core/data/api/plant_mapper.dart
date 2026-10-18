import 'package:frontend/core/data/api/backend_codes.dart';
import 'package:frontend/core/data/plant_catalog.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/soil_type.dart';

class PlantMapper {
  PlantMapper._();

  static Plant fromBackend(
    Map<String, dynamic> json, {
    String? scientificName,
    String? description,
    String? fallbackCity,
  }) {
    final name = (json['plant_name'] as String? ?? '').trim();
    final visual = PlantCatalog.find(name);
    final media = BackendCodes.plantingMediumFrom(
      json['planting_medium'] as String?,
    );
    final soil = SoilCatalog.byCode(json['soil_type'] as String? ?? '');
    final location = json['location'] as Map<String, dynamic>?;
    final plantingDate =
        DateTime.tryParse('${json['planting_date']}') ?? DateTime.now();

    return Plant(
      id: '${json['id']}',
      name: name.isEmpty ? 'Tanaman' : name,
      scientificName: scientificName,
      photoAsset: visual?.photoAsset ?? PlantCatalog.fallbackPhoto,

      location:
          _firstNonEmpty([
            location?['city'] as String?,
            fallbackCity,
            location?['label'] as String?,
          ]) ??
          'Lokasi Tanam',

      locationId: (location?['id'] as num?)?.toInt(),

      place: media.label,
      media: media,
      status: BackendCodes.badgeStatus(json['badge_status'] as String?),
      phase: BackendCodes.phaseFrom(json['current_phase'] as String?),
      plantedAt: plantingDate,

      careScore: 100,
      description: _descriptionOrFallback(
        description: description,
        media: media,
        soil: soil,
      ),
      tags: visual?.tags ?? const [],

      fertilizer: soil.code == 'fertile' ? 'NPK Organik' : 'NPK Daun',
      soilName: soil.name,

      tasks: const [],
      timeline: const [],
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String _descriptionOrFallback({
    required String? description,
    required PlantingMedia media,
    required SoilType soil,
  }) {
    final trimmed = (description ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Ditanam di ${media.label.toLowerCase()} dengan '
        '${soil.name.toLowerCase()}.';
  }
}
