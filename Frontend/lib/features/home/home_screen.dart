import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_common.dart';
import 'package:frontend/core/widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlantController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlantController>();
    final name = context.select<AuthController, String>(
      (a) => a.user?.firstName ?? 'User',
    );

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),

      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xxl,
          AppSpacing.page,
          AppShell.bottomInset,
        ),
        children: [
          _Greeting(name: name),
          const SizedBox(height: AppSpacing.xxl),

          if (controller.cityWeather.isNotEmpty) ...[
            for (var i = 0; i < controller.cityWeather.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              WeatherCard(
                city: controller.cityWeather[i].city,
                condition: controller.cityWeather[i].condition,
                temperature: controller.cityWeather[i].temperatureLabel,
                iconAsset: controller.cityWeather[i].iconAsset,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],

          const SectionHeader(title: 'Tanaman Saya'),
          const SizedBox(height: AppSpacing.lg),
          if (controller.isLoading && controller.plants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.error != null && controller.plants.isEmpty)
            EmptyState(
              icon: AppAssets.pottedPlant,
              title: 'Gagal memuat data',
              message: 'Periksa koneksi internet, lalu coba lagi.',
              actionLabel: 'Coba lagi',
              onAction: () => controller.load(force: true),
            )
          else if (controller.isEmpty)
            EmptyState(
              icon: AppAssets.pottedPlant,
              title: 'Belum ada tanaman',
              message:
                  'Tekan tombol di tengah bawah untuk mulai menanam '
                  'tanaman pertamamu.',
            )
          else
            for (final plant in controller.plants)
              PlantCard(
                plant: plant,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.plantDetail,
                  arguments: PlantDetailArgs(plantId: plant.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hallo, $name!', style: AppTextStyles.greetingLarge),

        Text(
          'Ayo cek tanamanmu hari ini!',
          style: AppTextStyles.titleWide.copyWith(color: AppColors.darkGrey),
        ),
      ],
    );
  }
}
