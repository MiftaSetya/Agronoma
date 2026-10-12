import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/app.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/features/add_plant/add_plant_flow.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/register_screen.dart';
import 'package:frontend/features/disease/disease_detection_screen.dart';
import 'package:frontend/features/home/home_screen.dart';
import 'package:frontend/features/plant_detail/ai_chatbot_screen.dart';
import 'package:frontend/features/plant_detail/plant_detail_screen.dart';
import 'package:frontend/features/profile/profile_screen.dart';

/// Titik masuk khusus pengembangan — **bukan** bagian aplikasi.
///
/// Gunanya memotret satu layar langsung tanpa menavigasi dari splash, misalnya
/// saat mencocokkan hasil render dengan frame Figma (`tool/shot.ps1`).
///
/// Rute bisa ditentukan dengan dua cara:
///
/// 1. Saat kompilasi — praktis kalau hanya menguji satu layar:
///    ```sh
///    flutter run -t lib/dev_preview.dart --dart-define=ROUTE=/add-plant
///    ```
/// 2. Saat jalan — lewat properti sistem Android, jadi satu APK cukup untuk
///    semua layar dan tidak perlu build ulang tiap ganti layar:
///    ```sh
///    adb shell setprop debug.agronoma.rute /home
///    adb shell am start -n com.agronoma.frontend/.MainActivity
///    ```
///
/// `debug.agronoma.langkah` mengisi langkah awal untuk layar yang punya
/// beberapa keadaan:
///
/// | Layar | Langkah | Arti |
/// |---|---|---|
/// | `/add-plant` | 0..4 | langkah wizard |
/// | `/plant-detail` | 0 / 1 | tab Ringkasan / Perawatan |
/// | `/disease-detection` | 0 / 1 | kamera / panel hasil |
///
/// Berkas ini tidak pernah dipanggil `main.dart`, jadi tidak ikut ke aplikasi
/// rilis: `flutter build` hanya mengompilasi kode yang terjangkau dari entry
/// point yang dipakai.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final route = await _setting('ROUTE', 'debug.agronoma.rute');
  final step = int.tryParse(await _setting('STEP', 'debug.agronoma.langkah'));

  runApp(
    AgronomaApp(
      // Sesi langsung diisi supaya Home dan Profile menampilkan data seperti
      // setelah login — kalau tidak, keduanya hanya menampilkan nilai kosong
      // dan tidak ada gunanya dibandingkan dengan design.
      signedInUser: MockData.user,
      home: _previewFor(
        route.isEmpty ? Routes.login : route,
        (step ?? 0).clamp(0, 4),
      ),
    ),
  );
}

/// Membaca pengaturan dari `--dart-define`, lalu dari properti sistem Android.
///
/// Properti sistem memberi keuntungan besar saat mencocokkan layar dengan
/// design: satu APK bisa membuka layar mana pun, jadi tidak perlu build ulang
/// setiap kali pindah layar.
///
/// Bila keduanya kosong, kembaliannya string kosong.
Future<String> _setting(String define, String property) async {
  // Properti sistem hanya ada di Android; di platform lain [Process.run] gagal
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
    _ => '',
  };
}

/// Memetakan nama rute menjadi layar, lengkap dengan argumen contoh.
///
/// Bila nanti ada layar baru, cukup tambahkan satu `case` di sini.
Widget _previewFor(String route, int step) {
  switch (route) {
    case Routes.login:
      return const LoginScreen();
    case Routes.register:
      return const RegisterScreen();
    case Routes.home:
      return const HomeScreen();
    case Routes.profile:
      return const ProfileScreen();
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
    default:
      throw ArgumentError.value(route, 'route', 'Rute preview tidak dikenal');
  }
}

/// Wizard dengan isian yang sudah disemai.
///
/// Design memotret wizard dalam keadaan yang sudah terisi: langkah 2 sudah
/// memilih "Pot tanaman" dan langkah 3 sudah menganalisis tanah lewat kamera.
/// Tanpa penyemaian, tangkapan langkah itu memperlihatkan kartu-kartu kosong
/// sehingga tidak bisa dibandingkan dengan referensinya.
///
/// Penyemaiannya lewat post-frame callback: controller dipakai `AddPlantFlow`
/// sendiri di frame pertama, jadi mengubah draft harus menunggu frame itu
/// selesai.
class _AddPlantPreview extends StatelessWidget {
  const _AddPlantPreview({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    // Semai hanya sekali per build; controller reset() sendiri di post-frame
    // pertama milik AddPlantFlow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final add = context.read<AddPlantController>();
      switch (step) {
        case 1:
          add.setMedia(PlantingMedia.pot.name);
        case 2:
          add.markSoilDetected();
      }
    });
    return AddPlantFlow(initialStep: step);
  }
}
