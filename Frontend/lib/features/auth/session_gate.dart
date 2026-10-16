import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/theme/theme.dart';

/// Gerbang sesi setelah splash: memulihkan token tersimpan, lalu mengarahkan
/// ke Beranda (bila token masih sah) atau Login.
///
/// Tanpa gerbang ini, token yang sudah tersimpan tidak pernah dipakai sehingga
/// pengguna harus masuk ulang setiap kali aplikasi dibuka.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();
    // Setelah frame pertama: `restoreSession` memanggil notifyListeners(),
    // yang tidak boleh berjalan di tengah build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthController>();
    await auth.restoreSession();
    if (!mounted) return;

    Navigator.of(context)
        .pushReplacementNamed(auth.isSignedIn ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    // Latar putih seperti splash supaya peralihan tidak berkedip; indikator
    // hanya tampil bila pemulihan sesi benar-benar memanggil jaringan.
    return const Scaffold(
      backgroundColor: AppColors.mainWhite,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
