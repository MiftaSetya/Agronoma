import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/data/device_token_store.dart';

class PushTokenService {
  PushTokenService({
    DeviceTokenStore? tokenStore,
    this.testPlatform,
    @visibleForTesting this.tokenProvider,
  }) : _store = tokenStore ?? DeviceTokenStore();

  final DeviceTokenStore _store;

  @visibleForTesting
  final TargetPlatform? testPlatform;

  @visibleForTesting
  final Future<String?> Function()? tokenProvider;

  static const String _keyPrefix = 'install-';

  bool _sent = false;

  bool get _isAndroid =>
      testPlatform != null
          ? testPlatform == TargetPlatform.android
          : defaultTargetPlatform == TargetPlatform.android;

  Future<void> registerToServer(Future<void> Function(String) send) async {
    if (_sent || !_isAndroid) return;
    _sent = true;

    try {
      final token = await _resolveToken();
      if (token == null || token.isEmpty) return;
      await send(token);
    } catch (_) {
      _sent = false;
    }
  }

  Future<String?> _resolveToken() async {
    final cached = await _store.read();
    if (cached != null && cached.isNotEmpty) return cached;

    String? token;
    try {
      token = await tokenProvider?.call();
    } catch (_) {
      token = null;
    }

    if (token == null || token.isEmpty) {
      try {
        final messaging = FirebaseMessaging.instance;
        token = await (messaging as dynamic).getToken() as String?;
      } catch (_) {
        token = null;
      }
    }

    if (token == null || token.isEmpty) {
      try {
        final info = DeviceInfoPlugin();
        final android = await info.androidInfo;
        final id = android.id;
        if (id.isNotEmpty) token = '$_keyPrefix$id';
      } catch (_) {
        token = null;
      }
    }

    if (token == null || token.isEmpty) {
      token = '$_keyPrefix${DateTime.now().microsecondsSinceEpoch}';
    }

    await _store.write(token);
    return token;
  }
}
