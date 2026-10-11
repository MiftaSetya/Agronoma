import 'package:flutter/material.dart';

import 'package:frontend/core/theme/theme.dart';

/// Tombol utama (hijau penuh) — komponen "Big button" di design (node `66:678`).
///
/// Tingginya 54px di design (bukan 50 seperti tombol lain), radius 16, teks
/// putih SemiBold.
class AgroButton extends StatelessWidget {
  const AgroButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Widget ikon opsional di kiri label.
  final Widget? icon;

  /// Menampilkan pemintal dan mematikan tombol.
  final bool loading;

  /// Memenuhi lebar induk (default) atau hanya selebar isinya.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
              Text(label, style: AppTextStyles.buttonLarge),
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.borderStrong,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Tombol sekunder (garis hijau).
class AgroOutlineButton extends StatelessWidget {
  const AgroOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 54),
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
          Text(label, style: AppTextStyles.buttonOutline),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
