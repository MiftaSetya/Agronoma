import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/disease.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Layar Plant Disease Detection (node `106:1124`) dengan panel hasil (frame
/// `176:1219`, drawer `253:2575`) yang digabung dalam satu layar. Tata letak
/// memakai koordinat design pada kanvas 440x956 supaya angka Figma bisa
/// dipakai apa adanya.
///
/// Kamera asli sengaja belum dipasang (butuh izin platform dan belum ada
/// backend — hasil diagnosis dari [MockDiseaseRepository]), jadi bingkainya
/// menampilkan foto contoh dari aset; saat plugin `camera` terpasang, yang
/// berubah hanya sumber gambar di [_CameraFrame] dan aksi tombol rana.
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

  Future<void> _capture() async {
    setState(() => _analyzing = true);
    final chat = context.read<ChatController>();
    try {
      final disease = await chat.diagnose(imagePath: null);
      if (!mounted) return;
      setState(() => _result = disease);
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
          _CameraFrame(analyzing: _analyzing, onCapture: _capture),
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

/// Bingkai kamera lengkap (foto, gradasi, top bar, bidik, kontrol) — dipakai
/// ulang di tampilan hasil karena bingkai tetap tergambar di belakang panel
/// hasil (design `176:1219`).
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.analyzing, required this.onCapture});

  final bool analyzing;
  final VoidCallback onCapture;

  /// Lebar foto pada design: simpulnya 539px tetapi gambarnya digambar
  /// 115,08% dari lebar simpul itu.
  static const double _photoWidth = 539 * 1.1508;
  static const double _photoHeight = 958;

  /// `left-[-50px]` ditambah `left-[-11,69%]` pada design.
  static const double _photoLeft = -50 + 539 * (-0.1169);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto latar (aset contoh, bukan kamera sungguhan — lihat header
        // kelas). Tanpa peredup tambahan: cukup dua gradasi di bawah.
        Positioned(
          left: _photoLeft,
          top: 0,
          width: _photoWidth,
          height: _photoHeight,
          child: Image.asset(AppAssets.photoPlantDetection, fit: BoxFit.fill),
        ),

        // Gradasi atas: arahnya dibalik oleh design (`-rotate-180
        // -scale-x-100`), jadi bagian paling gelap ada di atas.
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 170,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE6000000),
                  Color(0x99000000),
                  Color(0x00000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Gradasi bawah.
        const Positioned(
          left: 0,
          right: 0,
          top: 734,
          height: 223,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x99000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        const Positioned(
          left: 0,
          right: 0,
          top: 64,
          height: AppSizes.topBarHeight,
          child: _CameraTopBar(),
        ),

        const Positioned(
          left: 92,
          top: 299,
          width: 256,
          height: 256,
          child: _Reticle(),
        ),

        Positioned(
          left: 0,
          right: 0,
          top: 587,
          child: Center(
            child: analyzing
                ? const _AnalyzingPill()
                : const _InstructionPill(),
          ),
        ),

        Positioned(
          left: 48,
          right: 48,
          top: 734,
          height: 223,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _RoundButton(asset: AppAssets.galleryFill),
                _ShutterButton(analyzing: analyzing, onTap: onCapture),
                const _RoundButton(asset: AppAssets.flashFill),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Top bar kamera: silang di kiri, judul di tengah. Sisi kanan memang kosong
/// di design — simpul `arrow container` ada tetapi gambarnya `opacity="0"`.
class _CameraTopBar extends StatelessWidget {
  const _CameraTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const _CloseGlyph(),
          ),
          Text(
            'Deteksi Penyakit',
            style: AppTextStyles.headlineMediumOnDark,
          ),
          const SizedBox(width: 24, height: 24),
        ],
      ),
    );
  }
}

