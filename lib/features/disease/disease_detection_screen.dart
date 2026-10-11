import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/disease.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Layar Plant Disease Detection — frame `Plant Disease Detection`
/// (node `106:1124`) beserta hasilnya pada `Plant Disease Detection Result`
/// (node `176:1219`) yang memakai `Disease Drawer` (node `253:2575`).
///
/// Di design ada dua frame terpisah; di sini keduanya digabung dalam satu layar
/// karena alurnya berurutan: arahkan kamera → analisis → hasil muncul sebagai
/// panel yang naik dari bawah.
///
/// **Tata letak memakai koordinat design.**
/// Seluruh layar digambar pada kanvas 440x956 dan isinya diposisikan dengan
/// `Positioned` memakai angka yang sama seperti Figma (bingkai bidik di
/// (92, 299), tombol bawah di baris 734, dan seterusnya). Cara ini dipilih
/// ketimbang menyusun `Column`/`Row`: pada layar kamera hampir semua elemen
/// mengambang di atas foto dengan jarak yang tidak berhubungan satu sama lain,
/// jadi menyusunnya secara relatif justru menambah banyak angka tambahan yang
/// harus dijaga tetap sama dengan design.
///
/// **Catatan implementasi:** plugin `camera` belum dipasang (lihat catatan di
/// akhir berkas), jadi yang ditampilkan adalah foto contoh — bukan aliran
/// kamera sungguhan — dan hasil diagnosis diambil dari
/// [MockDiseaseRepository].
class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key, this.initialResult});

  /// Hasil yang langsung ditampilkan (mode kamera dilewati).
  ///
  /// Dipakai preview pengembangan untuk memotret panel hasil tanpa menekan
  /// tombol rana lebih dulu. Di aplikasi biasa biarkan `null`.
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
            // Posisi diambil dari design: panel mulai di baris 341 dan
            // tingginya 623, jadi 8px bawahnya memang melewati kanvas.
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

/// Satu bingkai kamera lengkap: foto, dua gradasi, top bar, bingkai bidik,
/// pil petunjuk, dan tiga kontrol bawah.
///
/// Dipakai ulang oleh tampilan hasil karena di design (`176:1219`) bingkai
/// kamera tetap tergambar di belakang panel hasil.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.analyzing, required this.onCapture});

  final bool analyzing;
  final VoidCallback onCapture;

  /// Lebar foto pada design: simpulnya 539px, tetapi gambarnya sendiri
  /// digambar 115,08% dari lebar simpul itu.
  static const double _photoWidth = 539 * 1.1508;
  static const double _photoHeight = 958;

  /// Geser kiri foto pada design: `left-[-50px]` ditambah `left-[-11,69%]`.
  static const double _photoLeft = -50 + 539 * (-0.1169);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto latar. Karena plugin kamera belum dipasang, ini foto contoh —
        // bukan aliran kamera sungguhan. Tanpa efek peredup tambahan: design
        // hanya memakai dua gradasi di bawah ini untuk menjaga teks tetap
        // terbaca.
        Positioned(
          left: _photoLeft,
          top: 0,
          width: _photoWidth,
          height: _photoHeight,
          child: Image.asset(AppAssets.photoPlantDetection, fit: BoxFit.fill),
        ),

        // Gradasi atas: gelap 90% di baris 0, 60% di tengah, hilang di baris
        // 170. Arahnya dibalik oleh design (`-rotate-180 -scale-x-100`), jadi
        // bagian paling gelap ada di atas.
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

        // Gradasi bawah: hilang di baris 734, 60% di tengah, 90% di bawah.
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

/// Top bar kamera: silang di kiri, judul di tengah, ruang kosong 24px di kanan.
///
/// Sisi kanan memang **kosong** di design: simpul `arrow container` ada, tetapi
/// gambarnya ditulis dengan `opacity="0"`. Menaruh panah di sana (seperti yang
/// sempat dilakukan) menambah satu ikon yang tidak pernah terlihat di design.
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

/// Silang `close-line` pada ukuran aslinya.
///
/// Berkas SVG-nya hanya 14,7x19,2 sedangkan simpul di design 24x24; isinya
/// diletakkan lewat `inset` 19,37% kiri-kanan dan 0,78% bawah. Ukuran dan
/// inset itu ditulis ulang di sini supaya silangnya persis sebesar design —
/// kalau SVG-nya hanya "dipasang di kotak 24", isinya ikut membesar.
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
  /// Garis pemindai naik-turun di dalam bingkai, sesuai animasi
  /// "Scanning animation line" pada design.
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
        // Garis pemindai bergerak dari atas ke bawah bingkai.
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

