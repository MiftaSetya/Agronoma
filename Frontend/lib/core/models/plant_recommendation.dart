import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'soil_type.dart';

@immutable
class PlantRecommendation {
  const PlantRecommendation({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.description,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String photoAsset;
  final String description;

  final List<String> tags;

  bool get bestFor => tags.contains(bestForTag);

  static const String bestForTag = 'Pilihan Terbaik';

  factory PlantRecommendation.fromJson(Map<String, dynamic> json) =>
      PlantRecommendation(
        id: json['id'] as String,
        name: json['name'] as String,
        photoAsset: json['photoAsset'] as String,
        description: json['description'] as String,
        tags: (json['tags'] as List? ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoAsset': photoAsset,
    'description': description,
    'tags': tags,
  };
}

@immutable
class AddPlantDraft {
  const AddPlantDraft({
    this.locationName,
    this.locationAddress,
    this.locationPosition,
    this.locationCity,
    this.locationProvince,
    this.locationId,
    this.locationConfirmed = false,
    this.media,
    this.soil,
    this.soilDetected = false,
    this.soilPhotoPath,
    this.recommendation,
    this.manualName,
    this.manualScientificName,
    this.phase,
  });

  final String? locationName;
  final String? locationAddress;

  final LatLng? locationPosition;

  final String? locationCity;
  final String? locationProvince;

  final int? locationId;

  final bool locationConfirmed;

  final String? media;
  final SoilType? soil;

  final bool soilDetected;

  final String? soilPhotoPath;

  final PlantRecommendation? recommendation;

  final String? manualName;
  final String? manualScientificName;

  final String? phase;

  bool get hasLocation =>
      locationConfirmed || (locationName != null && locationId != null);
  bool get hasMedia => media != null;
  bool get hasSoil => soil != null || soilDetected;
  bool get hasPlant => recommendation != null || manualName != null;

  String get resolvedName =>
      manualName ?? recommendation?.name ?? 'Tanaman Baru';

  AddPlantDraft copyWith({
    String? locationName,
    String? locationAddress,
    LatLng? locationPosition,
    String? locationCity,
    String? locationProvince,
    int? locationId,
    bool? locationConfirmed,
    String? media,
    SoilType? soil,
    bool? soilDetected,
    String? soilPhotoPath,
    PlantRecommendation? recommendation,
    String? manualName,
    String? manualScientificName,
    String? phase,
    bool clearRecommendation = false,
    bool clearManualName = false,
    bool clearLocation = false,
  }) => AddPlantDraft(
    locationName: clearLocation ? null : (locationName ?? this.locationName),
    locationAddress: clearLocation
        ? null
        : (locationAddress ?? this.locationAddress),
    locationPosition: clearLocation
        ? null
        : (locationPosition ?? this.locationPosition),
    locationCity: clearLocation ? null : (locationCity ?? this.locationCity),
    locationProvince: clearLocation
        ? null
        : (locationProvince ?? this.locationProvince),
    locationId: clearLocation ? null : (locationId ?? this.locationId),
    locationConfirmed: clearLocation
        ? false
        : (locationConfirmed ?? this.locationConfirmed),
    media: media ?? this.media,
    soil: soil ?? this.soil,
    soilDetected: soilDetected ?? this.soilDetected,
    soilPhotoPath: soilPhotoPath ?? this.soilPhotoPath,
    recommendation: clearRecommendation
        ? null
        : (recommendation ?? this.recommendation),
    manualName: clearManualName ? null : (manualName ?? this.manualName),
    manualScientificName: clearManualName
        ? null
        : (manualScientificName ?? this.manualScientificName),
    phase: phase ?? this.phase,
  );
}
