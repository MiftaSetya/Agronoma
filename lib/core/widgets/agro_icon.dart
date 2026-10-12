import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ikon SVG dari `assets/icons`.
///
/// Warna sudah "dibakar" di berkas SVG sesuai design, jadi [color] hanya
/// untuk ikon monokrom yang perlu diseragamkan (`srcIn` mengganti semua piksel
/// tak transparan — mis. ikon putih di latar gelap).
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

  /// Tinggi ikon untuk ikon yang rasio aslinya bukan 1:1. Wajib diisi untuk
  /// ikon seperti itu: SVG Figma hampir semuanya memakai
  /// `preserveAspectRatio="none"`, jadi lebar & tinggi yang sama-sama
  /// ditentukan akan meregangkan isinya (contoh: `close-line` 14,7x19,2 dipaksa
  /// 24x24 menjadi 30% lebih besar). Isi dengan tinggi aslinya.
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

/// Ikon monokrom: warna asli (abu/hijau) dipaksa mengikuti warna teks
/// sekitarnya (mis. ikon di dalam tombol, ikon di samping "Lihat Semua").
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
