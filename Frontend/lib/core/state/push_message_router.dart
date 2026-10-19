import 'dart:async';

import 'package:flutter/foundation.dart';

class PushMessageRouter {
  PushMessageRouter({
    required this.onRefreshNotifications,
    required this.onOpenNotifications,
    this.initialMessage,
    this.foregroundMessages,
    this.openedMessages,
  });

  final VoidCallback onRefreshNotifications;
  final VoidCallback onOpenNotifications;

  final Future<dynamic>? Function()? initialMessage;
  final Stream<dynamic>? foregroundMessages;
  final Stream<dynamic>? openedMessages;

  StreamSubscription<dynamic>? _foregroundSub;
  StreamSubscription<dynamic>? _openedSub;
  bool _bound = false;

  void bind() {
    if (_bound) return;
    _bound = true;

    _foregroundSub = foregroundMessages?.listen((_) {
      onRefreshNotifications();
    });
    _openedSub = openedMessages?.listen((_) {
      onOpenNotifications();
    });

    unawaited(_consumeInitial());
  }

  Future<void> _consumeInitial() async {
    try {
      final initial = await initialMessage?.call();
      if (initial != null) onOpenNotifications();
    } catch (_) {
      onRefreshNotifications();
    }
  }

  void dispose() {
    unawaited(_foregroundSub?.cancel());
    unawaited(_openedSub?.cancel());
    _foregroundSub = null;
    _openedSub = null;
    _bound = false;
  }
}
