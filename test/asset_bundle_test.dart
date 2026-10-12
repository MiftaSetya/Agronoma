import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Memastikan aset Fase 0 ter-bundle: manifest dikunci sebagai kontrak
/// anti-duplikat/anti-usang (aset lepas dari daftar langsung ketahuan), dan
/// isinya diverifikasi sesuai jenisnya — pernah ada file error HTML tersimpan
/// berekstensi gambar saat mengunduh dari server aset Figma.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> entries;

  setUpAll(() {
    final file = File('tool/manifest.json');
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'tool/manifest.json tidak ditemukan. Jalankan tool/fetch_assets.ps1 '
          'dan tool/optimize_assets.ps1 lebih dulu.',
    );
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    entries = (json['assets'] as List).cast<Map<String, dynamic>>();
  });

  test('manifest memuat 136 aset', () {
    expect(entries.length, 136);
    expect(entries.where((e) => e['kind'] == 'icon').length, 118);
    expect(entries.where((e) => e['kind'] == 'image').length, 18);
  });

  test('setiap aset ada di disk dan isinya sesuai ekstensi', () {
    final problems = <String>[];

    for (final e in entries) {
      final path = e['path'] as String;
      final file = File(path);

      if (!file.existsSync()) {
        problems.add('HILANG  $path');
        continue;
      }

      final bytes = file.readAsBytesSync();
      if (bytes.length < 32) {
        problems.add('TERLALU KECIL  $path (${bytes.length} byte)');
        continue;
      }

      final ext = (e['ext'] as String).toLowerCase();
      switch (ext) {
        case 'svg':
          final head = utf8.decode(
            bytes.sublist(0, bytes.length < 256 ? bytes.length : 256),
            allowMalformed: true,
          );
          if (!head.contains('<svg') && !head.contains('<?xml')) {
            problems.add('BUKAN SVG  $path');
          }
          break;
        case 'png':
          const pngSig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
          if (!_startsWith(bytes, pngSig)) {
            problems.add('BUKAN PNG  $path');
          }
          break;
        case 'jpg':
          if (!(bytes[0] == 0xFF && bytes[1] == 0xD8)) {
            problems.add('BUKAN JPEG  $path');
          }
          break;
        default:
          problems.add('EKSTENSI TIDAK DIKENAL  $path ($ext)');
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test(
    'setiap aset bisa dimuat lewat rootBundle (deklarasi pubspec benar)',
    () async {
      final problems = <String>[];

      for (final e in entries) {
        final path = e['path'] as String;
        try {
          final data = await rootBundle.load(path);
          if (data.lengthInBytes == 0) {
            problems.add('KOSONG  $path');
          }
        } catch (err) {
          problems.add('GAGAL DIMUAT  $path -> $err');
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    },
  );

  test('aset di disk tidak ada yang luput dari manifest', () {
    final luput = <String>[];

    for (final dir in ['assets/icons', 'assets/images']) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final f in d.listSync().whereType<File>()) {
        final rel = f.path.replaceAll(r'\', '/');
        if (!entries.any((e) => e['path'] == rel)) {
          luput.add(rel);
        }
      }
    }

    expect(
      luput,
      isEmpty,
      reason: 'Tidak tercatat di manifest:\n${luput.join('\n')}',
    );
  });

  test('font yang dipakai theme tersedia di disk', () {
    const fonts = [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Poppins-Bold.ttf',
    ];
    for (final f in fonts) {
      expect(File(f).existsSync(), isTrue, reason: 'font hilang: $f');
    }
  });

  test('lisensi font ikut disertakan', () {
    expect(File('assets/fonts/OFL-Inter.txt').existsSync(), isTrue);
    expect(File('assets/fonts/OFL-Poppins.txt').existsSync(), isTrue);
  });
}

bool _startsWith(List<int> bytes, List<int> sig) {
  if (bytes.length < sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (bytes[i] != sig[i]) return false;
  }
  return true;
}
