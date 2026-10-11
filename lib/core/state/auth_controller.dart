import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/app_user.dart';

/// Status sesi pengguna.
enum AuthStatus { signedOut, signingIn, signedIn }

/// Menyimpan sesi login.
///
/// Autentikasi masih palsu: [signIn] selalu berhasil selama email dan kata
/// sandi tidak kosong, dan tidak ada token yang disimpan. Yang penting,
/// seluruh UI hanya bicara ke kelas ini — saat backend Agronoma siap, isi
/// [signIn] tinggal diarahkan ke endpoint sungguhan tanpa mengubah layar.
class AuthController extends ChangeNotifier {
  /// [initialUser] dipakai test untuk memulai dalam keadaan sudah masuk.
  /// Namanya dibedakan dari field `_user` agar tidak memicu
  /// `prefer_initializing_formals`.
  AuthController({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  AuthStatus _status = AuthStatus.signedOut;
  String? _error;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;

  /// Apakah pengguna sudah masuk.
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Pesan kesalahan terakhir, lalu dihapus supaya tidak menempel di layar.
  String? consumeError() {
    final e = _error;
    _error = null;
    return e;
  }

  /// Masuk. Mengembalikan `true` kalau berhasil.
  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.signingIn;
    _error = null;
    notifyListeners();

    // Tiruan panggilan jaringan.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (email.trim().isEmpty || password.isEmpty) {
      _error = 'Email dan kata sandi wajib diisi.';
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _error = 'Kata sandi minimal 8 karakter.';
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
    _error = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (name.trim().isEmpty || email.trim().isEmpty) {
      _error = 'Nama dan email wajib diisi.';
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      _error = 'Kata sandi minimal 8 karakter.';
      _status = AuthStatus.signedOut;
      notifyListeners();
      return false;
    }
    if (password != confirmation) {
      _error = 'Konfirmasi kata sandi tidak cocok.';
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
