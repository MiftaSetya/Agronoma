import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/api/api_exception.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';

class SoilDetectionScreen extends StatefulWidget {
  const SoilDetectionScreen({super.key});

  @override
  State<SoilDetectionScreen> createState() => _SoilDetectionScreenState();
}

class _SoilDetectionScreenState extends State<SoilDetectionScreen> {
  bool _analyzing = false;

  Future<void> _capture(String? imagePath) async {
    setState(() => _analyzing = true);
    final result = await context.read<AddPlantController>().scanSoil(
      imagePath: imagePath,
    );
    if (!mounted) return;
    setState(() => _analyzing = false);

    if (result == null) {
      final error = context.read<AddPlantController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Gagal menganalisis tanah. Coba lagi.',
          ),
        ),
      );
      return;
    }

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