/// Pil petunjuk di bawah bingkai bidik.
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

/// Pil yang muncul saat analisis berjalan — menggantikan teks petunjuk.
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
      // Design memakai p-[17px]/p-[9px] dengan border 1px; karena border
      // Flutter dihitung di luar padding (design menghitungnya di dalam),
      // angkanya dikurangi satu.
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
    // Ukuran isinya berbeda antara galeri (20x20) dan kilat (18x22,8); angka
    // itu diambil dari design supaya ikon tidak ikut membesar.
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

/// Panel hasil diagnosis — `Disease Drawer` (node `253:2575`).
///
/// Di design panel ini tingginya 623px dan menempel di baris 341, dengan radius
/// atas 32. Isinya: gagang, nama penyakit + pil akurasi, garis pemisah, judul
/// "TINDAKAN SEGERA DIBUTUHKAN", lalu tiga langkah penanganan berbentuk garis
/// waktu.
///
/// Dibuat publik supaya bisa dipakai ulang oleh drawer "Disease Drawer"
/// (node `253:2575`) yang isinya sama.
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
          // `px-[24px] pb-[24px]` pada design.
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

/// Gagang panel — garis abu 32x4 di tengah kanvas.
///
/// Gagang ini sekaligus **satu-satunya** cara menutup panel. Di design tidak
/// ada tombol tutup di dalam panel; yang ada hanya gagang dan judul "TINDAKAN
/// SEGERA DIBUTUHKAN" yang mengisyaratkan isinya bisa digulir. Karena itu
/// menutup dilakukan dengan menarik gagangnya ke bawah, bukan dengan menambah
/// tombol yang akan menggeser seluruh isi panel dari design.
class _DrawerHandle extends StatefulWidget {
  const _DrawerHandle({this.onDismiss});

  /// Dipanggil saat gagang ditarik ke bawah cukup jauh.
  final VoidCallback? onDismiss;

  @override
  State<_DrawerHandle> createState() => _DrawerHandleState();
}

class _DrawerHandleState extends State<_DrawerHandle> {
  /// Jarak tarikan yang sudah dianggap "sengaja" (px).
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
        // Di design (`close` 440x24) garisnya digambar di baris 16..20, bukan
        // di tengah kotak. Memusatkannya membuat gagangnya naik 6px.
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
      // `px-[8px] py-[6px]` dengan border 0px, jadi padding-nya dipakai apa
      // adanya.
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
        // Garis penghubung: `left-[16px] top-[24px] bottom-[24px]` pada design,
        // jadi tepat di tengah nomor bulat (16 = 32/2).
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
            // Design memakai `p-[17px]`; dikurangi satu karena border Flutter
            // dihitung di luar padding.
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

// ───────────────────────────────────────────────────────────────────────────
// Catatan: kenapa layar ini belum memakai kamera sungguhan
// ───────────────────────────────────────────────────────────────────────────
//
// Plugin `camera` sengaja belum dipasang. Alasannya:
//
// 1. **Izin & hak akses.** Menambahkan plugin kamera berarti menambah entri
//    `AndroidManifest.xml` dan `Info.plist`. Repo ini belum punya jalur uji
//    untuk kedua platform itu, jadi izinnya tidak bisa diverifikasi.
// 2. **Belum ada backend.** Hasil deteksi sekarang datang dari
//    [MockDiseaseRepository], jadi gambar dari kamera tidak akan dikirim ke
//    mana pun. Menyalakan kamera sungguhan hanya menambah biaya tanpa manfaat.
// 3. **Tampilannya sudah pasti.** Yang perlu dicocokkan dengan design adalah
//    tata letaknya — bingkai bidik, pil petunjuk, dan kontrol bawah. Ketiganya
//    tidak berubah saat sumber gambarnya berganti.
//
// Saat plugin dipasang, yang berubah hanya sumber gambar di [_CameraFrame]:
// [`Image.asset(AppAssets.photoPlantDetection)`] diganti dengan pratinjau
// `CameraPreview`, dan tombol rana memanggil `takePicture()` lalu mengirim
// hasilnya ke `ChatController.diagnose(imagePath: …)`. Sisa layar, termasuk
// panel hasilnya, tidak perlu disentuh.
