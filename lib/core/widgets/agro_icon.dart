import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ikon SVG dari `assets/icons`.
///
/// Warna ikon sudah "dibakar" di dalam berkas SVG-nya sesuai design (hijau,
/// biru, kuning, abu), jadi secara default ikon dipakai apa adanya: mengisi
/// [color] justru akan menimpanya.
///
/// [color] hanya untuk ikon monokrom yang memang perlu diseragamkan dengan
/// sekitarnya — kasus paling umum adalah ikon putih di atas latar gelap, karena
/// `srcIn` mengganti seluruh piksel yang tidak transparan.
class AgroIcon extends StatelessWidget {
  const AgroIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.semanticLabel,
    this.color,
  });

  /// Path aset, HARUS lewat konstanta di `AppAssets`.
  final String asset;

  final double size;

  /// Nama untuk pembaca layar. Kosong berarti ikon dianggap murni hiasan.
  final String? semanticLabel;

  /// Bila diisi, seluruh piksel ikon diganti warna ini.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// Ikon monokrom yang dipaksa menjadi satu warna.
///
/// Dipakai saat ikon aslinya berwarna abu/hijau tetapi di design harus mengikuti
/// warna teks di sekitarnya (mis. ikon di dalam tombol, atau ikon hijau kecil di
/// sebelah tautan "Lihat Semua").
class AgroIconTinted extends StatelessWidget {
  const AgroIconTinted(
    this.asset, {
    super.key,
    this.size = 24,
    required this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AgroIcon(
      asset,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
