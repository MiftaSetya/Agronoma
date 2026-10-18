import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/features/splash/splash_screen.dart';

class _DummyNextScreen extends StatelessWidget {
  const _DummyNextScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('NEXT'));
}

Widget _app(Widget child) => MaterialApp(home: child);

Future<int> _lastMovementMs() async {
  final json = jsonDecode(
    File(SplashScreen.assetPath).readAsStringSync(),
  ) as Map<String, dynamic>;
  final fr = (json['fr'] as num).toDouble();
  var latest = 0;

  void walk(Object? node) {
    if (node is List) return node.forEach(walk);
    if (node is! Map) return;
    if (node['a'] == 1 && node['k'] is List) {
      final list = (node['k'] as List).cast<Map>();
      if (list.isNotEmpty) {
        final end = jsonEncode(list.last['s'] ?? list.last['e'] ?? list.last);
        for (final kf in list) {
          if (jsonEncode(kf['s'] ?? kf['e'] ?? kf) != end) {
            latest = (kf['t'] as num).toInt().clamp(latest, 1 << 30);
          }
        }
      }
    }
    node.values.forEach(walk);
  }

  walk(json);
  return (latest / fr * 1000).round();
}

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

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('NEXT'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2400));
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

    await tester.pumpWidget(_app(const Scaffold(body: Text('OTHER'))));
    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.text('OTHER'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('berkas Lottie ada dan bisa diurai oleh lottie 3.6.1', () async {
    final file = File(SplashScreen.assetPath);
    expect(
      file.existsSync(),
      isTrue,
      reason:
          '${SplashScreen.assetPath} hilang. Splash akan memakai tampilan '
          'cadangan (teks "Agronoma"), bukan animasi logo.',
    );

    final bytes = file.readAsBytesSync();
    final composition = await LottieComposition.fromBytes(bytes);

    expect(composition.duration.inMilliseconds, 5000);
    expect(composition.frameRate, closeTo(60, 0.1));
    expect(composition.bounds.width, 440);
    expect(composition.bounds.height, 956);
  });

  test('durasi animasi cocok dengan jeda handoff splash', () async {
    final lastMovement = await _lastMovementMs();
    expect(
      lastMovement,
      greaterThan(0),
      reason: 'Tidak ada track yang beranimasi — berkasnya statis.',
    );
    expect(
      SplashScreen.defaultHandoff.inMilliseconds,
      greaterThan(lastMovement + 100),
      reason:
          'Animasi masih bergerak sampai $lastMovement ms; handoff harus '
          'menyisakan jeda untuk "mendarat".',
    );
    expect(
      SplashScreen.defaultHandoff.inMilliseconds,
      lessThanOrEqualTo(5000),
      reason: 'Handoff melewati akhir komposisi (5 detik).',
    );
  });

  test('komposisi Lottie benar-benar beranimasi, bukan gambar diam', () async {
    final json = jsonDecode(
      File(SplashScreen.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    var tracks = 0;
    var keyframes = 0;
    void walk(Object? node) {
      if (node is List) return node.forEach(walk);
      if (node is! Map) return;
      if (node['a'] == 1 && node['k'] is List) {
        tracks++;
        keyframes += (node['k'] as List).length;
      }
      node.values.forEach(walk);
    }

    walk(json);
    expect(tracks, greaterThanOrEqualTo(20));
    expect(keyframes, greaterThanOrEqualTo(500));
  });

  test('Lottie tidak memakai aset raster (semua glyph vektor)', () async {
    final json = jsonDecode(
      File(SplashScreen.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final rasters = (json['assets'] as List)
        .whereType<Map>()
        .where(
          (a) => a['p'] is String && (a['p'] as String).startsWith('data:'),
        )
        .toList();
    expect(
      rasters,
      isEmpty,
      reason:
          'Ada ${rasters.length} aset raster. Glyph akan tampak buram di '
          'layar padat; konversi ulang ke path vektor.',
    );

    var imageLayers = 0;
    void walk(Object? node) {
      if (node is List) return node.forEach(walk);
      if (node is! Map) return;
      if (node['ty'] == 2) imageLayers++;
      node.values.forEach(walk);
    }

    walk(json);
    expect(imageLayers, 0);
  });

  test('glyph hasil konversi tetap punya animasi aslinya', () async {
    final json = jsonDecode(
      File(SplashScreen.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final precomp =
        (json['assets'] as List).whereType<Map>().firstWhere(
              (a) => a['id'] == 'asset_5',
            )['layers']
            as List;

    for (final ind in [8, 10, 11]) {
      final layer = precomp.whereType<Map>().firstWhere((l) => l['ind'] == ind);
      expect(layer['ty'], 4, reason: 'Layer $ind harus berupa shape.');
      final ks = layer['ks'] as Map;
      final px = (ks['p'] as Map)['x'] as Map;
      expect(px['a'], 1, reason: 'Layer $ind kehilangan animasi posisi-x.');
      final opacity = ks['o'] as Map;
      expect(opacity['a'], 1, reason: 'Layer $ind kehilangan animasi opacity.');
      expect(layer['shapes'], isNotEmpty);
    }
  });

  test('kanvas Lottie memakai rasio design 440x956', () async {
    final bytes = File(SplashScreen.assetPath).readAsBytesSync();
    final composition = await LottieComposition.fromBytes(bytes);
    expect(
      composition.bounds.width / composition.bounds.height,
      closeTo(440 / 956, 0.001),
    );
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
}
