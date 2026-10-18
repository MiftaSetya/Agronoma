import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/state/push_token_service.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authSource,
    AppUser? initialUser,
    PushTokenService? pushTokens,
  }) : _repository = authSource,
       pushTokenService = pushTokens,
       _user = initialUser {
    if (initialUser != null) _status = AuthStatus.signedIn;
  }

  final AuthRepository _repository;
  final PushTokenService? pushTokenService;

  AppUser? _user;
  AuthStatus _status = AuthStatus.signedOut;
  Map<String, String> _errors = const {};

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isSignedIn => _user != null;

  Map<String, String> consumeErrors() {
    final e = _errors;
    _errors = const {};
    return e;
  }

  Future<void> restoreSession() async {
    if (_user != null || !await _repository.hasSession()) return;
    AppUser? restored;
    try {
      restored = await _repository.currentUser();
    } on ApiException {
      restored = null;
    }
    if (restored != null) {
      _user = restored;
      _status = AuthStatus.signedIn;
      notifyListeners();
      _registerPushToken();
    }
  }

  void _registerPushToken() {
    pushTokenService?.registerToServer(_repository.registerDeviceToken);
  }

  Future<void> refreshStats() async {
    final current = _user;
    if (current == null) return;
    final updated = await _repository.refreshStats(current);
    _user = updated;
    notifyListeners();
  }

  bool _savingReminder = false;
  bool get isSavingReminder => _savingReminder;

  bool _uploadingPhoto = false;
  bool get isUploadingPhoto => _uploadingPhoto;

  Future<bool> setWateringReminder(bool enabled) async {
    final current = _user;
    if (current == null || _savingReminder) return false;

    _savingReminder = true;
    notifyListeners();

    try {
      _user = await _repository.saveWateringReminder(current, enabled);
      return true;
    } on ApiException {
      return false;
    } finally {
      _savingReminder = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto(String imagePath) async {
    final current = _user;
    if (current == null || _uploadingPhoto) return false;

    _uploadingPhoto = true;
    notifyListeners();

    try {
      _user = await _repository.uploadPhoto(current, imagePath);
      return true;
    } on ApiException {
      return false;
    } finally {
      _uploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.signingIn;
    _errors = const {};
    notifyListeners();

    final localErrors = <String, String>{};
    if (email.trim().isEmpty) localErrors['email'] = 'Email wajib diisi.';
    if (password.isEmpty) {
      localErrors['password'] = 'Kata sandi wajib diisi.';
    }
    if (localErrors.isNotEmpty) {
      _errors = localErrors;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }

    try {
      final result = await _repository.login(
        email: email.trim(),
        password: password,
      );
      return _applyResult(result);
    } on ApiException catch (e) {
      return _failWith(e);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    _status = AuthStatus.signingIn;
    _errors = const {};
    notifyListeners();

    final localErrors = <String, String>{};
    if (name.trim().isEmpty) localErrors['name'] = 'Nama wajib diisi.';
    if (email.trim().isEmpty) localErrors['email'] = 'Email wajib diisi.';
    if (password.isEmpty) {
      localErrors['password'] = 'Kata sandi wajib diisi.';
    } else if (password.length < 8) {
      localErrors['password'] = 'Kata sandi minimal 8 karakter.';
    }
    if (confirmation != password) {
      localErrors['confirmation'] = 'Konfirmasi kata sandi tidak cocok.';
    }
    if (localErrors.isNotEmpty) {
      _errors = localErrors;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }

    try {
      final result = await _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );
      return _applyResult(result);
    } on ApiException catch (e) {
      return _failWith(e);
    }
  }

  Future<void> signOut() async {
    await _repository.logout();
    _clearUser();
  }

  void clearLocalSession() => _clearUser();

  void _clearUser() {
    _user = null;
    _status = AuthStatus.signedOut;
    _errors = const {};
    notifyListeners();
  }

  bool _applyResult(AuthResult result) {
    final user = result.user;
    if (user != null) {
      _user = user;
      _status = AuthStatus.signedIn;
      notifyListeners();
      _registerPushToken();
      return true;
    }
    return _failWith(
      result.error ?? const ApiException(message: 'Terjadi kesalahan.'),
    );
  }

  static const Set<String> _fieldKeysOnScreen = {
    'name',
    'email',
    'password',
    'confirmation',
  };

  bool _failWith(ApiException error) {
    final errors = <String, String>{};
    final general = <String>[];

    error.fieldErrors.forEach((key, message) {
      if (_fieldKeysOnScreen.contains(key)) {
        errors[key] = message;
      } else {
        general.add(message);
      }
    });

    if (general.isNotEmpty) {
      errors['general'] = general.join(' ');
    } else if (errors.isEmpty) {
      errors['general'] = error.message;
    }

    _errors = errors;
    _status = AuthStatus.signedOut;
    notifyListeners();
    return false;
  }
}
