import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/notification_repository.dart';
import 'package:frontend/core/models/app_notification.dart';
import 'package:frontend/core/state/notification_controller.dart';

void main() {
  test('load mengambil notifikasi dari sumber', () async {
    final controller = NotificationController(SampleNotificationRepository());

    await controller.load();

    expect(controller.items, hasLength(2));
    expect(controller.unreadCount, 2);
    expect(controller.error, isNull);
  });

  test('markAsRead menandai satu notifikasi menjadi terbaca', () async {
    final controller = NotificationController(SampleNotificationRepository());
    await controller.load();

    final ok = await controller.markAsRead(1);

    expect(ok, isTrue);
    expect(controller.unreadCount, 1);
    expect(controller.items.firstWhere((n) => n.id == 1).isRead, isTrue);
    expect(controller.items.firstWhere((n) => n.id == 2).isRead, isFalse);
  });

  test('markAllRead menandai semua notifikasi menjadi terbaca', () async {
    final controller = NotificationController(SampleNotificationRepository());
    await controller.load();

    final ok = await controller.markAllRead();

    expect(ok, isTrue);
    expect(controller.unreadCount, 0);
    expect(controller.items.every((n) => n.isRead), isTrue);
  });

  test('reset mengosongkan daftar notifikasi', () async {
    final controller = NotificationController(SampleNotificationRepository());
    await controller.load();

    controller.reset();

    expect(controller.items, isEmpty);
    expect(controller.unreadCount, 0);
  });

  test('AppNotification.fromJson membaca payload API', () {
    final notification = AppNotification.fromJson({
      'id': 9,
      'type': 'phase_change',
      'message': 'Kangkung memasuki fase vegetatif awal.',
      'is_read': true,
      'related_plant_ids': [4, 5],
    });

    expect(notification.id, 9);
    expect(notification.isPhaseChange, isTrue);
    expect(notification.type, 'phase_change');
    expect(notification.isRead, isTrue);
    expect(notification.relatedPlantIds, [4, 5]);
  });
}
