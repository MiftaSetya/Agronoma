import 'package:frontend/core/assets/app_assets.dart';

class PlantVisual {
  const PlantVisual({required this.photoAsset, this.tags = const []});

  final String photoAsset;
  final List<String> tags;
}

class PlantCatalog {
  PlantCatalog._();

  static const String fallbackPhoto = AppAssets.photoPotSoil;

  static const Map<String, PlantVisual> visuals = {
    'cabai rawit': PlantVisual(
      photoAsset: AppAssets.photoCabaiRawit,
      tags: ['Indoor'],
    ),
    'cabai keriting': PlantVisual(
      photoAsset: AppAssets.photoCabaiKeriting,
      tags: ['Indoor'],
    ),
    'tomat ceri': PlantVisual(
      photoAsset: AppAssets.photoTomatCeri,
      tags: ['Indoor'],
    ),
    'lidah mertua': PlantVisual(
      photoAsset: AppAssets.photoLidahMertua,
      tags: ['Indoor'],
    ),
    'sansevieria': PlantVisual(
      photoAsset: AppAssets.photoLidahMertua,
      tags: ['Indoor'],
    ),
    'sirih gading': PlantVisual(
      photoAsset: AppAssets.photoSirihGading,
      tags: ['Indoor', 'Outdoor'],
    ),
  };

  static PlantVisual? find(String plantName) {
    final normalized = plantName
        .toLowerCase()
        .split('(')
        .first
        .split(',')
        .first
        .trim();

    for (final entry in visuals.entries) {
      if (normalized.startsWith(entry.key)) return entry.value;
    }
    return null;
  }
}
