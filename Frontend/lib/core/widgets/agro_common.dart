import 'package:flutter/material.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Judul seksi, mis. "Tanaman Saya".
///
/// Di design, "Lihat Semua" berada di dalam container `Frame 24:1101` yang
/// **disetel tersembunyi** (`hidden="true"` pada node itu), jadi di Home hanya
/// judulnya yang tampak. [actionLabel] tetap disediakan karena komponen yang
/// sama dipakai di layar lain (mis. Disease Detection) dengan tautan aktif.
///
/// Ukurannya juga mengikuti design: baris setinggi 28px, judul 20px SemiBold,
/// dan tautan 14px. Tinggi barisnya penting karena menjadi acuan jarak ke kartu
/// di bawahnya.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineLarge),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const AgroIconTinted(
                  AppAssets.chevronRight,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kartu tanaman — komponen `Plant card` di design (node `56:670`).
///
/// Susunan aslinya: padding 17, jarak 12, foto 80x80 radius 8, lalu kolom
/// judul + baris lokasi + chip status, dan lencana status bulat 32px di kanan.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Plant plant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.shadow1,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: Image.asset(
                    plant.photoAsset,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _LocationLine(plant: plant),
                      const SizedBox(height: AppSpacing.xs),
                      CareStatusChip(status: plant.status),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CareStatusBadge(status: plant.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyLarge.copyWith(color: AppColors.grey);
    return Row(
      children: [
        const AgroIcon(AppAssets.locationFill, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(plant.location, style: style),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.muted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            plant.place,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Chip status huruf kapital, mis. "PERLU DISIRAM".
class CareStatusChip extends StatelessWidget {
  const CareStatusChip({super.key, required this.status});

  final CareStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.border),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: status.foreground),
      ),
    );
  }
}

/// Lencana bulat 32px berisi ikon status (`Care Status/32px`, node `239:2316`).
class CareStatusBadge extends StatelessWidget {
  const CareStatusBadge({super.key, required this.status, this.size = 32});

  final CareStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.tint,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadow1,
      ),
      alignment: Alignment.center,
      child: AgroIcon(
        switch (status) {
          CareStatus.needsWater => AppAssets.waterDrops,
          CareStatus.needsFertilizer => AppAssets.wateringCan,
          CareStatus.safe => AppAssets.checkCircle,
        },
        size: size / 2,
      ),
    );
  }
}

/// Kartu ringkasan angka (dipakai di Profile: "Tanaman 24", "Dipanen 12").
///
/// Ukurannya mengikuti komponen `Total Plants` / `Harvested` pada design:
/// padding 17, radius 12, jarak antar-baris **4** (bukan 8), border
/// `#E1E3E4` — abu yang sedikit lebih dingin dari border kartu biasa.
/// Lebarnya 196px karena dua kartu + jarak 16 harus pas 408 pada kanvas 440.
///
/// Warnanya hanya berbeda di angka ([valueColor]): hijau untuk tanaman yang
/// sedang tumbuh, cokelat untuk hasil panen.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.valueColor,
    this.margin = EdgeInsets.zero,
  });

  final String icon;
  final String title;
  final String value;
  final String caption;
  final Color valueColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: AppColors.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgroIcon(icon, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(letterSpacing: 0.14),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(color: valueColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: AppTextStyles.titleWide.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

/// Kartu cuaca — komponen `Weather card` (node `239:2591`).
///
/// Ukuran aslinya dari design: **408x82**, padding 17, radius 16. Komposisinya
/// ikon 48 di kiri, lalu judul 20px SemiBold (`Surabaya`) dengan keterangan
/// 14px Regular di bawahnya, dan suhu 32px Medium di kanan.
///
/// Kartu ini **putih**, bukan biru: kesan kebiruan datang dari satu lingkaran
/// `rgba(223,244,251,0.59)` berukuran 128px yang di-blur 20px dan diposisikan
/// keluar di sudut kanan atas (`right -40, top -40`). Karena itu latarnya
/// direplikasi sebagai lapisan terpisah di bawah isi kartu.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.city,
    required this.condition,
    required this.temperature,
    this.iconAsset,
    this.onTap,
  });

  final String city;
  final String condition;
  final String temperature;
  final String? iconAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 82,
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: const Color(0x96DFF4FB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x96DFF4FB),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      if (iconAsset != null) AgroIcon(iconAsset!, size: 48),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              city,
                              style: AppTextStyles.headlineLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              condition,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(temperature, style: AppTextStyles.displayLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong dengan ikon, judul, dan keterangan.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AgroIcon(icon, size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
