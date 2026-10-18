import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/map_location.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/plant_recommendation.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_icon.dart';
import 'package:frontend/core/widgets/agro_map.dart';
import 'package:frontend/core/widgets/agro_text_field.dart';
import 'package:frontend/core/widgets/app_shell.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';

class AddPlantFlow extends StatefulWidget {
  const AddPlantFlow({
    super.key,
    this.initialStep = 0,
    this.soilListOpen = false,
  });

  final int initialStep;

  final bool soilListOpen;

  static const String topBarTitle = 'Tambah tanaman';

  static const List<String> stepLabels = [
    'Lokasi penanaman',
    'Media tanam',
    'Analisis tanah',
    'Rekomendasi tanaman',
    'Fase tumbuh tanaman',
  ];

  @override
  State<AddPlantFlow> createState() => _AddPlantFlowState();
}

class _AddPlantFlowState extends State<AddPlantFlow> {
  late int _step = widget.initialStep.clamp(0, 4);

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddPlantController>().reset();
    });
  }

  bool get _canContinue {
    final draft = context.read<AddPlantController>().draft;
    return switch (_step) {
      0 => draft.hasLocation,
      1 => draft.hasMedia,
      2 => draft.hasSoil,
      3 => draft.hasPlant,
      4 => draft.phase != null,
      _ => false,
    };
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final add = context.read<AddPlantController>();
    final plants = context.read<PlantController>();
    try {
      final plant = await add.savePlant();

      await plants.adopt(plant);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        Routes.plantDetail,
        arguments: PlantDetailArgs(plantId: plant.id),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan tanaman. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AddPlantController>();

    return Scaffold(
      backgroundColor: AppColors.surface,

      body: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _step > 0) setState(() => _step--);
        },
        child: Column(
          children: [
            AgroTopBar(title: AddPlantFlow.topBarTitle, onBack: _back),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _LocationStep(onNext: _next),
                      1 => _MediaStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      2 => _SoilStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                        openListByDefault: widget.soilListOpen,
                      ),
                      3 => _RecommendationStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                      ),
                      _ => _PhaseStep(
                        onBack: _back,
                        onNext: _next,
                        enabled: _canContinue,
                        saving: _saving,
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const double _border = 1;

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final int step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page - _border,
        AppSpacing.xxl - _border,
        AppSpacing.page - _border,
        AppSpacing.lg - _border,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        boxShadow: AppColors.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressStepIndicator(
            current: step,
            total: 5,
            label: AddPlantFlow.stepLabels[step],
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            description,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class ProgressStepIndicator extends StatelessWidget {
  const ProgressStepIndicator({
    super.key,
    required this.current,
    required this.total,
    this.label,
  });

  final int current;
  final int total;

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Langkah ${current + 1} dari $total:',

                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w500,
                    height: 16 / 14,
                  ),
                ),
                TextSpan(
                  text: ' ${label!}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.darkGrey,
                    height: 16 / 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < current
                        ? AppColors.primary
                        : i == current
                        ? AppColors.primaryLight
                        : AppColors.lightGrey,
                    borderRadius: AppRadius.chipAll,
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.onBack,
    required this.onNext,
    required this.enabled,
    this.saving = false,
    this.nextLabel = 'Lanjut',
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;
  final bool saving;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AgroOutlineButton(label: 'Kembali', onPressed: onBack),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AgroButton(
              label: nextLabel,
              loading: saving,
              onPressed: enabled ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const AgroIcon(AppAssets.pottedPlant, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Gagal memuat data',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Periksa koneksi internet, lalu coba lagi.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 200,
            child: AgroOutlineButton(label: 'Coba lagi', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const AgroIcon(AppAssets.pottedPlant, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Belum ada rekomendasi',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'AI belum bisa menyarankan tanaman untuk kondisi ini. '
            'Coba lagi atau tambahkan tanamanmu sendiri.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 200,
            child: AgroOutlineButton(label: 'Coba lagi', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}

MapLocation _exampleLocation(String? name) => MockData.locations.firstWhere(
  (loc) => loc.name == name,
  orElse: () => MockData.locations.first,
);

class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.onNext});

  static const String _title = 'Dimana tanaman ini akan tumbuh?';
  static const String _description =
      'Aplikasi memerlukan akses lokasi untuk menganalisis data cuaca lokal, '
      'kelembapan, dan kondisi cahaya matahari yang tepat bagi tanamanmu.';

  static const double _mapHeight = 380;

  static const double _mapTop = 296 - 120;

  static const double _cardTop = 662 - 120;

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AddPlantController>().draft;
    final picked = _exampleLocation(draft.locationName);

    final center = draft.locationPosition ?? picked.position;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: _mapTop,
          left: 0,
          right: 0,
          height: _mapHeight,

          child: AgroMap(center: center, interactive: false),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: const _HeaderCard(
            step: 0,
            title: _title,
            description: _description,
          ),
        ),
        Positioned(
          top: _cardTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            reverse: true,
            child: _LocationConfirmCard(
              name: picked.name,
              address: picked.address,
              onConfirm: () {
                context.read<AddPlantController>().setLocation(
                  picked.name,
                  picked.address,
                  position: center,
                  city: picked.city,
                  province: picked.province,
                );
                onNext();
              },
              onChange: () => _showLocationPicker(context, picked, center),
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationPicker(
    BuildContext context,
    MapLocation current,
    LatLng? point,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) =>
          _LocationPickerSheet(initial: current, initialPoint: point),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.initial, this.initialPoint});

  final MapLocation initial;

  final LatLng? initialPoint;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng _point = widget.initialPoint ?? widget.initial.position;

  late MapLocation? _nearest = _find(_point);

  static const Distance _distance = Distance();

  MapLocation? _find(LatLng point) {
    MapLocation? best;
    var bestMeters = double.infinity;
    for (final loc in MockData.locations) {
      final meters = _distance.as(LengthUnit.Meter, point, loc.position);
      if (meters < bestMeters) {
        best = loc;
        bestMeters = meters;
      }
    }

    return bestMeters <= 2000 ? best : null;
  }

  void _onMoved(LatLng point) {
    setState(() {
      _point = point;
      _nearest = _find(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _nearest?.name ?? 'Titik di peta';
    final detail =
        _nearest?.address ??
        '${_point.latitude.toStringAsFixed(5)}, '
            '${_point.longitude.toStringAsFixed(5)}';

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            child: AgroMap(center: _point, onCenterChanged: _onMoved),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AgroIcon(AppAssets.locationFilled, size: 24),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final loc in MockData.locations)
                  _LocationOption(
                    name: loc.name,
                    address: loc.address,
                    selected: loc == _nearest,
                    onTap: () => setState(() {
                      _point = loc.position;
                      _nearest = loc;
                    }),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AgroButton(
                  label: 'Pilih Lokasi Ini',
                  onPressed: () {
                    final known = _nearest ?? MockData.locations.first;
                    context.read<AddPlantController>().setLocation(
                      label,
                      detail,
                      position: _point,
                      city: known.city,
                      province: known.province,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationConfirmCard extends StatelessWidget {
  const _LocationConfirmCard({
    required this.name,
    required this.address,
    required this.onConfirm,
    required this.onChange,
  });

  final String name;
  final String address;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page - _border,
        AppSpacing.xxl - _border,
        AppSpacing.page - _border,
        AppSpacing.xxxl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AgroIcon(AppAssets.locationFilled, size: 24),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _TrimmedText(
                  text: name,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w700,
                    height: 29 / 20,
                  ),

                  trimAdjust: _capTrimAdjust(20, 29),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TrimmedText(
            text: address,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
            ),

            trimAdjust: _capTrimAdjust(14, 16),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AgroButton(label: 'Konfirmasi Lokasi', onPressed: onConfirm),
          const SizedBox(height: AppSpacing.sm),
          AgroOutlineButton(label: 'Ubah Lokasi', onPressed: onChange),
        ],
      ),
    );
  }

  static double _capTrimAdjust(double fontSize, double lineHeight) {
    const ascent = 2269 / 2048;
    const descent = 660 / 2048;
    const capHeight = 1490 / 2048;
    final halfLeading = (lineHeight - (ascent + descent) * fontSize) / 2;

    final capTop = halfLeading + (ascent - capHeight) * fontSize;

    return capTop -
        (lineHeight - fontSize * (ascent + descent)) / 2 -
        (capHeight * fontSize - fontSize * (ascent + descent)) / 2;
  }
}

class _TrimmedText extends StatelessWidget {
  const _TrimmedText({
    required this.text,
    required this.style,
    required this.trimAdjust,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final double trimAdjust;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -trimAdjust),
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.name,
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const AgroIcon(AppAssets.locationFill, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaStep extends StatelessWidget {
  const _MediaStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
  });

  static const List<(PlantingMedia, String, double, double)> _options = [
    (PlantingMedia.pot, AppAssets.mediaPot, 18, 19.908),
    (PlantingMedia.ground, AppAssets.mediaHouse, 20, 20),
    (PlantingMedia.openField, AppAssets.mediaGround, 20, 19.908),
  ];

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AddPlantController>().draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 1,
          title: 'Pilih Media Tanam',

          description:
              'Pilih di mana Anda akan menanam tanaman ini\n'
              'agar kami dapat memberikan panduan\n'
              'perawatan yang tepat.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              for (final (media, icon, w, h) in _options)
                _OptionCard(
                  icon: icon,
                  iconWidth: w,
                  iconHeight: h,
                  title: media.label,
                  subtitle: media.description,
                  selected: draft.media == media.name,

                  monochrome: true,

                  gap: AppSpacing.xxl,
                  onTap: () =>
                      context.read<AddPlantController>().setMedia(media.name),
                ),
            ],
          ),
        ),
        _StepActions(onBack: onBack, onNext: onNext, enabled: enabled),
      ],
    );
  }
}

class _SoilStep extends StatefulWidget {
  const _SoilStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
    this.openListByDefault = false,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  final bool openListByDefault;

  @override
  State<_SoilStep> createState() => _SoilStepState();
}

class _SoilStepState extends State<_SoilStep> {
  late bool _manual = widget.openListByDefault;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddPlantController>().loadSoilTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final add = context.watch<AddPlantController>();
    final draft = add.draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 2,
          title: 'Analisis tanah',
          description:
              'Pilih di mana Anda akan menanam tanaman ini\n'
              'agar kami dapat memberikan panduan\n'
              'perawatan yang tepat.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xxl,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: _manual
                ? [
                    if (add.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (add.error != null)
                      _LoadError(
                        onRetry: () =>
                            context.read<AddPlantController>().loadSoilTypes(),
                      )
                    else
                      for (final soil in add.soilTypes)
                        _SoilCard(
                          photo: soil.photoAsset,
                          title: soil.name,
                          description: soil.description,
                          selected: draft.soil?.id == soil.id,
                          onTap: () => context
                              .read<AddPlantController>()
                              .selectSoil(soil),
                        ),
                  ]
                : [
                    _BigOptionCard(
                      icon: draft.soilDetected
                          ? AppAssets.soilScanSelected
                          : AppAssets.soilScan,
                      iconSize: 32,
                      title: 'Bantu Saya Scan Tanah',
                      subtitle: 'Gunakan kamera untuk analisis otomatis',
                      selected: draft.soilDetected,
                      onTap: draft.soilDetected
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SoilDetectionScreen(),
                              ),
                            ),
                    ),
                    _BigOptionCard(
                      icon: AppAssets.soilListManual,
                      iconSize: 32,
                      title: 'Saya Tahu Jenis Tanah',
                      subtitle: 'Pilih dari daftar jenis tanah secara manual',
                      selected: false,
                      onTap: () => setState(() => _manual = true),
                    ),
                  ],
          ),
        ),
        _StepActions(
          onBack: _manual
              ? () => setState(() => _manual = false)
              : widget.onBack,
          onNext: widget.onNext,
          enabled: widget.enabled,
        ),
      ],
    );
  }
}

