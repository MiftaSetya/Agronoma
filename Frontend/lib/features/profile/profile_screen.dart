import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Layar Profil — frame `Profile` (node `28:1409`) pada Figma.
///
/// Ini isi tab saja; topbar & navbar disediakan `MainShell`/`AppShell`.
/// Jarak antar-seksi 32px (16px di dalam blok statistik), padding atas 24px —
/// semua dari komponen `profile content`. Nama pemilik diambil dari
/// [AuthController] (bukan ditulis mati seperti `Username` di design) supaya
/// selalu menampilkan pengguna yang sedang masuk.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        _ProfileHeader(name: user?.name ?? 'Username', photo: user?.photoAsset),
        const SizedBox(height: AppSpacing.xxxl),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: AppAssets.pottedPlant,
                title: 'Tanaman',
                value: '${user?.totalPlants ?? 0}',
                caption: 'Sedang tumbuh',
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: StatCard(
                icon: AppAssets.harvest,
                title: 'Dipanen',
                value: '${user?.harvestedThisSeason ?? 0}',
                caption: 'Musim ini',
                valueColor: AppColors.harvest,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _CareScoreCard(
          score: user?.careScoreLabel ?? '0%',
          caption: user?.careScoreCaption ?? '-',
        ),
        const SizedBox(height: AppSpacing.xxxl),
        _SettingsGroup(
          onArchiveTap: () {},
          logout: _LogoutCard(
            onTap: () {
              context.read<AuthController>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.login,
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Foto profil 80px + nama, di tengah, berjarak 8px.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, this.photo});

  final String name;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: photo == null
              ? const Icon(Icons.person, color: AppColors.grey)
              : Image.asset(photo!, fit: BoxFit.cover),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: AppTextStyles.displayName),
      ],
    );
  }
}

/// Kartu hijau "Skor perawatan" — garis tepinya `#659022`, hijau yang sedikit
/// lebih gelap dari latarnya (bukan abu).
class _CareScoreCard extends StatelessWidget {
  const _CareScoreCard({required this.score, required this.caption});

  final String score;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: const Color(0xFF659022)),
        boxShadow: AppColors.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AgroIcon(AppAssets.leafFill, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Skor perawatan',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            score,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: AppTextStyles.titleWide.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grup "Preferensi" + tombol "Keluar", digabung karena di design keduanya
/// berjarak sama dari blok sebelumnya.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.onArchiveTap, required this.logout});

  final VoidCallback onArchiveTap;
  final Widget logout;

  @override
  Widget build(BuildContext context) {
    // Design memakai `p-px` + `gap-[4px]` + `overflow-clip`, jadi latar abu
    // judulnya tidak "bocor" keluar radius.
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              const BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _PreferenceHeading(),
              _PreferenceRow(
                icon: AppAssets.waterDrop,
                title: 'Pengingat Penyiraman',
                subtitle: 'Notifikasi harian',
                trailing: const _WaterReminderSwitch(),
                showDivider: true,
              ),
              _PreferenceRow(
                icon: AppAssets.archive,
                title: 'Arsip tanaman',
                subtitle: 'Riwayat tanaman',
                onTap: onArchiveTap,
                trailing: const AgroIcon(
                  AppAssets.chevronRightSmall,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        logout,
      ],
    );
  }
}

class _PreferenceHeading extends StatelessWidget {
  const _PreferenceHeading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        8,
        AppSpacing.lg,
        9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        'PREFERENSI',
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.grey,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: AgroIcon(icon, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.menuRow),
                  Text(subtitle, style: AppTextStyles.menuRowCaption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Sakelar pengingat penyiraman, digambar sendiri (48x24, kenop 16px) karena
/// sakelar bawaan Material lebih besar. Keadaannya masih lokal, belum disimpan.
class _WaterReminderSwitch extends StatefulWidget {
  const _WaterReminderSwitch();

  @override
  State<_WaterReminderSwitch> createState() => _WaterReminderSwitchState();
}

class _WaterReminderSwitchState extends State<_WaterReminderSwitch> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _on = !_on),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(4),
        alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _on ? AppColors.primary : AppColors.border,
          borderRadius: AppRadius.chipAll,
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Tombol "Keluar": ikon pintu dalam lingkaran merah muda + teks merah.
class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.shadow1,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.dangerTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AgroIcon(AppAssets.logout, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                'Keluar',
                style: AppTextStyles.menuRow.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
