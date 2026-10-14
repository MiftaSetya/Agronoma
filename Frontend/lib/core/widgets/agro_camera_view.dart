import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

/// Saklar mode kamera yang diwariskan ke seluruh pohon widget.
///
/// `sampleOnly` memaksa setiap [AgroCameraView] menampilkan foto contoh alih-alih
/// pratinjau kamera. Dipakai pipeline tangkapan layar (`lib/dev_preview.dart`
/// dipanggil `tool/shots-all.ps1`): frame Figma menggambar sebuah foto, sedangkan
/// pratinjau kamera sungguhan tidak akan pernah sama dengan foto itu — tanpa
/// saklar ini perbandingan piksel layar kamera jadi tidak ada artinya.
class CameraScope extends InheritedWidget {
  const CameraScope({
    super.key,
    required this.sampleOnly,
    required super.child,
  });

  final bool sampleOnly;

  static bool sampleOnlyOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CameraScope>()?.sampleOnly ??
      false;

  @override
  bool updateShouldNotify(CameraScope oldWidget) =>
      oldWidget.sampleOnly != sampleOnly;
}

/// Bingkai kamera layar penuh, dipakai dua layar: "Plant Disease Detection"
/// (frame `106:1124`) dan "Add Plant 3 - Detect Soil" (frame `101:701`).
///
/// Kedua frame memakai **kerangka yang sama** — pil petunjuk di baris 587,
/// kontrol di baris 734, top bar di baris 64 — jadi seluruh tata letaknya hidup
/// di sini dan tiap layar cukup mengirim judul, teks petunjuk, serta geometri
/// fotonya ([photoBox]) karena kedua design menggambar foto dengan ukuran
/// berbeda.
///
/// Bingkai bidik tengah (siku `92,299 256x256` + garis pemindai) dari design
/// **sengaja tidak digambar** — pemilik proyek memintanya dihilangkan.
///
/// Yang ditampilkan adalah **kamera sungguhan** (`camera`). Bila perangkat tidak
/// punya kamera, izinnya ditolak, atau [CameraScope.sampleOnly] aktif, bingkai
/// jatuh ke [fallbackAsset] supaya layar tetap berguna dan pipeline tangkapan
/// layar tetap deterministik.
class AgroCameraView extends StatefulWidget {
  const AgroCameraView({
    super.key,
    required this.title,
    required this.instruction,
    required this.analyzingLabel,
    required this.fallbackAsset,
    required this.analyzing,
    required this.onCapture,
    this.photoBox,
  });

  /// Judul di top bar.
  final String title;

  /// Teks pil petunjuk di bawah tengah bingkai.
  final String instruction;

  /// Teks pil selagi [analyzing].
  final String analyzingLabel;

  /// Foto latar saat kamera tidak dipakai.
  final String fallbackAsset;

  /// Geometri kotak foto latar **di luar kanvas 440x956** (boleh di luar tepi,
  /// seperti design yang menaruh fotonya lebih lebar dari frame). `null` berarti
  /// [_defaultPhotoBox].
  ///
  /// Perlu berbeda per layar: frame `101:701` (tanah) menggambar foto tepat pada
  /// simpulnya (`-50,0 539x958`, terukur selisih 1.9), sedangkan `106:1124`
  /// (penyakit) memperbesar fotonya ke `-113,0 620x958` (terukur selisih 3.5).
  final Rect? photoBox;

  /// Analisis sedang berjalan (dikendalikan layar pemilik).
  final bool analyzing;

  /// Dipanggil saat rana ditekan. [imagePath] berisi berkas hasil jepretan,
  /// atau `null` bila kamera tidak tersedia sehingga mode contoh yang dipakai.
  final ValueChanged<String?> onCapture;

  /// Geometri bawaan = geometri frame `101:701` (Deteksi Tanah): foto tepat
  /// pada simpul `left-[-50px] w-[539px] h-[958px]`.
  static const Rect _defaultPhotoBox = Rect.fromLTWH(-50, 0, 539, 958);

  /// Geometri frame `106:1124` (Deteksi Penyakit): simpulnya tetap `-50,0
  /// 539x958` tetapi gambarnya digambar 115,08% dengan `left-[-11,69%]`.
  static const Rect photoBoxDisease = Rect.fromLTWH(
    -50 + 539 * -0.1169,
    0,
    539 * 1.1508,
    958,
  );

  @override
  State<AgroCameraView> createState() => _AgroCameraViewState();
}

