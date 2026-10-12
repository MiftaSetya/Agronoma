import 'dart:async';

/// Penjadwal handoff dari splash ke layar berikutnya, dipisah dari widget agar
/// bisa diuji: jadwal harus bisa **dipasang ulang** saat animasi benar-benar
/// mulai (`onLoaded`), dan aset Lottie tidak bisa dimuat di `flutter test`
/// sehingga jalur itu tak teruji kalau logikanya menempel di widget.
class SplashHandoff {
  SplashHandoff(this.onHandoff);

  /// Toleransi di atas [SplashScreen.duration] untuk jaring pengaman `initState`:
  /// pada perangkat normal `onLoaded` datang jauh lebih dulu, tapi bila dekode
  /// aset gagal atau tidak pernah selesai (mis. di `flutter test`), splash tetap
  /// berpindah dan tidak menggantung selamanya.
  static const Duration loadGrace = Duration(seconds: 2);

  /// Dipanggil sekali saat jadwal yang aktif selesai.
  final void Function() onHandoff;

  Timer? _timer;

  /// Menjadwalkan [onHandoff] setelah [delay], membatalkan jadwal sebelumnya —
  /// pemanggilan berulang (jaring pengaman `initState`, lalu `onLoaded`) selalu
  /// menghasilkan tepat satu handoff dari pemanggilan terakhir.
  void arm(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, onHandoff);
  }

  /// Membatalkan jadwal aktif tanpa memicu [onHandoff].
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
