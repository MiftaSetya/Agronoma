import 'dart:async';

class SplashHandoff {
  SplashHandoff(this.onHandoff);

  static const Duration loadGrace = Duration(seconds: 2);

  final void Function() onHandoff;

  Timer? _timer;

  void arm(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, onHandoff);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
