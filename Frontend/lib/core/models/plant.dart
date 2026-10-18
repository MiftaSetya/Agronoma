import 'package:flutter/material.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';

enum CareStatus {
  needsWater,
  needsFertilizer,
  safe;

  String get label => switch (this) {
    CareStatus.needsWater => 'Perlu Disiram',
    CareStatus.needsFertilizer => 'Perlu Pupuk',
    CareStatus.safe => 'Kondisi Aman',
  };

  Color get tint => switch (this) {
    CareStatus.needsWater => AppColors.careWaterTint,
    CareStatus.needsFertilizer => AppColors.careFertilizeSurface,
    CareStatus.safe => const Color(0x4DBEF372),
  };

  Color get border => switch (this) {
    CareStatus.needsWater => AppColors.careWaterLight,
    CareStatus.needsFertilizer => AppColors.careFertilizeSoft,
    CareStatus.safe => const Color(0x80BEF372),
  };

  Color get foreground => switch (this) {
    CareStatus.needsWater => AppColors.careWater,
    CareStatus.needsFertilizer => AppColors.careFertilize,
    CareStatus.safe => AppColors.primary,
  };
}

enum GrowthPhase {
  seedling('Semai Biji', 'Benih baru ditanam atau mulai berkecambah.'),
  vegetativeEarly(
    'Vegetatif Awal',
    'Daun muda mulai tumbuh, ukuran tanaman masih kecil.',
  ),
  vegetativeLate(
    'Vegetatif Akhir',
    'Tanaman tampak rimbun dengan batang dan daun yang kuat.',
  ),
  generative(
    'Generatif',
    'Tanaman mulai berbunga, berbuah, atau membentuk biji.',
  );

  const GrowthPhase(this.label, this.description);

  final String label;
  final String description;

  static const Map<GrowthPhase, (String, double, double)> _icons = {
    GrowthPhase.seedling: (AppAssets.phaseSeedling, 16, 16),
    GrowthPhase.vegetativeEarly: (AppAssets.phaseVegetativeEarly, 19, 17),
    GrowthPhase.vegetativeLate: (AppAssets.phaseVegetativeLate, 16, 25.0086),
    GrowthPhase.generative: (AppAssets.phaseGenerative, 16, 19),
  };

  String get iconAsset => _icons[this]!.$1;
  double get iconWidth => _icons[this]!.$2;
  double get iconHeight => _icons[this]!.$3;

  String get slug => name;
}

enum PlantingMedia {
  pot(
    'Pot tanaman',
    'Cocok untuk ruangan terbatas, balkon, atau tanaman hias di dalam '
        'wadah/pot.',
  ),
  ground(
    'Pekarangan rumah',
    'Ditanam di halaman sekitar rumah atau area tanah terbatas di sekitar '
        'hunian.',
  ),
  openField(
    'Lahan terbuka',
    'Ditanam di area tanah yang luas tanpa batas, seperti perkebunan, sawah, '
        'atau ladang.',
  );

  const PlantingMedia(this.label, this.description);

  final String label;
  final String description;
}

enum CareTaskKind {
  watering,
  fertilizing;

  String get actionLabel => switch (this) {
    CareTaskKind.watering => 'Siram Tanaman',
    CareTaskKind.fertilizing => 'Pupuk Tanaman',
  };
}

class CareTask {
  const CareTask({
    required this.title,
    required this.date,
    required this.done,
    this.description = '',
    this.kind = CareTaskKind.watering,
    this.note,
  });

  final String title;
  final String date;
  final String description;
  final bool done;
  final CareTaskKind kind;

  final String? note;

  CareTask copyWith({bool? done}) => CareTask(
    title: title,
    date: date,
    description: description,
    done: done ?? this.done,
    kind: kind,
    note: note,
  );

  factory CareTask.fromJson(Map<String, dynamic> json) => CareTask(
    title: json['title'] as String,
    date: json['date'] as String,
    description: json['description'] as String? ?? '',
    done: json['done'] as bool? ?? false,
    kind: json['kind'] == null
        ? CareTaskKind.watering
        : CareTaskKind.values.byName(json['kind'] as String),
    note: json['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date,
    'description': description,
    'done': done,
    'kind': kind.name,
    'note': note,
  };
}

class GrowthMilestone {
  const GrowthMilestone({
    required this.label,
    required this.date,
    required this.reached,
  });

