import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/models/plant_suitability.dart';

void main() {
  test('PlantSuitability.fromJson memetakan verdict dan skor', () {
    final result = PlantSuitability.fromJson({
      'plant_name': 'Kangkung',
      'verdict': 'marginal',
      'scores': {
        'location_climate_fit': 7,
        'productivity': 8,
        'ease_of_care': 9,
      },
      'reasoning': 'Tanah cukup mendukung, produktivitas baik.',
      'alternative_suggestion': 'Coba Bayam di musim hujan.',
    });

    expect(result.plantName, 'Kangkung');
    expect(result.verdict, PlantSuitabilityVerdict.marginal);
    expect(result.climateFit, 70);
    expect(result.productivity, 80);
    expect(result.easeOfCare, 90);
    expect(result.averageScore, 80);
    expect(result.alternativeSuggestion, 'Coba Bayam di musim hujan.');
  });

  test('verdict tidak dikenal jatuh ke marginal', () {
    final result = PlantSuitability.fromJson({
      'plant_name': 'Kangkung',
      'verdict': 'unknown',
      'scores': <String, dynamic>{},
      'reasoning': '',
      'alternative_suggestion': null,
    });

    expect(result.verdict, PlantSuitabilityVerdict.marginal);
    expect(result.averageScore, 0);
  });

  test('skor skala 0-10 dari Gemini dinormalisasi ke 0-100', () {
    final result = PlantSuitability.fromJson({
      'plant_name': 'Kangkung',
      'verdict': 'suitable',
      'scores': {
        'location_climate_fit': 9,
        'productivity': 8,
        'ease_of_care': 8,
      },
      'reasoning': '',
      'alternative_suggestion': null,
    });

    expect(result.climateFit, 90);
    expect(result.productivity, 80);
    expect(result.easeOfCare, 80);
    expect(result.averageScore, 83);
  });
}
