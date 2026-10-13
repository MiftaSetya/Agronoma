import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Menjaga penamaan aset tetap deskriptif. Sebelumnya berkas dinamai id aset
/// Figma (SHA-1 40 huruf) apa adanya sehingga sulit dibaca dan gampang salah
/// pasang — keliru menunjuk berkas rekan yang identik pernah menghasilkan
/// tombol tak terlihat. Test ini menolak nama hash, spasi, garis bawah, dan
/// huruf besar yang lolos kembali.
void main() {
  final dirs = ['assets/icons', 'assets/images'];

  test('tidak ada berkas aset yang bernama id SHA', () {
    final offenders = <String>[];

    for (final dir in dirs) {
      for (final f in Directory(dir).listSync().whereType<File>()) {
        final base = f.uri.pathSegments.last.split('.').first;
        if (RegExp(r'^[0-9a-f]{32,}$').hasMatch(base)) {
          offenders.add(f.path.replaceAll(r'\', '/'));
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Berkas masih bernama id aset Figma:\n${offenders.join('\n')}',
    );
  });

  test('setiap berkas aset memakai kebab-case', () {
    final bad = <String>[];

    for (final dir in dirs) {
      for (final f in Directory(dir).listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*\.(svg|jpg|png)$').hasMatch(name)) {
          bad.add('$dir/$name');
        }
      }
    }

    expect(bad, isEmpty, reason: 'Nama aset bukan kebab-case:\n${bad.join('\n')}');
  });

  test('setiap nama berkas ada di manifest dan di tool/asset-names.json', () {
    final manifest = jsonDecode(File('tool/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final names = (manifest['assets'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) => e['name'] as String)
        .toSet();

    final prov = jsonDecode(File('tool/asset-names.json').readAsStringSync())
        as Map<String, dynamic>;

    final problems = <String>[];
    for (final dir in dirs) {
      for (final f in Directory(dir).listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!names.contains(name)) {
          problems.add('tidak ada di manifest: $name');
        }
        if (!prov.containsValue(name)) {
          problems.add('tidak ada di asset-names.json: $name');
        }
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('setiap konstanta AppAssets menunjuk berkas yang ada', () {
    final src = File('lib/core/assets/app_assets.dart').readAsStringSync();
    final paths = RegExp(
      r"'\$_(icons|images)/([^']+)'",
    ).allMatches(src).map((m) => 'assets/${m.group(1)}/${m.group(2)}');

    final missing = paths.where((p) => !File(p).existsSync()).toList();
    expect(missing, isEmpty, reason: 'Path AppAssets menunjuk berkas hilang:\n${missing.join('\n')}');
  });
}
