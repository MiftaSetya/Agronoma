import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/device_token_store.dart';
import 'package:frontend/core/state/push_token_service.dart';

class _MemoryDeviceTokenStore implements DeviceTokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  test('registerToServer mengirim token provider dan menyimpannya', () async {
    final store = _MemoryDeviceTokenStore();
    final service = PushTokenService(
      tokenStore: store,
      testPlatform: TargetPlatform.android,
      tokenProvider: () async => 'fcm-token-abc',
    );
    final sent = <String>[];

    await service.registerToServer((t) async => sent.add(t));

    expect(sent, ['fcm-token-abc']);
    expect(store.token, 'fcm-token-abc');
  });

  test('token provider null memakai fallback install yang stabil', () async {
    final store = _MemoryDeviceTokenStore();
    final service = PushTokenService(
      tokenStore: store,
      testPlatform: TargetPlatform.android,
      tokenProvider: () async => null,
    );
    final sent = <String>[];

    await service.registerToServer((t) async => sent.add(t));

    expect(sent, hasLength(1));
    expect(sent.single, startsWith('install-'));
    expect(store.token, sent.single);
  });

  test('hanya mendaftar sekali per sesi', () async {
    final store = _MemoryDeviceTokenStore();
    final service = PushTokenService(
      tokenStore: store,
      testPlatform: TargetPlatform.android,
      tokenProvider: () async => 'fcm-token-abc',
    );
    var calls = 0;

    await service.registerToServer((t) async => calls++);
    await service.registerToServer((t) async => calls++);

    expect(calls, 1);
  });

  test('platform selain Android tidak mendaftar', () async {
    final store = _MemoryDeviceTokenStore();
    final service = PushTokenService(
      tokenStore: store,
      testPlatform: TargetPlatform.iOS,
      tokenProvider: () async => 'fcm-token-abc',
    );
    var calls = 0;

    await service.registerToServer((t) async => calls++);

    expect(calls, 0);
    expect(store.token, isNull);
  });
}
