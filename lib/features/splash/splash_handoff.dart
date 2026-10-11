import 'dart:async';

/// Penjadwal perpindahan dari splash ke layar berikutnya.
///
/// Sengaja dipisah dari widget, karena inti perbaikannya ada di sini: jadwal
/// handoff harus bisa **dipasang ulang** begitu animasi benar-benar mulai,
/// bukan sekali di `initState`. Kalau logikanya menempel di dalam widget, jalur
/// itu tidak akan pernah teruji — aset Lottie tidak bisa dimuat di
/// `flutter test`, jadi `onLoaded` tidak pernah menyala di sana.
class SplashHandoff {
  SplashHandoff(this.onHandoff);

  /// Toleransi di atas [SplashScreen.duration] untuk jaring pengaman `initState`.
  ///
  /// Dipakai sebelum animasi menyatakan dirinya siap: pada perangkat normal
  /// `onLoaded` datang jauh lebih dulu (puluhan milidetik), jadi batas ini tidak
  /// pernah tercapai. Kalau dekode benar-benar gagal atau tidak pernah selesai
  /// (misalnya di `flutter test`, tempat bundel aset tidak tersedia), splash tetap
  /// berpindah dan tidak menggantung selamanya.
  static const Duration loadGrace = Duration(seconds: 2);

  /// Dipanggil sekali saat jadwal yang aktif selesai.
  final void Function() onHandoff;

  Timer? _timer;

  /// Menjadwalkan [onHandoff] setelah [delay].
  ///
  /// Jadwal sebelumnya dibatalkan lebih dulu, sehingga pemanggilan berulang
  /// (jaring pengaman di `initState`, lalu penyelarasan di `onLoaded`) selalu
  /// menghasilkan satu handoff saja, dihitung dari pemanggilan terakhir.
  void arm(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, onHandoff);
  }

  /// Membatalkan jadwal yang aktif tanpa memicu [onHandoff].
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
