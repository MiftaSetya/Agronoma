import 'package:flutter/material.dart';

import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/data/mock_disease_repository.dart';
import 'package:frontend/core/data/mock_weather_repository.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:provider/provider.dart';
///
/// Di sinilah seluruh "kabel" aplikasi disambungkan: repositori mana yang
/// dipakai, controller mana yang hidup sepanjang sesi, dan rute awal.
///
/// Yang perlu diperhatikan: repositori disuntikkan sebagai **antarmuka**
/// ([PlantRepository], [WeatherRepository], [DiseaseRepository]), bukan sebagai
/// kelas mock-nya. Jadi saat backend Agronoma sudah ada, cukup ganti satu baris
/// di sini (`MockPlantRepository()` → `HttpPlantRepository(baseUrl: …)`) tanpa
/// menyentuh satu pun layar.
///
/// Ketiga parameter repositori dan [initialRoute] disediakan supaya widget test
/// bisa menyuntikkan data yang pasti dan langsung membuka layar yang diuji.
class AgronomaApp extends StatelessWidget {
  const AgronomaApp({
    super.key,
    this.plantRepository,
    this.weatherRepository,
    this.diseaseRepository,
    this.initialRoute = Routes.splash,
    this.home,
  });

  /// Sumber data tanaman; default [MockPlantRepository].
  final PlantRepository? plantRepository;

  /// Sumber data cuaca; default [MockWeatherRepository].
  final WeatherRepository? weatherRepository;

  /// Sumber data diagnosis; default [MockDiseaseRepository].
  final DiseaseRepository? diseaseRepository;

  /// Rute pertama yang dibuka. Default splash.
  final String initialRoute;

  /// Layar yang langsung ditampilkan tanpa lewat router.
  ///
  /// Dipakai widget test dan `tool/dev_preview.dart` supaya bisa membuka layar
  /// mana pun (termasuk langkah wizard tertentu) tanpa menavigasi dari splash.
  /// Di produksi biarkan `null` agar [initialRoute] yang berlaku.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Sumber data (tukar di sini saat backend siap) ──────────────────
        Provider<PlantRepository>(
          create: (_) => plantRepository ?? MockPlantRepository(),
        ),
        Provider<WeatherRepository>(
          create: (_) => weatherRepository ?? const MockWeatherRepository(),
        ),
        Provider<DiseaseRepository>(
          create: (_) => diseaseRepository ?? const MockDiseaseRepository(),
        ),

        // ── Controller ─────────────────────────────────────────────────────
        // Semua didaftarkan di root supaya state-nya tidak hilang saat berpindah
        // halaman: sesi login, daftar tanaman, draft wizard, dan percakapan bot.
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(
          create: (ctx) => PlantController(
            plantRepository: ctx.read<PlantRepository>(),
            weatherSource: ctx.read<WeatherRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AddPlantController(
            dataSource: ctx.read<PlantRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ChatController(
            detector: ctx.read<DiseaseRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Agronoma',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Seluruh layar digambar pada kanvas Figma yang memakai status bar
        // setinggi 64px (iPhone 16 Pro Max). Android memakai status bar yang
        // lebih pendek, jadi inset-nya diseragamkan sekali di sini; kalau tidak,
        // setiap layar akan meleset ke atas dengan jumlah yang sama. Lihat
        // [AppSizes.normalizeTopInset].
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(
                top: AppSizes.normalizeTopInset(context),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        // `home` dan `initialRoute` tidak boleh sama-sama menentukan layar
        // pertama, jadi salah satu dimatikan: kalau ada `home`, rute awal
        // dibiarkan default ('/') dan `onGenerateRoute` tidak sempat dipanggil.
        home: home,
        initialRoute: home == null ? initialRoute : null,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}
