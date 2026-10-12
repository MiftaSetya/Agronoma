import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membuat ikon launcher Agronoma dari logo SVG.
///
/// Dipakai sekali: `flutter test test/make_launcher_icon.dart` lalu salin
/// hasilnya ke `android/app/src/main/res/mipmap-*/ic_launcher.png` pada
/// ukuran yang sesuai. Pembaruan ikon berikutnya tinggal menjalankan ulang
/// perintah yang sama — tidak butuh alat eksternal.
///
/// Latar putih polos: ikon adaptif Android memotong lingkaran di tengah,
/// jadi logo diberi margin supaya tidak tersentuh potongan.
void main() {
  test('membuat ikon launcher', () async {
    const size = 1024;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final sizeD = size.toDouble();
    _LogoPainter().paint(canvas, ui.Size(sizeD, sizeD));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build').createSync(recursive: true);
    File('build/launcher_icon.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    expect(File('build/launcher_icon.png').lengthSync(), greaterThan(1000));
  });
}

/// Menggambar logo Agronoma (SVG asli 48x60) di tengah kanvas persegi.
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    const marginRatio = 0.22;
    final margin = size.width * marginRatio;
    final dst = Offset(margin, margin) &
        ui.Size(size.width - margin * 2, size.height - margin * 2);

    // Rasio asli logo 48:60.
    const srcRatio = 48 / 60;
    var w = dst.width;
    var h = w / srcRatio;
    if (h > dst.height) {
      h = dst.height;
      w = h * srcRatio;
    }
    canvas.save();
    canvas.translate(
      dst.left + (dst.width - w) / 2,
      dst.top + (dst.height - h) / 2,
    );
    canvas.scale(w / 48, w / 60);
    _drawLogo(canvas);
    canvas.restore();
  }

  /// Menggambar ulang bentuk logo (path asli dari SVG `0984935e…`).
  void _drawLogo(ui.Canvas canvas) {
    final green = ui.Paint()..color = const Color(0xFF6D9C25);
    final brown = ui.Paint()..color = const Color(0xFF89582B);
    final pathGreen = ui.Path()
      ..moveTo(20.4886, 0)
      ..lineTo(27.9246, 0.0433)
      ..cubicTo(34.176, 16.012, 41.627, 31.9183, 48, 47.8524)
      ..cubicTo(45.8225, 47.346, 43.2691, 46.7452, 41.0813, 46.4555)
      ..lineTo(35.9496, 34.5403)
      ..cubicTo(36.4704, 31.5106, 36.3938, 29.9654, 36.0661, 26.9406)
      ..cubicTo(35.0229, 27.0039, 34, 27.1861, 32.966, 27.3457)
      ..cubicTo(31.1634, 22.1994, 27.8077, 14.9909, 25.6068, 9.74565)
      ..cubicTo(25.1324, 8.59576, 24.6503, 7.57204, 24.1181, 6.45026)
      ..lineTo(7.06479, 46.492)
      ..cubicTo(4.57854, 46.8696, 2.45878, 47.2366, 0, 47.758)
      ..cubicTo(6.95986, 31.8946, 13.7897, 15.9751, 20.4886, 0)
      ..close();
    canvas.drawPath(pathGreen, green);
    final pathBrown = ui.Path()
      ..moveTo(26.6988, 47.5563)
      ..cubicTo(34.2541, 47.7022, 40.3922, 48.6764, 47.7333, 50.0925)
      ..cubicTo(47.1782, 50.8242, 46.3609, 51.9679, 45.7908, 52.646)
      ..cubicTo(30.7806, 49.5368, 17.2896, 49.187, 4.77641, 55.3431)
      ..cubicTo(4.03099, 54.5857, 2.90835, 53.5064, 2.25219, 52.7318)
      ..cubicTo(1.51298, 51.9143, 0.734947, 50.9616, 0.0150577, 50.114)
      ..cubicTo(7.06804, 48.6463, 14.9051, 47.5885, 22.116, 47.5542)
      ..lineTo(26.6988, 47.5563)
      ..close();
    canvas.drawPath(pathBrown, brown);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}
