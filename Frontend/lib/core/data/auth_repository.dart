import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/models/app_user.dart';

class AuthResult {
  const AuthResult.success(this.user) : error = null;

  const AuthResult.failure(this.error) : user = null;

  final AppUser? user;
  final ApiException? error;

  bool get isSuccess => user != null;
}

abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<AppUser?> currentUser();

  Future<AppUser> refreshStats(AppUser user);

  Future<bool> hasSession();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required ApiClient apiClient,
    required TokenStore tokenStore,
  }) : _client = apiClient,
       _tokens = tokenStore;

  final ApiClient _client;
  final TokenStore _tokens;

  @override
  Future<bool> hasSession() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _authenticate('login', {'email': email, 'password': password});
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _authenticate('register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('logout');
    } on ApiException catch (_) {
      await _tokens.clear();
      return;
    }
    await _tokens.clear();
  }

  @override
  Future<AppUser?> currentUser() async {
    if (!await hasSession()) return null;
    try {
      final body = await _client.get('user');
      return _userFrom(body);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> refreshStats(AppUser user) async {
    try {
      final body = await _client.get('profile');
      if (body is! Map<String, dynamic>) return user;
      return user.copyWith(
        totalPlants: (body['total_plants'] as num?)?.toInt(),
        harvestedThisSeason: (body['harvested_count'] as num?)?.toInt(),
        careScore: (body['care_score_percent'] as num?)?.toDouble(),
      );
    } on ApiException {
      return user;
    }
  }

  Future<AuthResult> _authenticate(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final body = await _client.post(path, body: payload);
      final map = body is Map<String, dynamic>
          ? body
          : const <String, dynamic>{};
      final token = map['token'] as String?;
      if (token == null || token.isEmpty) {
        return const AuthResult.failure(
          ApiException(message: 'Server tidak mengirim token akses.'),
        );
      }
      await _tokens.write(token);
      final user = _userFrom(body);
      if (user == null) {
        return const AuthResult.failure(
          ApiException(message: 'Server tidak mengirim data pengguna.'),
        );
      }
      return AuthResult.success(user);
    } on ApiException catch (e) {
      return AuthResult.failure(e);
    }
  }

  AppUser? _userFrom(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final raw = body['user'];
    if (raw is! Map<String, dynamic>) return null;
    return _mapUser(raw);
  }

  AppUser _mapUser(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String?;
    return AppUser(
      id: '${json['id']}',
      name: (json['name'] as String?) ?? 'Pengguna',
      email: (json['email'] as String?) ?? '',

      photoAsset: AppAssets.photoProfile,

      totalPlants: 0,
      harvestedThisSeason: 0,
      careScore: 0,
      joinedAt: createdAt == null ? null : DateTime.tryParse(createdAt),
    );
  }
}

class SampleAuthRepository implements AuthRepository {
  SampleAuthRepository({AppUser? user}) : _user = user ?? _sampleUser;

  static const AppUser _sampleUser = AppUser(
    id: '1',
    name: 'Budi Santoso',
    email: 'budi@agronoma.test',
    photoAsset: AppAssets.photoProfile,
    totalPlants: 5,
    harvestedThisSeason: 2,
    careScore: 92,
  );

  final AppUser _user;

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => AuthResult.success(_user);

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async => AuthResult.failure(
    const ApiException(
      message: 'Mode contoh hanya mendukung masuk.',
      statusCode: 501,
    ),
  );

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> refreshStats(AppUser user) async => user;
}
