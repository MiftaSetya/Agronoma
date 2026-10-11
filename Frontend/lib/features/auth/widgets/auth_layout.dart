import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';

/// Kerangka bersama untuk Login dan Register.
///
/// Keduanya memakai susunan yang sama persis di design, jadi jaraknya diukur
/// sekali di sini (node `150:951` / `155:1357`, blok `Frame 63`, `Frame 64`)
/// dan pemanggilnya cukup mengisi [fields] + [submit] tanpa mengatur jarak
/// sendiri. Kalau tiap layar mengatur jaraknya masing-masing, cepat atau lambat
/// keduanya akan berbeda satu-dua piksel tanpa ada yang tahu mana yang benar.
///
/// Ukuran dari design (relatif terhadap area di bawah status bar):
///
/// | Bagian | Jarak |
/// |---|---|
/// | tepi atas → logo | 60 |
/// | logo → judul | 40 |
/// | judul → subjudul | 8 |
/// | subjudul → field pertama | 32 |
/// | antar field | 24 |
/// | field terakhir → tombol | 40 |
/// | tombol → teks tautan | 32 |
///
/// Lebar blok judul 293 (bukan selebar halaman) supaya subjudul membungkus
/// menjadi dua baris tepat seperti di design.
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

  /// Field-field form, diberi jarak 24 satu sama lain.
  final List<Widget> fields;

  /// Tombol utama di bawah form.
  final Widget submit;

  /// Teks tautan paling bawah, mis. "Belum punya akun? Daftar".
  final Widget footer;

  /// Jarak dari baris area status bar ke logo. Pada design, blok logo
  /// (`Frame 63`) berada 60px di bawah `Frame 65` yang mulai tepat di bawah
  /// status bar.
  static const double _logoTopOffset = 60;

  /// Lebar blok judul pada design.
  static const double _headerWidth = 293;

  @override
  Widget build(BuildContext context) {
    // Inset atas sudah diseragamkan di `app.dart`, jadi di sini cukup 60px:
    // blok logo (`Frame 63`) berada 60px di bawah area status bar pada design.
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
                    // Logo "A" berdaun; tinggi aslinya 60 pada design.
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

/// Teks tautan "Sudah punya akun? Masuk" dengan bagian yang bisa ditekan.
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
