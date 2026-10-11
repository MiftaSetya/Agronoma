import 'package:flutter/material.dart';

import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';
import 'package:frontend/features/disease/disease_detection_screen.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/features/plant_detail/ai_chatbot_screen.dart';
import 'package:frontend/features/plant_detail/plant_detail_screen.dart';
import 'package:frontend/features/profile/profile_screen.dart';
import 'package:frontend/features/splash/splash_screen.dart';

/// Nama rute terpusat.
///
/// Design memakai istilah alur yang berbeda-beda (Splash, Login, Register,
/// Home, Profile, Add Plant 1..5, Plant Detail, Disease Detection). Semua
/// dikumpulkan di sini supaya tidak ada string rute yang ditulis lepas di
/// dalam widget, dan supaya setiap tujuan splash bisa diganti dari satu tempat.
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
  static const diseaseDetection = '/disease-detection';
}

/// Argumen untuk [Routes.plantDetail] dan [Routes.plantChat].
class PlantDetailArgs {
  const PlantDetailArgs({required this.plantId, this.initialTab = 0});

  final String plantId;

  /// 0 = Ringkasan, 1 = Perawatan.
  final int initialTab;
}

/// Membangun halaman dari nama rute.
///
/// Dipakai `MaterialApp.onGenerateRoute`, jadi seluruh peta rute ada di satu
/// berkas dan `main.dart` tetap tipis.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.splash:
      return _page(const SplashScreen(next: LoginScreen()), settings);

    case Routes.login:
      return _page(const LoginScreen(), settings);

    case Routes.register:
      return _page(const RegisterScreen(), settings);

    case Routes.home:
      return _page(const HomeScreen(), settings);

    case Routes.profile:
      return _page(const ProfileScreen(), settings);

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

    case Routes.diseaseDetection:
      return _page(const DiseaseDetectionScreen(), settings);

    default:
      return _page(const LoginScreen(), settings);
  }
}

/// Halaman biasa dengan transisi geser dari kanan (khas iOS/Android).
PageRoute<T> _page<T>(Widget child, RouteSettings settings) =>
    MaterialPageRoute<T>(builder: (_) => child, settings: settings);
