import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submit,
    required this.footer,
    this.error,
  });

  final String title;
  final String subtitle;

  final List<Widget> fields;

  final String? error;

  final Widget submit;

  final Widget footer;

  static const double _logoTopOffset = 60;

  static const double _headerWidth = 293;

  @override
  Widget build(BuildContext context) {
    const topPadding = _logoTopOffset;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              SizedBox(height: topPadding),
              SizedBox(
                width: _headerWidth,
                child: Column(
                  children: [
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
              if (error != null) ...[
                _ErrorBanner(message: error!),
                const SizedBox(height: AppSpacing.xxl),
              ],
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.danger),
      ),
    );
  }
}

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