class _SoilCard extends StatelessWidget {
  const _SoilCard({
    required this.photo,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String photo;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg - _border),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0xC7A1D650),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset(
                photo,
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
                    title,
                    style: AppTextStyles.titleLarge.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey,
                      letterSpacing: -0.5,
                      height: 18 / 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 80,
              child: Center(
                child: Opacity(
                  opacity: selected ? 1 : 0,
                  child: const AgroIcon(AppAssets.checkMarkGreen, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationStep extends StatefulWidget {
  const _RecommendationStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;

  @override
  State<_RecommendationStep> createState() => _RecommendationStepState();
}

class _RecommendationStepState extends State<_RecommendationStep> {
  var _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AddPlantController>().loadRecommendations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final add = context.watch<AddPlantController>();
    final draft = add.draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 3,
          title: 'Hasil rekomendasi',

          description: 'Pilihan tanaman terbaik yang sesuai dengan kondisi lingkunganmu.',
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    96,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  children: [
                    if (add.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppSpacing.lg),
                            Text('Menganalisis tanaman…'),
                          ],
                        ),
                      )
                    else if (add.error != null)
                      _LoadError(
                        onRetry: () => context
                            .read<AddPlantController>()
                            .loadRecommendations(),
                      )
                    else ...[
                      if (draft.manualName != null)
                        _OptionCard(
                          icon: AppAssets.pottedPlant,
                          title: draft.manualName!,
                          subtitle: 'Ditambahkan manual',
                          selected: true,
                          onTap: () {},
                        )
                      else if (add.recommendations.isEmpty)
                        _EmptyRecommendations(
                          onRetry: () => context
                              .read<AddPlantController>()
                              .loadRecommendations(),
                        ),
                      for (final r in add.recommendations)
                        _RecommendationCard(
                          recommendation: r,
                          selected: draft.recommendation?.id == r.id,
                          onTap: () => context
                              .read<AddPlantController>()
                              .selectRecommendation(r),
                        ),
                    ],
                  ],
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xxl,
                    AppSpacing.page,
                    AppSpacing.lg,
                  ),
                  child: _ManualAddButton(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const _ManualPlantSheet(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _StepActions(
          onBack: widget.onBack,
          onNext: widget.onNext,
          enabled: widget.enabled,
          nextLabel: add.isLoading ? 'Menganalisis…' : 'Lanjut',
        ),
      ],
    );
  }
}