/// Silang `close-line` pada ukuran aslinya. SVG-nya hanya 14,7x19,2 sedangkan
/// simpul di design 24x24; kalau SVG dipasang di kotak 24 utuh, isinya ikut
/// membesar — makanya ukurannya ditulis eksplisit dengan inset.
class _CloseGlyph extends StatelessWidget {
  const _CloseGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Padding(
        padding: EdgeInsets.only(
          left: 4.62,
          right: 4.68,
          top: 4.65,
          bottom: 0.19,
        ),
        child: AgroIconTinted(
          AppAssets.closeLine,
          size: 14.728,
          height: 19.1657,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

/// Bingkai bidik: empat siku sudut + garis pemindai.
class _Reticle extends StatefulWidget {
  const _Reticle();

  @override
  State<_Reticle> createState() => _ReticleState();
}

class _ReticleState extends State<_Reticle>
    with SingleTickerProviderStateMixin {
  /// Garis pemindai naik-turun, sesuai "Scanning animation line" pada design.
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Empat siku sudut, bukan kotak penuh: menutup seluruh sisi akan
        // memotong pandangan ke objek di dalam bingkai.
        const _Corner(alignment: Alignment.topLeft, top: true, left: true),
        const _Corner(alignment: Alignment.topRight, top: true, left: false),
        const _Corner(alignment: Alignment.bottomLeft, top: false, left: true),
        const _Corner(
          alignment: Alignment.bottomRight,
          top: false,
          left: false,
        ),
        AnimatedBuilder(
          animation: _scan,
          builder: (context, _) => Positioned(
            left: 0,
            right: 0,
            top: _scan.value * (256 - 4),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFA1E834),
                borderRadius: AppRadius.chipAll,
                boxShadow: const [
                  BoxShadow(color: Color(0xFFA8E64A), blurRadius: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Satu siku sudut bingkai bidik (30x30, garis 4px, radius 12).
class _Corner extends StatelessWidget {
  const _Corner({
    required this.alignment,
    required this.top,
    required this.left,
  });

  final Alignment alignment;
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Color(0x80FFFFFF), width: 4);
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(12) : Radius.zero,
            topRight: top && !left ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

/// Pil petunjuk di bawah bingkai bidik (penggantinya saat analisis: [_AnalyzingPill]).
class _InstructionPill extends StatelessWidget {
  const _InstructionPill();

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AgroIcon(
            AppAssets.infoFill,
            size: 20,
            height: 21.814,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Arahkan kamera ke tanaman atau daun',
            style: AppTextStyles.tagline.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Pil yang muncul saat analisis berjalan.
class _AnalyzingPill extends StatelessWidget {
  const _AnalyzingPill();

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Menganalisis daun…',
            style: AppTextStyles.tagline.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Kotak pil kaca: latar hitam 60%, border putih 10%, radius penuh.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding dikurangi 1px dari design (p-[17px]/p-[9px] + border 1px)
      // karena border Flutter dihitung di luar padding, design di dalam.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: AppRadius.chipAll,
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }
}

/// Tombol bulat kecil di kiri/kanan rana (48x48, radius 12, kaca buram).
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final isGallery = asset == AppAssets.galleryFill;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0x33E1E3E4),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      alignment: Alignment.center,
      child: isGallery
          ? const AgroIcon(AppAssets.galleryFill, size: 20)
          : const AgroIcon(
              AppAssets.flashFill,
              size: 17.9993,
              height: 22.8167,
            ),
    );
  }
}

/// Tombol rana: cincin 80px dengan isi putih 70px.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.analyzing, required this.onTap});

  final bool analyzing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: analyzing ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x33FFFFFF),
          border: Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: analyzing ? AppColors.grey : AppColors.onPrimary,
          ),
        ),
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

// Catatan kamera: plugin `camera` sengaja belum dipasang — butuh izin
// Android/iOS yang belum bisa diverifikasi, dan belum ada backend untuk gambar.
// Saat dipasang: ganti `Image.asset(AppAssets.photoPlantDetection)` di
// [_CameraFrame] dengan `CameraPreview`, lalu tombol rana memanggil
// `takePicture()` dan mengirimnya ke `ChatController.diagnose(imagePath: …)`.
