import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/disease.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Layar Plant Disease Detection (node `106:1124`) dengan panel hasil (frame
/// `176:1219`, drawer `253:2575`) yang digabung dalam satu layar. Tata letak
/// memakai koordinat design pada kanvas 440x956 supaya angka Figma bisa
/// dipakai apa adanya.
///
/// Bingkai kameranya adalah kamera sungguhan lewat [AgroCameraView]. Yang masih
/// contoh adalah **hasil diagnosisnya**, karena mengenali penyakit dari foto
/// butuh model/backend — foto jepretan tetap dikirim sebagai `imagePath` supaya
/// tinggal disambungkan saat backend tersedia.
class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key, this.initialResult});

  /// Hasil yang langsung ditampilkan (mode kamera dilewati); dipakai preview
  /// pengembangan. Di aplikasi biasa biarkan `null`.
  final Disease? initialResult;

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  Disease? _result;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  Future<void> _capture(String? imagePath) async {
    setState(() => _analyzing = true);
    final chat = context.read<ChatController>();
    try {
      final disease = await chat.diagnose(imagePath: imagePath);
      if (!mounted) return;
      setState(() => _result = disease);
    } catch (_) {
      if (!mounted) return;
      // Kegagalan analisis tidak boleh muncul sebagai layar galat; pengguna
      // diberi tahu dan bisa menekan rana lagi.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menganalisis gambar. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _reset() => setState(() => _result = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bingkai kamera selalu ada di belakang; panel hasil hanya menutupi
          // bagian bawahnya, sama seperti design.
          AgroCameraView(
            title: 'Deteksi Penyakit',
            instruction: 'Arahkan kamera ke tanaman atau daun',
            analyzingLabel: 'Menganalisis daun…',
            fallbackAsset: AppAssets.photoPlantDetection,
            photoBox: AgroCameraView.photoBoxDisease,
            analyzing: _analyzing,
            onCapture: _capture,
          ),
          if (_result != null)
            Positioned(
              left: 0,
              right: 0,
              top: 341,
              height: DiseaseResultDrawer.height,
              child: DiseaseResultDrawer(disease: _result!, onRetake: _reset),
            ),
        ],
      ),
    );
  }
}

/// Panel hasil diagnosis — `Disease Drawer` (node `253:2575`), tinggi 623px di
/// baris 341 dengan radius atas 32. Dibuat publik agar bisa dipakai ulang.
class DiseaseResultDrawer extends StatelessWidget {
  const DiseaseResultDrawer({
    super.key,
    required this.disease,
    this.onRetake,
  });

  /// Tinggi panel pada design.
  static const double height = 623;

  final Disease disease;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetLarge),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerHandle(onDismiss: onRetake),
              const SizedBox(height: AppSpacing.xxl),
              _DrawerHeader(disease: disease),
              const SizedBox(height: AppSpacing.xxl),
              const Divider(color: AppColors.borderStrong),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'TINDAKAN SEGERA DIBUTUHKAN',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: SingleChildScrollView(
                  child: _TreatmentTimeline(steps: disease.steps),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gagang panel — garis abu 32x4 di tengah kanvas. Ini **satu-satunya** cara
/// menutup panel (di design tidak ada tombol tutup); menambahkan tombol akan
/// menggeser seluruh isi panel dari design.
class _DrawerHandle extends StatefulWidget {
  const _DrawerHandle({this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  State<_DrawerHandle> createState() => _DrawerHandleState();
}

class _DrawerHandleState extends State<_DrawerHandle> {
  /// Jarak tarikan minimal agar dianggap "sengaja" (px).
  static const double _threshold = 24;

  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dragged = 0,
      onVerticalDragUpdate: (details) {
        _dragged += details.delta.dy;
      },
      onVerticalDragEnd: (_) {
        if (_dragged >= _threshold) widget.onDismiss?.call();
        _dragged = 0;
      },
      child: const SizedBox(
        height: 24,
        // Di design garisnya di baris 16..20, bukan di tengah kotak —
        // memusatkannya membuat gagang naik 6px.
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: 32,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: AppRadius.chipAll,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nama penyakit + pil akurasi.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.disease});

  final Disease disease;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AgroIcon(
                    AppAssets.warningFill,
                    size: 13.3333,
                    height: 14.5427,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Penyakit terdeteksi',
                    style: AppTextStyles.bodyCaption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              Text(disease.name, style: AppTextStyles.headlineSmall),
              Text(
                disease.scientificName,
                style: AppTextStyles.titleWide.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _AccuracyPill(label: '${disease.confidenceLabel} Cocok'),
      ],
    );
  }
}

/// Pil akurasi hijau di kanan nama penyakit.
class _AccuracyPill extends StatelessWidget {
  const _AccuracyPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AgroIcon(AppAssets.checkCircleSolid, size: 15),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primarySurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis waktu langkah penanganan: nomor bulat 32px di kiri, kartu di kanan,
/// dengan satu garis penghubung di belakang nomornya.
class _TreatmentTimeline extends StatelessWidget {
  const _TreatmentTimeline({required this.steps});

  final List<DiseaseStep> steps;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Garis penghubung tepat di tengah nomor bulat (16 = 32/2).
        Positioned(
          left: 16,
          top: 24,
          bottom: 24,
          child: Container(width: 2, color: AppColors.lightGrey),
        ),
        Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _TreatmentStep(number: i + 1, step: steps[i]),
              if (i < steps.length - 1) const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ],
    );
  }
}

class _TreatmentStep extends StatelessWidget {
  const _TreatmentStep({required this.number, required this.step});

  final int number;
  final DiseaseStep step;

  @override
  Widget build(BuildContext context) {
    final first = number == 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: first ? AppColors.primary : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.bodyLarge.copyWith(
              color: first ? AppColors.onPrimary : AppColors.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.14,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Container(
            // Padding dikurangi 1px dari design (p-[17px]) karena border
            // Flutter dihitung di luar padding.
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.lightGrey),
              boxShadow: AppColors.shadow1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(step.detail, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
