import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/core/theme/theme.dart';

/// Splash screen Agronoma.
///
/// Animasi diambil dari frame `Splash Screen` (node `1:2`) pada Figma
/// "Agronoma Design". Frame itu dibuat dengan **Figma Motion**: timeline 5 detik
/// berisi 15 layer — delapan glyph wordmark (A, g, r, o, n, o, m, a) ditambah
/// cincin, tunas, dan bagian dalam huruf "o".
///
/// Di Figma timeline itu berulang tanpa henti (`animation-iteration-count:
/// infinite`), sedangkan splash di sini dimainkan **sekali** (`repeat: false`).
/// Urutan animasi aslinya, dipakai sebagai acuan bila suatu saat berkas Lottie
/// perlu diganti dengan reproduksi manual:
///
/// | Glyph | Aksi | Mulai | Selesai |
/// |---|---|---|---|
/// | A | slide `+125px` → 0 | 35,3% | 46,2% |
/// | cincin "o" | rotate `−90°` → 0, slide `+92px` → 0 | 44,4% | 74,5% |
/// | g | fade + slide `−120px` → 0 | 49,5% | 55,5% |
/// | r | idem | 53,5% | 59,5% |
/// | n | idem | 61,5% | 67,5% |
/// | o | idem | 65,5% | 71,5% |
/// | m | idem | 69,5% | 75,5% |
/// | a | idem | 73,5% | 79,5% |
///
/// Logo baru utuh pada ±72% (3,6 detik), karena itu jeda menuju layar
/// berikutnya dipasang di [defaultHandoff] (3,9 detik) supaya masih ada jeda
/// tenang sesaat sebelum berpindah.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next, this.duration = defaultHandoff});

  /// Berkas animasi splash. Folder `assets/lottie/` sudah dideklarasikan di
  /// `pubspec.yaml`, jadi berkas ini otomatis ikut ter-bundle.
  static const String assetPath = 'assets/lottie/splash.json';

  /// Jeda sebelum berpindah layar: logo sudah utuh di 3,6 detik, jadi 3,9 detik
  /// memberi jeda tenang sesaat tanpa animasi terpotong.
  static const Duration defaultHandoff = Duration(milliseconds: 3900);

  /// Layar tujuan setelah splash. Disuntikkan dari luar (composition root di
  /// `main.dart`) supaya fitur splash tidak perlu mengimpor fitur lain dan bisa
  /// diuji dengan widget dummy. Bila `null`, splash hanya diam di tempat.
  final Widget? next;

  /// Berapa lama splash ditampilkan sebelum berpindah ke [next].
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _goToNext);
  }

  @override
  void dispose() {
    // Timer dibatalkan di sini, dan itu satu-satunya penjaga yang dibutuhkan:
    // timer yang sudah dibatalkan tidak akan pernah memanggil `_goToNext`, jadi
    // tidak mungkin ada navigasi ganda maupun navigasi setelah widget dilepas.
    _timer?.cancel();
    super.dispose();
  }

  /// Berpindah ke [SplashScreen.next] dengan transisi fade.
  ///
  /// Syarat `mounted` tetap dipertahankan sebagai sabuk pengaman: kalau kelak
  /// [SplashScreen.duration] berubah di tengah jalan (mis. dari cek sesi login)
  /// dan `initState` diganti memakai `Future` alih-alih `Timer`, tidak ada lagi
  /// yang otomatis menjamin widget masih hidup saat callback menyala.
  void _goToNext() {
    final next = widget.next;
    if (!mounted || next == null) {
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Splash berlatar putih, jadi ikon status bar harus gelap.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.mainWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.mainWhite,
        body: Center(
          // Sengaja tanpa `SizedBox` maupun `fit`: `RenderLottie` memilih
          // ukurannya sendiri mengikuti rasio kanvas komposisi dan tidak pernah
          // memperbesar melebihi ukuran aslinya. Itu persis yang diinginkan —
          // kanvas Figma (440x956) diperkecil seperlunya, sehingga posisi logo
          // dan margin-nya tetap sama seperti design. Memaksa kotak persegi di
          // sini justru akan mengecilkan logo menjadi ±setengahnya.
          child: Semantics(
            label: 'Agronoma',
            image: true,
            child: Lottie.asset(
              SplashScreen.assetPath,
              repeat: false,
              errorBuilder: (context, error, stackTrace) =>
                  const _SplashLogoFallback(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan cadangan bila berkas Lottie gagal dimuat.
///
/// Hanya jaring pengaman supaya splash tidak pernah menjadi layar putih kosong
/// tanpa penjelasan; ini bukan pengganti animasi dan tidak seharusnya muncul di
/// build produksi.
class _SplashLogoFallback extends StatelessWidget {
  const _SplashLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Agronoma',
      style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primaryDark),
    );
  }
}
