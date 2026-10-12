import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';

/// Kerangka bersama Login & Register: geometrinya (node `150:951` / `155:1357`,
/// blok `Frame 63`/`Frame 64`) diukur sekali di sini supaya kedua layar tidak
/// berbeda satu-dua piksel. Jarak dari design (relatif area di bawah status bar):
/// 60 → logo, 40 → judul, 8 → subjudul, 32 → field pertama, 24 antar field,
/// 40 → tombol, 32 → tautan. Lebar blok judul 293 (bukan selebar halaman)
/// agar subjudul membungkus jadi dua baris seperti di design.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submit,
    required this.footer,
  });

  final String title;
  final String subtitle;

  final List<Widget> fields;

  final Widget submit;

  final Widget footer;

  /// Jarak dari baris area status bar ke logo: blok logo (`Frame 63`) berada
  /// 60px di bawah `Frame 65` yang mulai tepat di bawah status bar.
  static const double _logoTopOffset = 60;

  /// Lebar blok judul pada design; lihat doc kelas.
  static const double _headerWidth = 293;

  @override
  Widget build(BuildContext context) {
    // Inset atas sudah diseragamkan di `app.dart`, jadi di sini cukup 60px.
    const topPadding = _logoTopOffset;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding horizontal 40 → lebar field 360, sama seperti design.
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              SizedBox(height: topPadding),
              SizedBox(
                width: _headerWidth,
                child: Column(
                  children: [
                    // Logo "A" berdaun; tinggi 60 mengikuti design.
                    Semantics(
                      label: 'Agronoma',
                      image: true,
                      child: SvgPicture.asset(AppAssets.logoMark, height: 60),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xxl),
                fields[i],
              ],
              const SizedBox(height: 40),
              submit,
              const SizedBox(height: AppSpacing.xxxl),
              footer,
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tautan footer auth: teks polos + bagian berwarna yang bisa ditekan.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.actionLabel,
    required this.onTap,
  });

  final String prefix;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: prefix,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.ink),
            ),
            TextSpan(
              text: actionLabel,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
