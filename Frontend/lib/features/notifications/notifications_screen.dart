import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/app_notification.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/notification_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationController>().load();
    });
  }

  Future<void> _openPlant(int plantId) async {
    await Navigator.of(context).pushNamed(
      Routes.plantDetail,
      arguments: PlantDetailArgs(plantId: '$plantId'),
    );
    if (!mounted) return;
    context.read<NotificationController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const AgroIcon(AppAssets.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Notifikasi'),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: controller.isActing
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.markAllRead();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Semua notifikasi ditandai terbaca.'
                                : 'Gagal menandai notifikasi. Coba lagi.',
                          ),
                        ),
                      );
                    },
              child: const Text('Tandai semua'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(),
        child: _body(controller),
      ),
    );
  }

  Widget _body(NotificationController controller) {
    if (controller.isLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                Text(
                  'Notifikasi gagal dimuat. Periksa koneksi lalu coba lagi.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.lg),
                AgroButton(
                  label: 'Coba lagi',
                  onPressed: () => controller.load(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (controller.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                const AgroIcon(AppAssets.leafFill, size: 48),
                const SizedBox(height: AppSpacing.lg),
                Text('Belum ada notifikasi', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pengingat penyiraman dan perubahan fase tanaman akan '
                  'muncul di sini.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: controller.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = controller.items[index];
        final plantId = item.relatedPlantIds.isEmpty
            ? null
            : item.relatedPlantIds.first;

        return _NotificationCard(
          notification: item,
          onTap: () async {
            if (!item.isRead) {
              await context.read<NotificationController>().markAsRead(item.id);
            }
            if (plantId != null && mounted) await _openPlant(plantId);
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: notification.isRead ? AppColors.surface : AppColors.primarySurface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isUnread ? AppColors.primaryTint : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AgroIcon(
                  notification.isPhaseChange
                      ? AppAssets.leafFill
                      : AppAssets.waterDrop,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.isPhaseChange
                                ? 'Perubahan Fase'
                                : 'Pengingat Penyiraman',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
