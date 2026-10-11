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
    this.height,
    this.semanticLabel,
    this.color,
  });

  /// Path aset, HARUS lewat konstanta di `AppAssets`.
  final String asset;

  /// Lebar ikon. Bila [height] kosong, tinggi mengikuti nilai ini juga.
  final double size;

  /// Tinggi ikon, untuk ikon yang rasio aslinya **bukan** 1:1.
  ///
  /// Ini bukan hiasan: berkas SVG dari Figma hampir semuanya ditulis dengan
  /// `preserveAspectRatio="none"`, jadi begitu lebar dan tinggi sama-sama
  /// ditentukan, isinya **diregangkan** ke kotak itu. Selama ini tidak terasa
  /// karena hampir semua ikon dipasang di design dengan ukuran simpul yang
  /// kebetulan sama dengan ukuran aslinya. Beberapa tidak: silang `close-line`
  /// aslinya 14,7x19,2 tetapi simpulnya 24x24 — memaksa 24x24 membuat silangnya
  /// 30% lebih besar dari design. Untuk ikon seperti itu, isi [height] dengan
  /// tinggi aslinya.
  final double? height;

  /// Nama untuk pembaca layar. Kosong berarti ikon dianggap murni hiasan.
  final String? semanticLabel;

  /// Bila diisi, seluruh piksel ikon diganti warna ini.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: height ?? size,
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
    this.height,
    required this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final double? height;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AgroIcon(
      asset,
      size: size,
      height: height,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
