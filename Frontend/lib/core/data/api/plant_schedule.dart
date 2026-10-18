import 'package:frontend/core/models/plant.dart';

class CareDay {
  const CareDay({
    required this.date,
    required this.wateringStatus,
    required this.fertilizingStatus,
    this.wateringLogId,
    this.rainConfirmed,
    this.moistureFeedback,
  });

  final String date;

  final String wateringStatus;

  final String fertilizingStatus;

  final int? wateringLogId;

  final String? rainConfirmed;

  final String? moistureFeedback;

  factory CareDay.fromJson(Map<String, dynamic> json) => CareDay(
    date: '${json['date']}',
    wateringStatus: json['watering_status'] as String? ?? 'none',
    fertilizingStatus: json['fertilizing_status'] as String? ?? 'none',
    wateringLogId: (json['watering_log_id'] as num?)?.toInt(),
    rainConfirmed: json['rain_confirmed'] as String?,
    moistureFeedback: json['user_moisture_feedback'] as String?,
  );

  bool get awaitsRainConfirmation =>
      wateringStatus == 'skip_rain' && rainConfirmed == 'not_answered';

  bool get awaitsMoistureFeedback =>
      wateringStatus == 'partial_rain' &&
      wateringLogId != null &&
      (moistureFeedback == null || moistureFeedback == 'not_answered');

  bool get needsWater => wateringStatus == 'need_water';

  bool get waitsForRain =>
      wateringStatus == 'skip_rain' || wateringStatus == 'partial_rain';

  bool get watered => wateringStatus == 'watered';

  bool get fertilized => fertilizingStatus == 'fertilized';
}

class PlantSchedule {
  PlantSchedule._();

  static String isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static List<CareTask> tasksForToday(
    List<CareDay> days, {
    required DateTime today,
    bool dueFertilizer = false,
  }) {
    final key = isoDate(today);
    CareDay? entry;
    for (final candidate in days) {
      if (candidate.date == key) {
        entry = candidate;
        break;
      }
    }

    final tasks = <CareTask>[];

    final watering = entry == null ? null : _wateringTask(entry);
    if (watering != null) tasks.add(watering);

    if (entry != null && entry.fertilized) {
      tasks.add(
        CareTask(
          title: CareTaskKind.fertilizing.actionLabel,
          description: 'Sudah dipupuk hari ini.',
          date: 'Hari ini',
          done: true,
          kind: CareTaskKind.fertilizing,
        ),
      );
    } else if (dueFertilizer) {
      tasks.add(
        const CareTask(
          title: 'Pupuk Tanaman',
          description: 'Jadwal pemupukan hari ini.',
          date: 'Hari ini',
          done: false,
          kind: CareTaskKind.fertilizing,
        ),
      );
    }

    return tasks;
  }

  static CareTask? _wateringTask(CareDay entry) {
    if (entry.needsWater) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description: 'Tanah sudah waktunya disiram hari ini.',
        date: 'Hari ini',
        done: false,
        kind: CareTaskKind.watering,
      );
    }
    if (entry.waitsForRain) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description:
            'Hujan diperkirakan turun; cek kondisi tanah lalu '
            'tandai bila tidak perlu disiram.',
        date: 'Hari ini',
        done: false,
        kind: CareTaskKind.watering,
      );
    }
    if (entry.watered) {
      return CareTask(
        title: CareTaskKind.watering.actionLabel,
        description: 'Sudah disiram hari ini.',
        date: 'Hari ini',
        done: true,
        kind: CareTaskKind.watering,
      );
    }
    return null;
  }
}
