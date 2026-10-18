import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/app_shell.dart';

class ArchivedPlantsScreen extends StatefulWidget {
  const ArchivedPlantsScreen({super.key});

  @override
  State<ArchivedPlantsScreen> createState() => _ArchivedPlantsScreenState();
}

class _ArchivedPlantsScreenState extends State<ArchivedPlantsScreen> {
  bool _loading = true;
  String? _busyPlantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await context.read<PlantController>().loadArchived();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _restore(String plantId) async {
    setState(() => _busyPlantId = plantId);
    final ok = await context.read<PlantController>().restore(plantId);
    if (!mounted) return;
    setState(() => _busyPlantId = null);

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tanaman dikembalikan ke daftar aktif.')),
      );
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gagal mengembalikan tanaman. Periksa koneksi Anda.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final plants = controller.archivedPlants;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          AgroTopBar(
            title: 'Arsip Tanaman',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : plants.isEmpty
                ? const EmptyState(
                    icon: AppAssets.archive,
                    title: 'Arsip masih kosong',
                    message:
                        'Tanaman yang sudah selesai dipanen akan muncul di '
                        'sini setelah diarsipkan.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.xxl,
                        AppSpacing.page,
                        AppSpacing.xxl,
                      ),
                      itemCount: plants.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return _ArchivedCard(
                          plant: plant,
                          busy: _busyPlantId == plant.id,
                          onRestore: () => _restore(plant.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({
    required this.plant,
    required this.busy,
    required this.onRestore,
  });

  final Plant plant;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadow1,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: PlantPhoto(plant: plant, width: 64, height: 64),
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
                Text(plant.location, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: busy ? null : onRestore,
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kembalikan'),
          ),
        ],
      ),
    );
  }
}
