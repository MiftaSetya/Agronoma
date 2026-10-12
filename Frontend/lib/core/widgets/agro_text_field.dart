import 'package:flutter/material.dart';

import 'package:frontend/core/theme/theme.dart';

/// Kolom teks berjudul — komponen `textfield/with title` (node `278:2802`):
/// label SemiBold 14, jarak 8, input tinggi 44, border `#E7E9E7` radius 12.
class AgroTextField extends StatelessWidget {
  const AgroTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  /// Ikon di dalam kotak, di kiri (mis. tag/pot pada varian field).
  final Widget? prefixIcon;

  /// Widget di kanan, mis. tombol mata untuk kata sandi.
  final Widget? suffix;

  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          enabled: enabled,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.sm,
                    ),
                    child: prefixIcon,
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: suffix,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol mata untuk menampilkan/menyembunyikan kata sandi
/// (`text_icons/show password`, node `155:993`).
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Saat kata sandi tersembunyi, design menampilkan ikon mata terbuka
    // (artinya "ketuk untuk melihat"), dan ikon mata tercoret saat kata sandi
    // sedang terlihat ("ketuk untuk menyembunyikan"). Itu juga pola yang lazim,
    // jadi ikon Material dipakai apa adanya tanpa aset tambahan.
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: AppColors.grey,
      ),
    );
  }
}

/// Field yang menampilkan pilihan (dropdown) — varian paling bawah pada
/// komponen field di design, dengan panah ke bawah dan icon di kiri.
class AgroSelectField extends StatelessWidget {
  const AgroSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.prefixIcon,
  });

  final String label;

  /// Nilai terpilih; null berarti belum ada (tampilkan [hint]).
  final String? value;
  final VoidCallback onTap;
  final String? hint;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final filled = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Container(
            height: AppSizes.fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: filled ? AppColors.borderStrong : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    value ?? hint ?? 'Pilih',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: filled ? AppColors.ink : AppColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
