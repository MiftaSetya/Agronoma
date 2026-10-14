import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';

/// Layar kamera "Deteksi Jenis Tanah" pada langkah 3 wizard (frame `101:701`).
///
/// Bingkainya sama persis dengan layar deteksi penyakit — keduanya memakai
/// [AgroCameraView] — hanya judul dan teks petunjuknya yang berbeda.
///
/// **Kamera sungguhan**; yang masih contoh adalah *hasil analisisnya*, karena
/// mengklasifikasi jenis tanah dari foto butuh model/backend (lihat
/// `docs/testing.md`). Foto hasil jepretan tetap disimpan di draft supaya siap
/// dikirim saat backend tersedia.
class SoilDetectionScreen extends StatefulWidget {
  const SoilDetectionScreen({
    super.key,
    this.analysisDelay = const Duration(milliseconds: 1400),
  });

  /// Jeda "menganalisis" sebelum hasil dikembalikan; dinolkan oleh uji agar
  /// tidak perlu menunggu.
  final Duration analysisDelay;

  @override
  State<SoilDetectionScreen> createState() => _SoilDetectionScreenState();
}

class _SoilDetectionScreenState extends State<SoilDetectionScreen> {
  bool _analyzing = false;

  Future<void> _capture(String? imagePath) async {
    setState(() => _analyzing = true);
    // Di sini nanti panggilan backend: kirim [imagePath], terima jenis tanahnya.
    await Future<void>.delayed(widget.analysisDelay);
    if (!mounted) return;
    context.read<AddPlantController>().markSoilDetected(photoPath: imagePath);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AgroCameraView(
        title: 'Deteksi Jenis Tanah',
        instruction: 'Arahkan kamera ke permukaan tanah',
        analyzingLabel: 'Menganalisis tanah…',
        fallbackAsset: AppAssets.photoPotSoil,
        analyzing: _analyzing,
        onCapture: _capture,
      ),
    );
  }
}
