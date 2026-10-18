import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceTokenStore {
  DeviceTokenStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _key = 'agronoma.push_token';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