class _AgroCameraViewState extends State<AgroCameraView>
    with WidgetsBindingObserver {
  CameraController? _controller;

  /// Pengaturan awal sudah dibaca (kamera mulai / mode contoh ditetapkan).
  bool _settled = false;

  /// Rana sedang menjepret (sebelum layar memulai analisisnya).
  bool _capturing = false;

  FlashMode _flash = FlashMode.off;

  /// Alasan kamera tidak dipakai; `null` berarti pratinjau langsung tampil.
  /// Diisi hanya untuk kegagalan sungguhan (bukan mode contoh).
  String? _problem;

  bool get _busy => _capturing || widget.analyzing;
  bool get _live => _controller?.value.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settled) return;
    _settled = true;
    // Mode contoh sengaja tidak menyentuh plugin sama sekali supaya tangkapan
    // layar tidak bergantung pada ada/tidaknya kamera di perangkat itu.
    if (CameraScope.sampleOnlyOf(context)) {
      _problem = null;
      return;
    }
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sejak camera 0.5.0 plugin tidak lagi mengurus siklus hidup sendiri; kalau
    // kamera dibiarkan hidup saat aplikasi ke latar, banyak perangkat gagal
    // melanjutkan pratinjau ketika kembali.
    if (!_live) return;
    if (state == AppLifecycleState.inactive) {
      _release();
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() => _problem = 'Perangkat ini tidak punya kamera.');
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        // Tidak ada rekaman video di sini, dan meminta izin mikrofon hanya
        // menambah dialog izin yang tidak perlu dipakai.
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _problem = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _problem = switch (e.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' => 'Izin kamera ditolak.',
          _ => 'Kamera tidak bisa dibuka.',
        };
      });
    } on MissingPluginException {
      // Terjadi di widget test: tidak ada implementasi platform.
      if (!mounted) return;
      setState(() => _problem = 'Kamera tidak tersedia.');
    }
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      widget.onCapture(null);
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      widget.onCapture(file.path);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil gambar. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flash == FlashMode.torch ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flash = next);
    } on CameraException {
      // Kamera tanpa lampu: biarkan mode apa adanya tanpa mengganggu pengguna.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_live) _livePreview(_controller!) else _samplePhoto(),

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

        Positioned(
          left: 0,
          right: 0,
          top: 64,
          height: AppSizes.topBarHeight,
          child: _TopBar(title: widget.title),
        ),

        Positioned(
          left: 0,
          right: 0,
          top: 587,
          child: Center(
            child: _busy
                ? _AnalyzingPill(label: widget.analyzingLabel)
                : _InstructionPill(text: widget.instruction),
          ),
        ),

        if (_problem != null)
          Positioned(
            left: 0,
            right: 0,
            top: 641,
            child: Center(child: _NoticePill(text: _problem!)),
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
                _ShutterButton(busy: _busy, onTap: _shoot),
                _RoundButton(
                  asset: AppAssets.flashFill,
                  active: _flash == FlashMode.torch,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Pratinjau langsung diperbesar sampai menutup seluruh layar (cover).
  ///
  /// `previewSize` dilaporkan dalam orientasi lanskap di Android, jadi lebarnya
  /// ditukar dengan tinggi dulu; tanpa itu pratinjau tampil membujur ke samping.
  Widget _livePreview(CameraController controller) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.shrink();
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  /// Latar pengganti: foto contoh dengan geometri design layar pemilik.
  Widget _samplePhoto() {
    final box = widget.photoBox ?? AgroCameraView._defaultPhotoBox;
    return Positioned(
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: Image.asset(widget.fallbackAsset, fit: BoxFit.fill),
    );
  }
}

/// Top bar kamera: silang di kiri, judul di tengah. Sisi kanan memang kosong
/// di design — simpul `arrow container` ada tetapi gambarnya `opacity="0"`.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

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
          // `Flexible` tidak mengubah posisi selama teks muat (lebar
          // intrinsiknya dipakai apa adanya); gunanya supaya judul panjang atau
          // skala huruf besar tidak membuat baris meluber.
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.headlineMediumOnDark,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

/// Pil petunjuk di bawah tengah bingkai.
class _InstructionPill extends StatelessWidget {
  const _InstructionPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AgroIcon(AppAssets.infoFill, size: 20, height: 21.814),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.tagline.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pil yang muncul saat analisis berjalan.
class _AnalyzingPill extends StatelessWidget {
  const _AnalyzingPill({required this.label});

  final String label;

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
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.tagline.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemberitahuan kenapa kamera tidak dipakai (izin ditolak / tanpa kamera).
/// Tidak pernah tampil di mode contoh, jadi tidak mengganggu tangkapan layar.
class _NoticePill extends StatelessWidget {
  const _NoticePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AgroIcon(AppAssets.warningFill, size: 14.5427, height: 13.3333),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.tagline.copyWith(color: AppColors.onPrimary),
            ),
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
  const _RoundButton({required this.asset, this.onTap, this.active = false});

  final String asset;
  final VoidCallback? onTap;

  /// Keadaan "menyala" (mis. lampu kilat sedang hidup).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isGallery = asset == AppAssets.galleryFill;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            : AgroIcon(
                AppAssets.flashFill,
                size: 17.9993,
                height: 22.8167,
                color: active ? AppColors.primaryLight : null,
              ),
      ),
    );
  }
}

/// Tombol rana: cincin 80px dengan isi putih 70px.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
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
            color: busy ? AppColors.grey : AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}