class _ManualAddButton extends StatelessWidget {
  const _ManualAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.primary),
          boxShadow: AppColors.shadow1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AgroIcon(AppAssets.manualAddCircle, size: 24, height: 26.2),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Tambah manual tanaman',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                height: 24 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.selected,
    required this.onTap,
  });

  final PlantRecommendation recommendation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg - _border),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0xC7A1D650),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: Image.asset(
                    recommendation.photoAsset,
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
                        recommendation.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in recommendation.tags)
                            _RecommendationChip(
                              label: tag,
                              highlighted:
                                  tag == PlantRecommendation.bestForTag,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        recommendation.description,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.grey,
                          height: 18 / 14,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: AppSpacing.lg,
              left: 255 + AppSpacing.md,
              child: Opacity(
                opacity: selected ? 1 : 0,
                child: const AgroIcon(AppAssets.checkMarkGreen, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.careFertilizeSurface
            : AppColors.lightGrey,
        borderRadius: AppRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            const AgroIcon(AppAssets.bestMatchStar, size: 12, height: 12.581),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.bodyCaption.copyWith(
              height: 18 / 12,
              letterSpacing: -0.5,
              color: highlighted ? AppColors.careFertilize : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualPlantSheet extends StatefulWidget {
  const _ManualPlantSheet();

  @override
  State<_ManualPlantSheet> createState() => _ManualPlantSheetState();
}

class _ManualPlantSheetState extends State<_ManualPlantSheet> {
  final _name = TextEditingController();
  final _scientific = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _name.dispose();
    _scientific.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _showValidation = true);
      return;
    }
    context.read<AddPlantController>().setManualPlant(
      _name.text,
      _scientific.text.isEmpty ? null : _scientific.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah manual tanaman', style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          AgroTextField(
            label: 'Nama tanaman',
            hint: 'Contoh: Cabai Rawit',
            controller: _name,
            textInputAction: TextInputAction.next,
            errorText: _showValidation && _name.text.trim().isEmpty
                ? 'Nama tanaman tidak boleh kosong'
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          AgroTextField(
            label: 'Nama ilmiah (opsional)',
            hint: 'Contoh: Capsicum frutescens',
            controller: _scientific,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AgroButton(label: 'Tambah Tanaman', onPressed: _save),
        ],
      ),
    );
  }
}

