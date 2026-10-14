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

/// Titik masuk khusus pengembangan — **bukan** bagian aplikasi (tidak pernah
/// dipanggil `main.dart`, jadi tidak ikut ke build rilis). Gunanya memotret
/// satu layar langsung tanpa menavigasi dari splash, misalnya saat
/// mencocokkan hasil render dengan frame Figma.
///
/// Layar ditentukan lewat properti sistem Android (satu APK untuk semua
/// layar, tanpa build ulang):
///
/// ```sh
/// adb shell setprop debug.agronoma.rute /home
/// adb shell setprop debug.agronoma.langkah 2
/// adb shell am start -n com.agronoma.frontend/.MainActivity
/// ```
///
/// `debug.agronoma.langkah` mengisi keadaan awal: langkah wizard `/add-plant`
/// (0..4, dan 5 = langkah 3 dengan daftar tanah terbuka), tab `/plant-detail`
/// (0 Ringkasan / 1 Perawatan), atau keadaan `/disease-detection` (0 kamera /
/// 1 panel hasil). Alternatif saat kompilasi:
/// `--dart-define=ROUTE=/add-plant --dart-define=STEP=2`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final route = await _setting('ROUTE', 'debug.agronoma.rute');
  final step = int.tryParse(await _setting('STEP', 'debug.agronoma.langkah'));
  // `debug.agronoma.kamera asli` melepas mode contoh supaya bingkai kamera bisa
  // diuji dengan pratinjau sungguhan; nilai lain (termasuk kosong) tetap mode
  // contoh demi tangkapan layar yang deterministik.
  final liveCamera = await _setting('KAMERA', 'debug.agronoma.kamera') == 'asli';

  runApp(
    AgronomaApp(
      // Sesi langsung diisi supaya Home dan Profile menampilkan data seperti
      // setelah login (kalau tidak, keduanya hanya menampilkan nilai kosong).
      signedInUser: MockData.user,
      home: _previewFor(
        route.isEmpty ? Routes.login : route,
        (step ?? 0).clamp(0, 5),
      ),
      sampleCamera: !liveCamera,
    ),
  );
}

/// Membaca pengaturan dari `--dart-define`, lalu dari properti sistem Android;
/// keduanya kosong berarti kembalian string kosong.
Future<String> _setting(String define, String property) async {
  // Properti sistem hanya ada di Android; di platform lain `getprop` gagal
  // dan `--dart-define` yang dipakai.
  try {
    final result = await Process.run('getprop', [property]);
    final value = '${result.stdout}'.trim();
    if (value.isNotEmpty) return value;
  } on ProcessException {
    // Bukan Android — jatuh ke `--dart-define`.
  }
  return switch (define) {
    'ROUTE' => const String.fromEnvironment('ROUTE'),
    'STEP' => '${const int.fromEnvironment('STEP')}',
    'KAMERA' => const String.fromEnvironment('KAMERA'),
    _ => '',
  };
}

/// Memetakan nama rute menjadi layar, lengkap dengan argumen contoh.
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

/// Wizard dengan isian yang sudah disemai agar tangkapan layarnya bisa
/// dibandingkan dengan design (yang memotret wizard dalam keadaan terisi:
/// langkah 2 sudah memilih "Pot tanaman", langkah 3 sudah menganalisis tanah).
///
/// Penyemaiannya lewat post-frame callback karena controller dipakai
/// `AddPlantFlow` sendiri di frame pertama.
class _AddPlantPreview extends StatelessWidget {
  const _AddPlantPreview({required this.step});

  final int step;

  /// `step == 5` bukan langkah keenam wizard, melainkan keadaan langkah 3
  /// dengan daftar "Saya Tahu Jenis Tanah" sudah terbuka (frame `113:765`);
  /// design memotret kedua keadaan itu sebagai dua frame berbeda.
  static const int _soilListStep = 5;

  @override
  Widget build(BuildContext context) {
    final soilListOpen = step == _soilListStep;
    final flowStep = soilListOpen ? 2 : step;
    // Semai hanya sekali per build; controller reset() sendiri di post-frame
    // pertama milik AddPlantFlow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Post-frame kedua: callback yang didaftarkan saat build berjalan
      // sebelum initState() AddPlantFlow mendaftarkan reset() miliknya, jadi
      // menyemai di frame pertama justru langsung dihapus reset(). Menyemai di
      // frame kedua menjamin urutannya benar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final add = context.read<AddPlantController>();
        switch (flowStep) {
          case 1:
            add.setMedia(PlantingMedia.pot.name);
          case 2:
            // Design memotret langkah 3 dalam dua keadaan: kartu besar dengan
            // tanah sudah dianalisis (88:361), dan daftar manual dengan "Tanah
            // gembur" terpilih (113:765).
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
