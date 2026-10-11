import 'package:flutter/material.dart';

import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/splash/splash_screen.dart';
import 'package:frontend/features/theme_preview/theme_preview_screen.dart';

void main() => runApp(const AgronomaApp());

/// Aplikasi Agronoma.
///
/// Entry point sengaja tipis: berkas ini hanya menyusun tema dan layar pertama.
/// Splash menjadi layar pembuka, dan tujuannya diisi dari sini (composition
/// root) supaya fitur splash tidak mengimpor fitur lain.
///
/// TODO(Fase 2): ganti `home` dengan router, dan arahkan splash ke
/// `SplashGate` yang memeriksa sesi login sebelum memilih layar berikutnya.
/// Selama alur produk belum ada, tujuan splash masih `ThemePreviewScreen`.
class AgronomaApp extends StatelessWidget {
  const AgronomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agronoma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(next: ThemePreviewScreen()),
    );
  }
}
