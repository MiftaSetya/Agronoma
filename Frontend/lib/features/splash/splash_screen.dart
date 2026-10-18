import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/splash/splash_handoff.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next, this.duration = defaultHandoff});

  static const String assetPath = 'assets/lottie/splash.json';

  static const Duration defaultHandoff = Duration(milliseconds: 4200);

  final Widget? next;

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
