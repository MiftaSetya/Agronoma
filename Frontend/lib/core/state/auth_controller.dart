import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/app_user.dart';

/// Status sesi pengguna.
enum AuthStatus { signedOut, signingIn, signedIn }

/// Menyimpan sesi login.
///
/// Autentikasi masih palsu: [signIn] selalu berhasil selama email dan kata
/// sandi tidak kosong, dan tidak ada token yang disimpan. Seluruh UI hanya
/// bicara ke kelas ini, jadi saat backend siap cukup isi [signIn] tanpa
/// mengubah layar.
class AuthController extends ChangeNotifier {
  /// [initialUser] dipakai test untuk memulai dalam keadaan sudah masuk;
  /// namanya dibedakan dari field `_user` agar tidak memicu
  /// `prefer_initializing_formals`.
  AuthController({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  AuthStatus _status = AuthStatus.signedOut;
  Map<String, String> _errors = const {};

  AppUser? get user => _user;
  AuthStatus get status => _status;

  /// Pesan kesalahan terakhir per field (`'email'`, `'password'`, dst.),
  /// lalu dihapus supaya tidak menempel di layar.
  Map<String, String> consumeErrors() {
    final e = _errors;
    _errors = const {};
    return e;
  }

  /// Masuk. Mengembalikan `true` kalau berhasil.
  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.signingIn;
    _errors = const {};
    notifyListeners();

    // Tiruan panggilan jaringan.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final errors = <String, String>{};
    if (email.trim().isEmpty) errors['email'] = 'Email wajib diisi.';
    if (password.isEmpty) {
      errors['password'] = 'Kata sandi wajib diisi.';
    } else if (password.length < 8) {
      errors['password'] = 'Kata sandi minimal 8 karakter.';
    }
    if (errors.isNotEmpty) {
      _errors = errors;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }

    _user = MockData.user;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  /// Mendaftar akun baru. Selalu berhasil selama validasi lolos.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    _status = AuthStatus.signingIn;
    _errors = const {};
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Nama wajib diisi.';
    if (email.trim().isEmpty) errors['email'] = 'Email wajib diisi.';
    if (password.isEmpty) {
      errors['password'] = 'Kata sandi wajib diisi.';
    } else if (password.length < 8) {
      errors['password'] = 'Kata sandi minimal 8 karakter.';
    }
    if (confirmation != password) {
      errors['confirmation'] = 'Konfirmasi kata sandi tidak cocok.';
    }
    if (errors.isNotEmpty) {
      _errors = errors;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }

    _user = MockData.user;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  /// Keluar dari sesi.
  void signOut() {
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
