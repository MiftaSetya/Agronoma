import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/soil_type.dart';

class BackendCodes {
  BackendCodes._();

  static String plantingMedium(PlantingMedia media) => switch (media) {
    PlantingMedia.pot => 'pot',
    PlantingMedia.ground => 'home_yard',
    PlantingMedia.openField => 'open_land',
  };

  static PlantingMedia plantingMediumFrom(String? code) => switch (code) {
    'home_yard' => PlantingMedia.ground,
    'open_land' => PlantingMedia.openField,
    _ => PlantingMedia.pot,
  };

  static String soilType(SoilType soil) => soil.code;

  static SoilType soilTypeFrom(String? code) => SoilCatalog.byCode(code ?? '');

  static String phase(GrowthPhase phase) => switch (phase) {
    GrowthPhase.seedling => 'seedling',
    GrowthPhase.vegetativeEarly => 'early_vegetative',
    GrowthPhase.vegetativeLate => 'late_vegetative',
    GrowthPhase.generative => 'generative',
  };

  static GrowthPhase phaseFrom(String? code) => switch (code) {
    'early_vegetative' => GrowthPhase.vegetativeEarly,
    'late_vegetative' => GrowthPhase.vegetativeLate,
    'generative' => GrowthPhase.generative,
    _ => GrowthPhase.seedling,
  };

  static CareStatus badgeStatus(String? code) => switch (code) {
    'perlu_disiram' => CareStatus.needsWater,
    'perlu_pupuk' => CareStatus.needsFertilizer,
    _ => CareStatus.safe,
  };
}
