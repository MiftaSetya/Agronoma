import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/state/push_message_router.dart';

void main() {
  test('pesan foreground memicu refresh notifikasi', () async {
    var refreshed = 0;
    var opened = 0;
    final foreground = StreamController<dynamic>();
    final router = PushMessageRouter(
      onRefreshNotifications: () => refreshed++,
      onOpenNotifications: () => opened++,
      foregroundMessages: foreground.stream,
    );

    router.bind();
    foreground.add({'notification': {'title': 'Agronoma'}});

    await Future<void>.delayed(Duration.zero);

    expect(refreshed, 1);
    expect(opened, 0);

    router.dispose();
    await foreground.close();
  });

  test('pesan yang dibuka dari notifikasi membuka layar notifikasi', () async {
    var opened = 0;
    final openedStream = StreamController<dynamic>();
    final router = PushMessageRouter(
      onRefreshNotifications: () {},
      onOpenNotifications: () => opened++,
      openedMessages: openedStream.stream,
    );

    router.bind();
    openedStream.add({'data': {}});

    await Future<void>.delayed(Duration.zero);

    expect(opened, 1);

    router.dispose();
    await openedStream.close();
  });

  test('pesan awal saat cold start membuka layar notifikasi', () async {
    var opened = 0;
    final router = PushMessageRouter(
      onRefreshNotifications: () {},
      onOpenNotifications: () => opened++,
      initialMessage: () async => {'data': {}},
    );

    router.bind();

    await Future<void>.delayed(Duration.zero);

    expect(opened, 1);

    router.dispose();
  });

  test('pesan awal null tidak membuka layar notifikasi', () async {
    var opened = 0;
    final router = PushMessageRouter(
      onRefreshNotifications: () {},
      onOpenNotifications: () => opened++,
      initialMessage: () async => null,
    );

    router.bind();

    await Future<void>.delayed(Duration.zero);

    expect(opened, 0);

    router.dispose();
  });
}
