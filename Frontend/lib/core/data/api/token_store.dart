import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan token akses.
///
/// Dibuat sebagai antarmuka supaya lapisan API tidak bergantung langsung pada
/// plugin platform: widget test dan uji integrasi bisa memakai penyimpanan
/// dalam memori.
abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// Penyimpanan aman asli: Keychain (iOS) / EncryptedSharedPreferences
/// (Android). Token tidak pernah ditulis ke berkas biasa.
class SecureTokenStore implements TokenStore {
  // Bawaan v11 sudah memakai AES-GCM dengan pembungkusan kunci RSA di
  // Android KeyStore; tidak perlu opsi khusus.
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _key = 'agronoma.access_token';

  const SecureTokenStore();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Penyimpanan dalam memori — dipakai test dan mode pratinjau agar tidak
/// menyentuh Keychain/Keystore.
class InMemoryTokenStore implements TokenStore {
  String? _token;

  InMemoryTokenStore([this._token]);

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