  final String label;
  final String date;

  final bool reached;

  factory GrowthMilestone.fromJson(Map<String, dynamic> json) =>
      GrowthMilestone(
        label: json['label'] as String,
        date: json['date'] as String,
        reached: json['reached'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'date': date,
    'reached': reached,
  };
}

@immutable
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.location,
    required this.place,
    required this.media,
    required this.status,
    required this.phase,
    required this.plantedAt,
    required this.careScore,
    required this.description,
    this.scientificName,
    this.tags = const [],
    this.fertilizer = 'NPK Daun',
    this.soilName = 'Tanah gembur',
    this.secondaryStatus,
    this.tasks = const [],
    this.timeline = const [],
  });

  final String id;
  final String name;

  final String photoAsset;

  final String location;

  final String place;

  final PlantingMedia media;
  final CareStatus status;

  final CareStatus? secondaryStatus;

  final GrowthPhase phase;
  final DateTime plantedAt;

  final double careScore;

  final String description;
  final String? scientificName;

  final List<String> tags;

  final String fertilizer;

  final String soilName;

  final List<CareTask> tasks;
  final List<GrowthMilestone> timeline;

  int get phaseIndex => GrowthPhase.values.indexOf(phase);
  int get ageInDays =>
      DateTime.now().difference(plantedAt).inDays.clamp(0, 100000);
  String get ageLabel => '$ageInDays hari';

  Plant copyWith({
    String? name,
    String? location,
    String? place,
    PlantingMedia? media,
    CareStatus? status,
    CareStatus? secondaryStatus,
    GrowthPhase? phase,
    double? careScore,
    String? fertilizer,
    String? soilName,
    List<CareTask>? tasks,
  }) => Plant(
    id: id,
    name: name ?? this.name,
    photoAsset: photoAsset,
    location: location ?? this.location,
    place: place ?? this.place,
    media: media ?? this.media,
    status: status ?? this.status,
    phase: phase ?? this.phase,
    plantedAt: plantedAt,
    careScore: careScore ?? this.careScore,
    description: description,
    scientificName: scientificName,
    tags: tags,
    fertilizer: fertilizer ?? this.fertilizer,
    soilName: soilName ?? this.soilName,
    secondaryStatus: secondaryStatus ?? this.secondaryStatus,
    tasks: tasks ?? this.tasks,
    timeline: timeline,
  );

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String,
    name: json['name'] as String,
    photoAsset: json['photoAsset'] as String,
    location: json['location'] as String,
    place: json['place'] as String? ?? 'Pekarangan Rumah',
    media: PlantingMedia.values.byName(json['media'] as String),
    status: CareStatus.values.byName(json['status'] as String),
    phase: GrowthPhase.values.byName(json['phase'] as String),
    plantedAt: DateTime.parse(json['plantedAt'] as String),
    careScore: (json['careScore'] as num).toDouble(),
    description: json['description'] as String,
    scientificName: json['scientificName'] as String?,
    tags: (json['tags'] as List? ?? const []).cast<String>(),
    fertilizer: json['fertilizer'] as String? ?? 'NPK Daun',
    soilName: json['soilName'] as String? ?? 'Tanah gembur',
    secondaryStatus: json['secondaryStatus'] == null
        ? null
        : CareStatus.values.byName(json['secondaryStatus'] as String),
    tasks: (json['tasks'] as List? ?? [])
        .map((e) => CareTask.fromJson(e as Map<String, dynamic>))
        .toList(),
    timeline: (json['timeline'] as List? ?? [])
        .map((e) => GrowthMilestone.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoAsset': photoAsset,
    'location': location,
    'place': place,
    'media': media.name,
    'status': status.name,
    'secondaryStatus': secondaryStatus?.name,
    'phase': phase.name,
    'plantedAt': plantedAt.toIso8601String(),
    'careScore': careScore,
    'description': description,
    'scientificName': scientificName,
    'tags': tags,
    'fertilizer': fertilizer,
    'soilName': soilName,
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
  };
}
