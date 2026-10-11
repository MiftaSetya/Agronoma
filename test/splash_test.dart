import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/splash/splash_screen.dart';

/// Widget dummy sebagai tujuan splash, supaya test tidak perlu tahu layar asli.
class _DummyNextScreen extends StatelessWidget {
  const _DummyNextScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('NEXT'));
}

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('splash merender tanpa error', (tester) async {
    await tester.pumpWidget(_app(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash berpindah ke layar berikutnya setelah durasi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SplashScreen(
          next: _DummyNextScreen(),
          duration: Duration(milliseconds: 300),
        ),
      ),
    );

    // Sebelum durasi habis, layar tujuan belum boleh muncul.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('NEXT'), findsNothing);

    // Lewati durasi, lalu selesaikan transisi fade (250 ms).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('NEXT'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash tidak berpindah bila widget sudah dilepas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SplashScreen(
          next: _DummyNextScreen(),
          duration: Duration(milliseconds: 300),
        ),
      ),
    );

    // Lepas splash sebelum timernya menyala. Timer harus dibatalkan di
    // `dispose`, jadi tidak boleh ada navigasi ke route yang sudah tiada.
    await tester.pumpWidget(_app(const Scaffold(body: Text('OTHER'))));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('OTHER'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash menampilkan fallback saat berkas Lottie tidak ada', (
    tester,
  ) async {
    // Selama `assets/lottie/splash.json` belum ada (menunggu ekspor dari Figma),
    // splash tidak boleh menjadi layar putih bisu: errorBuilder harus
    // menampilkan teks pengganti.
    expect(
      File(SplashScreen.assetPath).existsSync(),
      isFalse,
      reason:
          'Test ini mengandaikan berkas Lottie belum ada. Bila berkasnya sudah '
          'ditambahkan, hapus test ini karena fallback tidak lagi relevan.',
    );

    await tester.pumpWidget(_app(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Agronoma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('folder assets/lottie dideklarasikan di pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec.contains('assets/lottie/'),
      isTrue,
      reason:
          'assets/lottie/ harus terdaftar di pubspec.yaml agar '
          '${SplashScreen.assetPath} ikut ter-bundle.',
    );
  });

  test('jeda handoff memberi waktu logo tampil utuh', () {
    // Logo baru utuh pada ±72% dari timeline 5 detik, yaitu ±3,6 detik
    // (lihat dokumentasi di splash_screen.dart), jadi jeda tidak boleh lebih
    // pendek dari itu agar animasi tidak terpotong.
    expect(
      SplashScreen.defaultHandoff.inMilliseconds,
      greaterThanOrEqualTo(3600),
    );
  });
}
