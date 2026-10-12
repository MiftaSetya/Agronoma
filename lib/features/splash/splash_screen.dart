import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/splash/splash_handoff.dart';

/// Splash screen Agronoma: animasi Lottie dari frame `Splash Screen`
/// (node `1:2`) Figma "Agronoma Design", diekspor dari Figma Motion ke
/// `assets/lottie/splash.json` (diulang di Figma, di sini dimainkan sekali).
///
/// Tiga glyph wordmark awalnya diekspor plugin Figma sebagai PNG 1x (simpul
/// boolean "Subtract"); ketiganya sudah diganti path vektor dari SVG sumber
/// `assets/icons/` dengan `ks` dan fill identik, sehingga semua glyph tajam di
/// layar padat. Test "Lottie tidak memakai aset raster" di `test/splash_test.dart`
/// menjaga agar tidak ada glyph yang diam-diam kembali menjadi gambar.
///
/// Dari pengukuran langsung `splash.json`, seluruh track berhenti bergerak pada
/// 3,967 detik (79,3%) — bukan 3,6 detik — dan angka itulah dasar
/// [defaultHandoff]. Urutan animasi asli Figma dipakai sebagai acuan bila berkas
/// Lottie suatu saat diganti reproduksi manual:
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
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next, this.duration = defaultHandoff});

  static const String assetPath = 'assets/lottie/splash.json';

  /// Jeda sebelum berpindah layar, dihitung dari saat animasi mulai berjalan
  /// (lihat `_onAnimationLoaded`), bukan dari saat widget dibangun.
  ///
  /// 4200 ms diukur dari `splash.json` (track terakhir berhenti di 3,967 s;
  /// keyframe aktif terakhir di frame 238/300), bukan perkiraan: 3,9 s memotong
  /// glyph "a" sebelum selesai, 4,0 s terlalu mepet, sedangkan 4,2 s tetap
  /// menyisakan ±230 ms "mendarat" sebelum transisi fade 250 ms.
  static const Duration defaultHandoff = Duration(milliseconds: 4200);

  /// Layar tujuan setelah splash. Disuntikkan dari composition root (`main.dart`)
  /// agar fitur splash tidak mengimpor fitur lain dan bisa diuji dengan widget
  /// dummy; bila `null`, splash diam di tempat.
  final Widget? next;

  /// Berapa lama splash ditampilkan sebelum berpindah ke [next].
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashHandoff _handoff = SplashHandoff(_goToNext);

  @override
  void initState() {
    super.initState();
    _handoff.arm(widget.duration + SplashHandoff.loadGrace);
  }

  /// Dipanggil saat Lottie selesai di-decode dan animasi mulai; jadwal
  /// ditambatkan di sini (bukan `initState`) karena `duration` diukur dari saat
  /// animasi benar-benar berjalan — waktu dekode aset tidak boleh memotong
  /// durasinya, sehingga animasi selalu utuh sampai handoff.
  void _onAnimationLoaded(LottieComposition composition) {
    _handoff.arm(widget.duration);
  }

  @override
  void dispose() {
    _handoff.cancel();
    super.dispose();
  }

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
          // Tanpa `SizedBox`/`fit`: `RenderLottie` memakai ukuran kanvas
          // komposisi (440x956, hanya diperkecil) sehingga posisi logo tetap
          // sesuai design; memaksa kotak persegi justru mengecilkan logo
          // ±setengahnya.
          child: Semantics(
            label: 'Agronoma',
            image: true,
            child: Lottie.asset(
              SplashScreen.assetPath,
              repeat: false,
              onLoaded: _onAnimationLoaded,
              errorBuilder: (context, error, stackTrace) =>
                  const _SplashLogoFallback(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback statis bila Lottie gagal dimuat — jaring pengaman agar splash tidak
/// jadi layar putih kosong; bukan pengganti animasi.
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
