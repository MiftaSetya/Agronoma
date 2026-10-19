import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/notification_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().refreshStats();
      context.read<NotificationController>().load();
    });
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 960,
    );
    if (picked == null || !mounted) return;

    final auth = context.read<AuthController>();
    final ok = await auth.uploadPhoto(picked.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Foto profil berhasil diperbarui.'
              : 'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xxl,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        _ProfileHeader(
          name: user?.name ?? 'Username',
          photo: user?.photoAsset,
          photoUrl: user?.photoUrl,
          uploading: auth.isUploadingPhoto,
          onTapPhoto: _changePhoto,
        ),
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
                caption: 'Total panen',
                valueColor: AppColors.harvest,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        _SettingsGroup(
          onArchiveTap: () async {
            await Navigator.of(context).pushNamed(Routes.archivedPlants);
            if (!context.mounted) return;
            await context.read<AuthController>().refreshStats();
          },
          onNotificationsTap: () async {
            await Navigator.of(context).pushNamed(Routes.notifications);
            if (!context.mounted) return;
            context.read<NotificationController>().load();
          },
          unreadCount: context.watch<NotificationController>().unreadCount,
          reminderEnabled: user?.wateringReminderEnabled ?? true,
          reminderSaving: context.watch<AuthController>().isSavingReminder,
          onReminderChanged: (value) async {
            final auth = context.read<AuthController>();
            final ok = await auth.setWateringReminder(value);
            if (!context.mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Gagal menyimpan pengaturan. Periksa koneksi lalu coba lagi.',
                  ),
                ),
              );
            }
          },
          logout: _LogoutCard(
            onTap: () async {
              await context.read<AuthController>().signOut();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.login, (route) => false);
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.onTapPhoto,
    this.photo,
    this.photoUrl,
    this.uploading = false,
  });

  final String name;
  final String? photo;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          key: const Key('profile-photo'),
          onTap: uploading ? null : onTapPhoto,
          child: Stack(
            alignment: Alignment.bottomRight,
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
                child: uploading
                    ? const Center(child: CircularProgressIndicator())
                    : photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          color: AppColors.grey,
                        ),
                      )
                    : photo == null
                    ? const Icon(Icons.person, color: AppColors.grey)
                    : Image.asset(photo!, fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: AppTextStyles.displayName),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ketuk foto untuk mengganti',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.onArchiveTap,
    required this.onNotificationsTap,
    required this.unreadCount,
    required this.reminderEnabled,
    required this.reminderSaving,
    required this.onReminderChanged,
    required this.logout,
  });

  final VoidCallback onArchiveTap;
  final VoidCallback onNotificationsTap;
  final int unreadCount;
  final bool reminderEnabled;
  final bool reminderSaving;
  final ValueChanged<bool> onReminderChanged;
  final Widget logout;

  @override
  Widget build(BuildContext context) {
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
                trailing: _WaterReminderSwitch(
                  value: reminderEnabled,
                  saving: reminderSaving,
                  onChanged: onReminderChanged,
                ),
                showDivider: true,
              ),
              _PreferenceRow(
                icon: AppAssets.archive,
                title: 'Arsip tanaman',
                subtitle: 'Riwayat tanaman',
                onTap: onArchiveTap,
                trailing: const AgroIcon(AppAssets.chevronRightSmall, size: 12),
              ),
              _PreferenceRow(
                icon: AppAssets.checkCircle,
                title: 'Notifikasi',
                subtitle: unreadCount > 0
                    ? '$unreadCount belum dibaca'
                    : 'Pengingat & info fase',
                onTap: onNotificationsTap,
                trailing: AgroIcon(AppAssets.chevronRightSmall, size: 12),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 9),
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

class _WaterReminderSwitch extends StatelessWidget {
  const _WaterReminderSwitch({
    required this.value,
    required this.onChanged,
    required this.saving,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: saving ? 0.5 : 1,
      child: GestureDetector(
        onTap: saving ? null : () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 48,
          height: 24,
          padding: const EdgeInsets.all(4),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.border,
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
      ),
    );
  }
}

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
            color: AppColors.surface,
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
