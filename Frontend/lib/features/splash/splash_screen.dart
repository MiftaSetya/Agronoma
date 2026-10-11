import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/splash/splash_handoff.dart';

/// Splash screen Agronoma.
///
/// Animasi diambil dari frame `Splash Screen` (node `1:2`) pada Figma
/// "Agronoma Design", diekspor dari **Figma Motion** ke Lottie
/// (`assets/lottie/splash.json`).
///
/// Isi berkas itu: kanvas 440x956, 60 fps, 300 frame (5 detik), berisi grup
/// "agronoma full" di posisi Figma `(51, 309)`. Di dalamnya ada 11 layer —
/// delapan glyph wordmark (A, g, r, o, n, o, m, a) ditambah cincin, tunas, dan
/// bayangan tanah — dengan 32 track animasi dan 874 keyframe.
///
/// Catatan kualitas: tiga glyph (huruf "g", "o", dan "a") diekspor plugin Figma
/// sebagai **gambar PNG 1x**, bukan path vektor, karena simpul aslinya berupa
/// boolean operation ("Subtract") yang tidak dijadikan path oleh eksportir.
/// Ukurannya 32x44, 32x32, dan 26x32 px, sedangkan di layar ketiganya digambar
/// sekitar 2,9x lebih besar (kepadatan Pixel 9 Pro), jadi ketiganya tampak
/// lebih lembut daripada lima glyph lain yang tetap vektor.
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
/// Angka persen di atas dibulatkan dari keyframe Figma. Pengukuran langsung atas
/// `splash.json` menunjukkan animasi **berhenti bergerak pada 3,967 detik
/// (79,3%)** — bukan 3,6 detik — dan angka itulah yang jadi dasar
/// [defaultHandoff].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next, this.duration = defaultHandoff});

  /// Berkas animasi splash. Folder `assets/lottie/` sudah dideklarasikan di
  /// `pubspec.yaml`, jadi berkas ini otomatis ikut ter-bundle.
  static const String assetPath = 'assets/lottie/splash.json';

  /// Jeda sebelum berpindah layar, dihitung **dari saat animasi mulai berjalan**
  /// (lihat `_onAnimationLoaded`), bukan dari saat widget dibangun.
  ///
  /// Diukur dari `splash.json`, bukan dari perkiraan: seluruh 32 track berhenti
  /// pada 3,967 detik (keyframe terakhir yang masih mengubah nilai ada di frame
  /// 238 dari 300). Sisa 1 detik terakhir hanya nilai yang ditahan, jadi memotong
  /// di 4,2 detik tidak menghilangkan satu gerakan pun dan masih menyisakan
  /// ±230 ms untuk "mendarat" sebelum transisi fade 250 ms —
  /// sedangkan 3,9 detik (nilai lama, dari perkiraan 3,6 detik) memotong glyph
  /// "a" sebelum selesai, dan 4,0 detik terlalu mepet.
  static const Duration defaultHandoff = Duration(milliseconds: 4200);

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
  late final SplashHandoff _handoff = SplashHandoff(_goToNext);

  @override
  void initState() {
    super.initState();
    _handoff.arm(widget.duration + SplashHandoff.loadGrace);
  }

  /// Dipanggil begitu komposisi Lottie selesai di-decode dan animasi mulai.
  ///
  /// Jadwal dihitung ulang dari sini karena [SplashScreen.duration] diukur dari
  /// **saat animasi benar-benar berjalan**, sedangkan dekode aset butuh waktu.
  /// Kalau jeda dihitung dari `initState` (perilaku lama), waktu dekode itu
  /// diam-diam memotong durasi animasi dan wordmark belum selesai saat handoff.
  /// Menambatkannya ke `onLoaded` membuat total waktu layar memanjang mengikuti
  /// lambatnya pemuatan, sehingga animasinya selalu utuh.
  void _onAnimationLoaded(LottieComposition composition) {
    _handoff.arm(widget.duration);
  }

  @override
  void dispose() {
    // Satu-satunya penjaga yang dibutuhkan: jadwal yang sudah dibatalkan tidak
    // akan pernah memanggil `_goToNext`, jadi tidak mungkin ada navigasi ganda
    // maupun navigasi setelah widget dilepas.
    _handoff.cancel();
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
