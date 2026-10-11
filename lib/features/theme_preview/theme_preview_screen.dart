import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/theme/theme.dart';

/// Screen sementara: menampilkan token theme dan memuat aset nyata dari
/// `assets/` supaya kegagalan bundling aset langsung ketahuan.
///
/// Dipindahkan apa adanya dari `main.dart` saat splash screen dipasang, supaya
/// `main.dart` tetap tipis dan hanya berisi komposisi aplikasi. Screen ini bukan
/// bagian dari alur produk dan akan dihapus begitu seluruh alur Fase 2 tersedia.
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  // Contoh aset yang benar-benar ada di project, dari manifest Fase 0.
  static const _svgArrow =
      'assets/icons/ef737f2fd5f77ee8b2373bcd192ef31ba14d492b.svg';
  static const _svgPlant =
      'assets/icons/94312fbfd7eb7a516ff388c59c4dafa9851503ba.svg';
  static const _jpgPhoto =
      'assets/images/83fcae546fbfaec4e5b6e7980bb5365d0cf4c9e4.jpg';
  static const _pngCutout =
      'assets/images/5fd926b61cce8291149523be00289d78b3b7b5d2.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Fase 1')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _Section('Tipografi'),
          _styleTile('displayLarge', AppTextStyles.displayLarge, '28°C'),
          _styleTile('displayMedium', AppTextStyles.displayMedium, '98%'),
          _styleTile(
            'headlineLarge',
            AppTextStyles.headlineLarge,
            'Cabai Rawit',
          ),
          _styleTile(
            'headlineMedium',
            AppTextStyles.headlineMedium,
            'Tambah tanaman',
          ),
          _styleTile('titleLarge', AppTextStyles.titleLarge, 'Detail Tanam'),
          _styleTile(
            'bodyLarge',
            AppTextStyles.bodyLarge,
            'Sangat adaptif dengan suhu terik.',
          ),
          _styleTile(
            'bodyMuted',
            AppTextStyles.bodyMuted,
            'Masuk untuk melanjutkan perawatan tanamanmu.',
          ),
          _styleTile('bodyCaption', AppTextStyles.bodyCaption, '2 jam lalu'),
          _styleTile('labelSmall', AppTextStyles.labelSmall, 'PERLU DISIRAM'),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Warna resmi (Figma Variables)'),
          _swatches({
            'primary': AppColors.primary,
            'grey': AppColors.grey,
            'darkGrey': AppColors.darkGrey,
            'mainWhite': AppColors.mainWhite,
            'lightGrey': AppColors.lightGrey,
            'labelPrimary': AppColors.labelPrimary,
          }),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Warna turunan — netral'),
          _swatches({
            'ink': AppColors.ink,
            'surfaceMuted': AppColors.surfaceMuted,
            'surfaceAlt': AppColors.surfaceAlt,
            'borderStrong': AppColors.borderStrong,
            'muted': AppColors.muted,
          }),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Warna turunan — semantik'),
          _swatches({
            'primaryLight': AppColors.primaryLight,
            'primaryDark': AppColors.primaryDark,
            'primaryTint': AppColors.primaryTint,
            'careWaterTint': AppColors.careWaterTint,
            'careWater': AppColors.careWater,
            'careFertilize': AppColors.careFertilize,
            'careFertilizeSurface': AppColors.careFertilizeSurface,
            'danger': AppColors.danger,
            'star': AppColors.star,
            'harvest': AppColors.harvest,
          }),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Komponen'),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Lanjut'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Kembali'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'nama@email.com',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            child: Row(
              children: [
                _statusChip(
                  'PERLU DISIRAM',
                  AppColors.careWaterTint,
                  AppColors.careWater,
                ),
                const SizedBox(width: AppSpacing.sm),
                _statusChip(
                  'PERLU PUPUK',
                  AppColors.careFertilizeTint,
                  AppColors.careFertilize,
                ),
                const SizedBox(width: AppSpacing.sm),
                _statusChip(
                  'KONDISI AMAN',
                  AppColors.primaryTint,
                  AppColors.primaryDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Aset — SVG'),
          Row(
            children: [
              _svgBox(_svgArrow),
              const SizedBox(width: AppSpacing.md),
              _svgBox(_svgPlant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SvgPicture.asset(
                  _svgArrow,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Aset — raster'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _imageBox(_jpgPhoto, 'JPEG 1200x1200')),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _imageBox(_pngCutout, 'PNG alpha')),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
          _Section('Analisa'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'flutter analyze & test',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aset terdaftar: 117 ikon SVG + 19 gambar = 136.\n'
                  'Semua dipetakan di tool/manifest.json.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  static Widget _styleTile(String name, TextStyle style, String sample) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(name, style: AppTextStyles.bodyCaption),
          ),
          Expanded(child: Text(sample, style: style)),
        ],
      ),
    );
  }

  static Widget _swatches(Map<String, Color> colors) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: colors.entries.map((e) {
        final onDark = e.value.computeLuminance() < 0.5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 48,
              decoration: BoxDecoration(
                color: e.value,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                _hex(e.value),
                style: AppTextStyles.labelSmall.copyWith(
                  color: onDark ? AppColors.surface : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 72,
              child: Text(
                e.key,
                style: AppTextStyles.bodyCaption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadow1,
      ),
      child: child,
    );
  }

  static Widget _statusChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.chipAll),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: fg)),
    );
  }

  static Widget _svgBox(String path) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SvgPicture.asset(path),
    );
  }

  static Widget _imageBox(String path, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(path, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodyCaption),
      ],
    );
  }

  static String _hex(Color c) {
    final v = c.toARGB32();
    final r = (v >> 16) & 0xFF;
    final g = (v >> 8) & 0xFF;
    final b = v & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
        ],
      ),
    );
  }
}
