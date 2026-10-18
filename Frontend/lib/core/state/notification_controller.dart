import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:frontend/core/data/notification_repository.dart';
import 'package:frontend/core/models/app_notification.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._source);

  final NotificationRepository _source;

  static const Duration _interval = Duration(seconds: 45);

  List<AppNotification> _items = const [];
  bool _loading = false;
  bool _acting = false;
  bool _polling = false;
  Object? _error;

  AppLifecycleListener? _listener;
  bool _resumed = true;
  bool _enabled = false;
  Timer? _timer;

  void startPolling() {
    if (_enabled) return;
    _enabled = true;
    _listener ??= AppLifecycleListener(
      onResume: () => _resumed = true,
      onShow: () => _resumed = true,
      onInactive: () => _resumed = false,
      onPause: () => _resumed = false,
      onDetach: () => _resumed = false,
    );
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  void stopPolling() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (!_enabled || !_resumed || _loading || _acting || _polling) return;
    _polling = true;
    try {
      final items = await _source.getNotifications();
      if (!_enabled) return;
      _items = items;
      _error = null;
      notifyListeners();
    } catch (_) {
      if (!_enabled) return;
    } finally {
      _polling = false;
    }
  }

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isActing => _acting;
  Object? get error => _error;

  int get unreadCount =>
      _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _source.getNotifications();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(int id) async {
    if (_acting) return false;
    _acting = true;
    notifyListeners();
    try {
      await _source.markAsRead(id);
      _items = [
        for (final n in _items)
          if (n.id == id)
            AppNotification(
              id: n.id,
              type: n.type,
              message: n.message,
              isRead: true,
              relatedPlantIds: n.relatedPlantIds,
            )
          else
            n,
      ];
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _acting = false;
      notifyListeners();
    }
  }

  Future<bool> markAllRead() async {
    if (_acting) return false;
    _acting = true;
    notifyListeners();
    try {
      await _source.markAllRead();
      _items = [
        for (final n in _items)
          AppNotification(
            id: n.id,
            type: n.type,
            message: n.message,
            isRead: true,
            relatedPlantIds: n.relatedPlantIds,
          ),
      ];
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _acting = false;
      notifyListeners();
    }
  }

  void reset() {
    _items = const [];
    _loading = false;
    _acting = false;
    _polling = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    _listener?.dispose();
    _listener = null;
    super.dispose();
  }
}
