import 'package:flutter/foundation.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.relatedPlantIds = const [],
  });

  final int id;
  final String type;
  final String message;
  final bool isRead;
  final List<int> relatedPlantIds;

  bool get isWatering => type == 'watering';
  bool get isPhaseChange => type == 'phase_change';

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        message: json['message'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        relatedPlantIds: [
          for (final raw in (json['related_plant_ids'] as List? ?? const []))
            if (raw is num) raw.toInt(),
        ],
      );
}