class _PhaseStep extends StatelessWidget {
  const _PhaseStep({
    required this.onBack,
    required this.onNext,
    required this.enabled,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool enabled;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AddPlantController>().draft;

    return Column(
      children: [
        const _HeaderCard(
          step: 4,
          title: 'Pilih fase pertumbuhan',
          description:
              'Sesuaikan jadwal perawatan berdasarkan usia\n'
              'tanamanmu saat ini.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.xxl,
            ),
            children: [
              for (final phase in GrowthPhase.values)
                _OptionCard(
                  icon: phase.iconAsset,
                  iconWidth: phase.iconWidth,
                  iconHeight: phase.iconHeight,
                  title: phase.label,
                  subtitle: phase.description,
                  selected: draft.phase == phase.name,

                  monochrome: true,
                  gap: 10,
                  onTap: () =>
                      context.read<AddPlantController>().setPhase(phase.name),
                ),
            ],
          ),
        ),
        _StepActions(
          onBack: onBack,
          onNext: onNext,
          enabled: enabled,
          saving: saving,

          nextLabel: 'Lanjut',
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.iconWidth,
    this.iconHeight,
    this.gap = AppSpacing.lg,
    this.monochrome = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  final double? iconWidth;
  final double? iconHeight;

  final bool monochrome;

  final double gap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: gap),
        padding: const EdgeInsets.all(AppSpacing.lg - _border),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0xC7A1D650),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _IconCircle(
              icon: icon,
              width: iconWidth ?? 18,
              height: iconHeight ?? 19.908,
              selected: selected,
              monochrome: monochrome,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(letterSpacing: -1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Opacity(
              opacity: selected ? 1 : 0,
              child: const AgroIcon(AppAssets.checkMarkGreen, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigOptionCard extends StatelessWidget {
  const _BigOptionCard({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl - _border,
          vertical: AppSpacing.xxxl - _border,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x806D9C25),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : AppColors.shadow1,
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AgroIcon(icon, size: iconSize),
            ),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: [
                Text(
                  _capitalize(title),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey,
                    height: 16 / 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.width,
    required this.height,
    required this.selected,
    this.monochrome = false,
  });

  final String icon;
  final double width;
  final double height;
  final bool selected;

  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.lightGrey,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AgroIcon(
        icon,
        size: width,
        height: height,
        color: monochrome
            ? (selected ? AppColors.surface : AppColors.grey)
            : null,
      ),
    );
  }
}
