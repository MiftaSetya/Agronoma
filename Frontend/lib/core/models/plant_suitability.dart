import 'package:flutter/material.dart';

@immutable
class PlantSuitability {
  const PlantSuitability({
    required this.plantName,
    required this.verdict,
    required this.climateFit,
    required this.productivity,
    required this.easeOfCare,
    required this.reasoning,
    this.alternativeSuggestion,
  });

  final String plantName;
  final PlantSuitabilityVerdict verdict;
  final int climateFit;
  final int productivity;
  final int easeOfCare;
  final String reasoning;
  final String? alternativeSuggestion;

  int get averageScore => ((climateFit + productivity + easeOfCare) / 3).round();

  String get verdictLabel => switch (verdict) {
    PlantSuitabilityVerdict.suitable => 'Sesuai',
    PlantSuitabilityVerdict.marginal => 'Cukup Sesuai',
    PlantSuitabilityVerdict.notSuitable => 'Kurang Sesuai',
  };

  factory PlantSuitability.fromJson(Map<String, dynamic> json) {
    final scores = json['scores'];
    final map = scores is Map<String, dynamic>
        ? scores
        : const <String, dynamic>{};

    int scaled(Object? raw) {
      final value = (raw as num?)?.toInt() ?? 0;
      return value > 0 && value <= 10 ? value * 10 : value;
    }

    return PlantSuitability(
      plantName: (json['plant_name'] as String? ?? '').trim(),
      verdict: PlantSuitabilityVerdict.values.firstWhere(
        (v) => v.name == json['verdict'],
        orElse: () => PlantSuitabilityVerdict.marginal,
      ),
      climateFit: scaled(map['location_climate_fit']),
      productivity: scaled(map['productivity']),
      easeOfCare: scaled(map['ease_of_care']),
      reasoning: (json['reasoning'] as String? ?? '').trim(),
      alternativeSuggestion: (json['alternative_suggestion'] as String?)?.trim(),
    );
  }
}

enum PlantSuitabilityVerdict { suitable, marginal, notSuitable }
