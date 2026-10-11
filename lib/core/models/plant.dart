import 'package:flutter/material.dart';

import 'package:frontend/core/theme/theme.dart';

/// Kondisi perawatan sebuah tanaman.
///
/// Dipakai oleh kartu tanaman di Home dan oleh chip "KONDISI AMAN" /
/// "PERLU DISIRAM" / "PERLU PUPUK" pada design. Nilainya sengaja
/// dipisahkan dari warna supaya pemakaian di UI bisa memetakan sendiri.
enum CareStatus {
  /// Butuh disiram — biru (`AppColors.careWater*`).
  needsWater,

  /// Butuh dipupuk — kuning (`AppColors.careFertilize*`).
  needsFertilizer,

  /// Tidak ada tindakan mendesak — hijau (`AppColors.primaryTint`).
  safe;

  /// Label chip huruf kapital seperti di design.
  String get label => switch (this) {
    CareStatus.needsWater => 'Perlu Disiram',
    CareStatus.needsFertilizer => 'Perlu Pupuk',
    CareStatus.safe => 'Kondisi Aman',
  };

  /// Warna latar chip.
  Color get tint => switch (this) {
    CareStatus.needsWater => AppColors.careWaterTint,
    CareStatus.needsFertilizer => AppColors.careFertilizeSurface,
    CareStatus.safe => const Color(0x4DBEF372),
  };

  /// Warna garis tepi chip.
  Color get border => switch (this) {
    CareStatus.needsWater => AppColors.careWaterLight,
    CareStatus.needsFertilizer => AppColors.careFertilizeSoft,
    CareStatus.safe => const Color(0x80BEF372),
  };

  /// Warna teks chip.
  Color get foreground => switch (this) {
    CareStatus.needsWater => AppColors.careWater,
    CareStatus.needsFertilizer => AppColors.careFertilize,
    CareStatus.safe => AppColors.primary,
  };
}

/// Fase pertumbuhan tanaman (langkah 5 wizard tambah tanaman).
enum GrowthPhase {
  seedling('Semai', 'Baru berkecambah, masih sangat rentan.'),
  vegetative('Vegetatif', 'Tumbuh daun dan batang, butuh nitrogen tinggi.'),
  generative('Generatif', 'Mulai berbunga dan berbuah.'),
  harvest('Panen', 'Siap atau sedang dipanen.');

  const GrowthPhase(this.label, this.description);

  final String label;
  final String description;
}

/// Cara menanam / media tanam (langkah 2 wizard).
enum PlantingMedia {
  ground('Tanah Langsung', 'Ditanam di tanah pekarangan atau kebun.'),
  pot('Pot', 'Ditanam di pot, mudah dipindah dan diatur.'),
  polybag('Polybag', 'Cocok untuk lahan sempit dan tanaman muda.'),
  hydroponic('Hidroponik', 'Tanpa tanah, memakai air kaya nutrisi.');

  const PlantingMedia(this.label, this.description);

  final String label;
  final String description;
}

/// Satu tugas perawatan pada tab "Perawatan".
class CareTask {
  const CareTask({
    required this.title,
    required this.date,
    required this.done,
    this.note,
  });

  /// Judul tugas, mis. "Siram tanaman".
  final String title;

  /// Tanggal tampil di kartu tugas, mis. "Hari ini".
  final String date;

  /// Sudah dikerjakan atau belum.
  final bool done;

  /// Catatan tambahan (opsional).
  final String? note;

  CareTask copyWith({bool? done}) => CareTask(
    title: title,
    date: date,
    done: done ?? this.done,
    note: note,
  );

  factory CareTask.fromJson(Map<String, dynamic> json) => CareTask(
    title: json['title'] as String,
    date: json['date'] as String,
    done: json['done'] as bool? ?? false,
    note: json['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date,
    'done': done,
    'note': note,
  };
}

/// Satu tonggak pada timeline pertumbuhan (tab "Ringkasan").
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

/// Model tanaman.
///
/// Immutable dan punya `fromJson`/`toJson` sejak awal supaya penggantian
/// repositori mock ke HTTP tidak menyentuh lapisan UI sama sekali.
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
    this.tasks = const [],
    this.timeline = const [],
  });

  final String id;
  final String name;

  /// Path aset lokal (mis. `assets/images/<sha>.jpg`).
  final String photoAsset;

  /// Kota tempat tanaman tumbuh, mis. "Surabaya".
  final String location;

  /// Tempat spesifik, mis. "Pekarangan Rumah" (titik pemisah di kartu).
  final String place;

  final PlantingMedia media;
  final CareStatus status;
  final GrowthPhase phase;
  final DateTime plantedAt;

  /// Skor perawatan 0–100 (dipakai di kartu "Skor perawatan").
  final double careScore;

  final String description;
  final String? scientificName;

  final List<CareTask> tasks;
  final List<GrowthMilestone> timeline;

  /// Umur tanaman dalam hari.
  int get ageInDays =>
      DateTime.now().difference(plantedAt).inDays.clamp(0, 100000);

  /// Umur dalam bentuk yang enak dibaca, mis. "12 hari".
  String get ageLabel => '$ageInDays hari';

  Plant copyWith({
    String? name,
    String? location,
    String? place,
    PlantingMedia? media,
    CareStatus? status,
    GrowthPhase? phase,
    double? careScore,
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
    'phase': phase.name,
    'plantedAt': plantedAt.toIso8601String(),
    'careScore': careScore,
    'description': description,
    'scientificName': scientificName,
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
  };
}
