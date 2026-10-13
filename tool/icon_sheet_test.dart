import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Alat bantu pengembangan (bukan bagian test suite).
///
/// Menggambar SEMUA ikon di `assets/icons/` ke satu PNG berkisi, dan setiap sel
/// diberi label "indeks + 8 huruf pertama sha" supaya pemetaan nama berkas ke
/// bentuk ikon bisa dibaca langsung tanpa menebak.
///
/// Jalankan:
///   flutter test tool/icon_sheet_test.dart
///
/// Hasil: `build/icon_sheet.png`.
///
/// Catatan: test ini memang berakhir dengan timeout di runner (pemuatan SVG
/// menyisakan pekerjaan asinkron), tapi berkas PNG-nya sudah selesai ditulis
/// sebelum itu. Jadi jalankan, lalu abaikan status keluar dan pakai PNG-nya.
void main() {
  testWidgets('render kisi ikon berlabel', (tester) async {
    final files = Directory('assets/icons')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    const columns = 8;
    const cellW = 132.0;
    const cellH = 150.0;
    final rows = (files.length / columns).ceil();
    final width = columns * cellW;
    final height = rows * cellH;

    final sources = [for (final f in files) f.readAsStringSync()];
    final labels = [
      for (final f in files) f.uri.pathSegments.last.replaceAll('.svg', ''),
    ];

    final key = GlobalKey();
    await tester.binding.setSurfaceSize(Size(width, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: width,
              height: height,
              color: const Color(0xFFFFFFFF),
              child: Wrap(
                children: [
                  for (var i = 0; i < sources.length; i++)
                    Container(
                      width: cellW,
                      height: cellH,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        color: i.isEven
                            ? const Color(0xFFF2F2F2)
                            : const Color(0xFFFFFFFF),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$i  ${labels[i]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF000000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.string(sources[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    });

    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/icon_sheet.png');
    out.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());

    stdout.writeln('lebar=$width tinggi=$height kolom=$columns baris=$rows');
    for (var i = 0; i < files.length; i++) {
      stdout.writeln('${i.toString().padLeft(3)}: ${files[i].uri.pathSegments.last}');
    }
    stdout.writeln('tersimpan: ${out.path}');
  }, timeout: const Timeout(Duration(seconds: 120)));
}
