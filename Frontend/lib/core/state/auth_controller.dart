import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/models/app_user.dart';

/// Status sesi pengguna.
enum AuthStatus { signedOut, signingIn, signedIn }

/// Menyimpan sesi login.
///
/// Seluruh UI hanya berbicara ke kelas ini; asal datanya (backend atau mode
/// contoh) ditentukan oleh [AuthRepository] yang disuntikkan dari `app.dart`.
class AuthController extends ChangeNotifier {
  /// [authSource] dan [initialUser] sengaja berbeda nama dari field-nya karena
  /// Dart tidak mengizinkan *named initializing formal* untuk field privat
  /// (`prefer_initializing_formals`). [initialUser] dipakai test untuk memulai
  /// dalam keadaan sudah masuk.
  AuthController({required AuthRepository authSource, AppUser? initialUser})
    : _repository = authSource,
      _user = initialUser {
    if (initialUser != null) _status = AuthStatus.signedIn;
  }

  final AuthRepository _repository;

  AppUser? _user;
  AuthStatus _status = AuthStatus.signedOut;
  Map<String, String> _errors = const {};

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isSignedIn => _user != null;

  /// Pesan kesalahan terakhir per field (`'email'`, `'password'`, dst.),
  /// lalu dihapus supaya tidak menempel di layar.
  Map<String, String> consumeErrors() {
    final e = _errors;
    _errors = const {};
    return e;
  }

  /// Memulihkan sesi dari token tersimpan saat aplikasi dibuka.
  ///
  /// Dipanggil sekali dari splash; kegagalan jaringan tidak mengeluarkan
  /// pengguna yang sudah punya token — token hanya dibuang bila server
  /// menolaknya dengan 401.
  Future<void> restoreSession() async {
    if (_user != null || !await _repository.hasSession()) return;
    try {
      final restored = await _repository.currentUser();
      if (restored != null) {
        _user = restored;
        _status = AuthStatus.signedIn;
        notifyListeners();
      }
    } on ApiException {
      // Biarkan status tetap signedOut; pengguna bisa mencoba lagi.
    }
  }

  /// Masuk. Mengembalikan `true` kalau berhasil.
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

  /// Mendaftar akun baru. Mengembalikan `true` kalau berhasil.
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

  /// Keluar dari sesi.
  Future<void> signOut() async {
    await _repository.logout();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  bool _applyResult(AuthResult result) {
    final user = result.user;
    if (user != null) {
      _user = user;
      _status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    }
    return _failWith(
      result.error ?? const ApiException(message: 'Terjadi kesalahan.'),
    );
  }

  /// Nama field yang benar-benar ada di layar Login/Register. Kunci lain dari
  /// backend — mis. `credentials` saat kredensial salah — tidak punya kolom,
  /// jadi dialihkan ke banner umum supaya tetap terlihat pengguna.
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
