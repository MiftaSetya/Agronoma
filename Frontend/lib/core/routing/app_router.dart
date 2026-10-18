import 'package:flutter/material.dart';

import 'package:frontend/core/widgets/main_shell.dart';
import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';
import 'package:frontend/features/auth/session_gate.dart';
import 'package:frontend/features/disease/disease_detection_screen.dart';
import 'package:frontend/features/plant_detail/ai_chatbot_screen.dart';
import 'package:frontend/features/plant_detail/plant_detail_screen.dart';
import 'package:frontend/features/splash/splash_screen.dart';

class Routes {
  Routes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  static const home = '/home';

  static const profile = '/profile';

  static const plantDetail = '/plant-detail';
  static const plantChat = '/plant-chat';
  static const addPlant = '/add-plant';
  static const soilDetection = '/soil-detection';
  static const diseaseDetection = '/disease-detection';
}

class PlantDetailArgs {
  const PlantDetailArgs({required this.plantId, this.initialTab = 0});

  final String plantId;

  final int initialTab;
}

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.splash:
      return _page(const SplashScreen(next: SessionGate()), settings);

    case Routes.login:
      return _page(const LoginScreen(), settings);

    case Routes.register:
      return _page(const RegisterScreen(), settings);

    case Routes.home:
      return _page(const MainShell(), settings);

    case Routes.profile:
      return _page(const MainShell(initialIndex: 1), settings);

    case Routes.plantDetail:
      final args = settings.arguments as PlantDetailArgs?;
      return _page(
        PlantDetailScreen(
          plantId: args?.plantId ?? '',
          initialTab: args?.initialTab ?? 0,
        ),
        settings,
      );

    case Routes.plantChat:
      final args = settings.arguments as PlantDetailArgs?;
      return _page(PlantChatScreen(plantId: args?.plantId), settings);

    case Routes.addPlant:
      return _page(const AddPlantFlow(), settings);

    case Routes.soilDetection:
      return _page(const SoilDetectionScreen(), settings);

    case Routes.diseaseDetection:
      final args = settings.arguments;
      return _page(
        DiseaseDetectionScreen(
          plantId: args is String && args.isNotEmpty ? args : null,
        ),
        settings,
      );

    default:
      return _page(const LoginScreen(), settings);
  }
}

PageRoute<T> _page<T>(Widget child, RouteSettings settings) =>
    MaterialPageRoute<T>(builder: (_) => child, settings: settings);
