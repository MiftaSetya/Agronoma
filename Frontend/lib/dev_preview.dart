import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/app.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/widgets/main_shell.dart';
import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';
import 'package:frontend/features/disease/disease_detection_screen.dart';
import 'package:frontend/features/plant_detail/ai_chatbot_screen.dart';
import 'package:frontend/features/plant_detail/plant_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final route = await _setting('ROUTE', 'debug.agronoma.rute');
  final step = int.tryParse(await _setting('STEP', 'debug.agronoma.langkah'));

  final liveCamera =
      await _setting('KAMERA', 'debug.agronoma.kamera') == 'asli';

  runApp(
    AgronomaApp(
      signedInUser: MockData.user,
      home: _previewFor(
        route.isEmpty ? Routes.login : route,
        (step ?? 0).clamp(0, 5),
      ),
      sampleCamera: !liveCamera,

      useSampleData: true,
    ),
  );
}

Future<String> _setting(String define, String property) async {
  try {
    final result = await Process.run('getprop', [property]);
    final value = '${result.stdout}'.trim();
    if (value.isNotEmpty) return value;
  } on ProcessException catch (_) {
    return _dartDefine(define);
  }
  return _dartDefine(define);
}

String _dartDefine(String define) => switch (define) {
  'ROUTE' => const String.fromEnvironment('ROUTE'),
  'STEP' => '${const int.fromEnvironment('STEP')}',
  'KAMERA' => const String.fromEnvironment('KAMERA'),
  _ => '',
};

Widget _previewFor(String route, int step) {
  switch (route) {
    case Routes.login:
      return const LoginScreen();
    case Routes.register:
      return const RegisterScreen();
    case Routes.home:
      return const MainShell();
    case Routes.profile:
      return const MainShell(initialIndex: 1);
    case Routes.plantDetail:
      return PlantDetailScreen(plantId: '', initialTab: step);
    case Routes.plantChat:
      return const PlantChatScreen();
    case Routes.addPlant:
      return _AddPlantPreview(step: step);
    case Routes.diseaseDetection:
      return DiseaseDetectionScreen(
        initialResult: step == 1 ? MockData.disease : null,
      );
    case Routes.soilDetection:
      return const SoilDetectionScreen();
    default:
      throw ArgumentError.value(route, 'route', 'Rute preview tidak dikenal');
  }
}

class _AddPlantPreview extends StatelessWidget {
  const _AddPlantPreview({required this.step});

  final int step;

  static const int _soilListStep = 5;

  @override
  Widget build(BuildContext context) {
    final soilListOpen = step == _soilListStep;
    final flowStep = soilListOpen ? 2 : step;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final add = context.read<AddPlantController>();
        switch (flowStep) {
          case 1:
            add.setMedia(PlantingMedia.pot.name);
          case 2:
            if (soilListOpen) {
              add.selectSoil(MockData.soilTypes[1]);
            } else {
              add.markSoilDetected();
            }
        }
      });
    });
    return AddPlantFlow(initialStep: flowStep, soilListOpen: soilListOpen);
  }
}
