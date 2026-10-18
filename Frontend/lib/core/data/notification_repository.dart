import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();

  Future<void> markAsRead(int id);

  Future<void> markAllRead();
}

class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final body = await _api.get('notifications');
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) AppNotification.fromJson(item),
    ];
  }

  @override
  Future<void> markAsRead(int id) =>
      _api.patch('notifications/$id/read', body: const {});

  @override
  Future<void> markAllRead() =>
      _api.patch('notifications/read-all', body: const {});
}

class SampleNotificationRepository implements NotificationRepository {
  SampleNotificationRepository();

  final List<AppNotification> _items = [
    AppNotification(
      id: 1,
      type: 'watering',
      message: 'Kangkung perlu disiram hari ini.',
      isRead: false,
      relatedPlantIds: const [4],
    ),
    AppNotification(
      id: 2,
      type: 'phase_change',
      message: 'Bayam memasuki fase vegetatif awal.',
      isRead: false,
      relatedPlantIds: const [5],
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async => List.of(_items);

  @override
  Future<void> markAsRead(int id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _items[index] = AppNotification(
        id: _items[index].id,
        type: _items[index].type,
        message: _items[index].message,
        isRead: true,
        relatedPlantIds: _items[index].relatedPlantIds,
      );
    }
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      final n = _items[i];
      _items[i] = AppNotification(
        id: n.id,
        type: n.type,
        message: n.message,
        isRead: true,
        relatedPlantIds: n.relatedPlantIds,
      );
    }
  }
}
