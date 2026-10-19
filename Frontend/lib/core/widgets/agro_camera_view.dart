import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

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

  final String title;

  final String instruction;

  final String analyzingLabel;

  final String fallbackAsset;

  final Rect? photoBox;

  final bool analyzing;

  final ValueChanged<String?> onCapture;

  static const Rect _defaultPhotoBox = Rect.fromLTWH(-50, 0, 539, 958);

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

  bool _settled = false;

  bool _capturing = false;

  FlashMode _flash = FlashMode.off;

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
      _flash = FlashMode.off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_live) _livePreview(_controller!) else _samplePhoto(),

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

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 223 + bottomInset,
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
          bottom: 166 + bottomInset,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_problem != null) ...[
                  _NoticePill(text: _problem!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _busy
                    ? _AnalyzingPill(label: widget.analyzingLabel)
                    : _InstructionPill(text: widget.instruction),
              ],
            ),
          ),
        ),

        Positioned(
          left: 48,
          right: 48,
          bottom: 70.5 + bottomInset,
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

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.asset, this.onTap, this.active = false});

  final String asset;
  final VoidCallback? onTap;

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
