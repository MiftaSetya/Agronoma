import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'package:frontend/features/splash/splash_screen.dart';

/// Widget dummy sebagai tujuan splash, supaya test tidak perlu tahu layar asli.
class _DummyNextScreen extends StatelessWidget {
  const _DummyNextScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('NEXT'));
}

Widget _app(Widget child) => MaterialApp(home: child);

/// Waktu (ms) keyframe terakhir yang **masih mengubah nilai** di `splash.json`.
///
/// Semua track berhenti pada frame terakhir komposisi (5 detik) karena nilai
/// terakhir hanya ditahan, jadi "frame terakhir" saja tidak berguna untuk
/// keperluan timing. Yang dicari adalah keyframe terakhir yang nilainya berbeda
/// dari nilai akhir — di situlah gerakan sungguh-sungguh berhenti.
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

    // Sebelum durasi habis, layar tujuan belum boleh muncul.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('NEXT'), findsNothing);

    // Aset Lottie tidak bisa dimuat di `flutter test`, jadi yang menyelamatkan
    // di sini adalah jaring pengaman: duration + loadGrace (300 ms + 2 detik).
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

    // Lepas splash sebelum timernya menyala. `dispose` harus membatalkan timer,
    // jadi tidak boleh ada navigasi ke route yang sudah tiada — termasuk setelah
    // lewat jaring pengaman (duration + loadGrace).
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

    // Diurai dengan paket yang benar-benar dipakai di runtime, bukan dengan
    // pemeriksa JSON biasa — jadi kegagalan parsing ketahuan di sini, bukan di
    // layar pengguna.
    final bytes = file.readAsBytesSync();
    final composition = await LottieComposition.fromBytes(bytes);

    expect(composition.duration.inMilliseconds, 5000);
    expect(composition.frameRate, closeTo(60, 0.1));
    expect(composition.bounds.width, 440);
    expect(composition.bounds.height, 956);
  });

  test('durasi animasi cocok dengan jeda handoff splash', () async {
    // Kontrak yang mudah rusak tanpa ketahuan: kalau berkas Lottie diekspor
    // ulang dengan durasi lebih pendek, handoff bisa memotong gerakan terakhir.
    // Ambangnya dihitung dari berkas itu sendiri, bukan ditulis tangan, supaya
    // test ini tetap benar setelah ekspor ulang.
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
    // Kontrak kualitas: seluruh glyph harus berupa path vektor supaya tajam di
    // layar padat. Ekspor Figma sempat menanam huruf "g", "o", dan "a" sebagai
    // PNG 1x; ketiganya sudah dikonversi ke vektor. Test ini gagal kalau ada
    // ekspor ulang yang diam-diam mengembalikannya menjadi gambar.
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

    // Tidak boleh ada layer bergambar (ty=2) yang tersisa di mana pun.
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
    // Konversi image -> shape hanya boleh mengubah representasi, bukan timing.
    // Ketiga glyph itu ("a" ind 8, "o" ind 10, "g" ind 11) harus tetap punya
    // keyframe opacity dan posisi-x yang menggerakkannya masuk.
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
    // Rasio ini yang membuat logo duduk di posisi dan margin yang sama seperti
    // Figma tanpa perhitungan manual: layer "agronoma full" ada di (51, 309)
    // di dalam kanvas 440x956.
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
