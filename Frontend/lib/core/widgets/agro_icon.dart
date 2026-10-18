import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AgroIcon extends StatelessWidget {
  const AgroIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.height,
    this.semanticLabel,
    this.color,
  });

  final String asset;

  final double size;

  final double? height;

  final String? semanticLabel;

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
