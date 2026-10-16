import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/soil_catalog.dart';
import 'package:frontend/core/models/soil_type.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';
import 'package:frontend/features/add_plant/soil_detection_screen.dart';

/// Uji layar kamera "Deteksi Jenis Tanah" (frame `101:701`).
///
/// Kamera platform tidak tersedia di widget test, jadi yang diuji di sini
/// adalah **mode contoh** ([CameraScope.sampleOnly]): foto design dipakai dan
/// plugin tidak pernah disentuh. Perilaku kamera sungguhan diverifikasi di
/// emulator (lihat `docs/testing.md`).
class _FakeRepository implements AddPlantRepository {
  /// Dipanggil saat rana ditekan; disimpan supaya uji bisa memastikan foto
  /// jepretan memang diteruskan ke repositori (mode contoh: null).
  String? lastImagePath;

  @override
  Future<SoilScanResult> scanSoil({String? imagePath}) async {
    lastImagePath = imagePath;
    return SoilScanResult(soil: SoilCatalog.types[1], confidence: 0.9);
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  /// Kanvas design 440x956 supaya koordinat rana bisa dipakai apa adanya.
  void useDesignSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Transisi rute diselesaikan dengan `pump` berdurasi tetap supaya tidak
  /// bergantung pada ada/tidaknya animasi berulang di layar kamera.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Widget wrap(Widget child, {AddPlantController? controller}) =>
      ChangeNotifierProvider<AddPlantController>(
        create: (_) =>
            controller ?? AddPlantController(dataSource: _FakeRepository()),
        child: CameraScope(
          sampleOnly: true,
          child: MaterialApp(theme: AppTheme.light, home: child),
        ),
      );

  testWidgets('mode contoh memakai foto design, bukan kamera platform', (
    tester,
  ) async {
    useDesignSize(tester);
    await tester.pumpWidget(wrap(const SoilDetectionScreen()));
    await tester.pump();

    // Tanpa implementasi plugin, memanggil kamera akan melempar
    // MissingPluginException — kalau foto ini muncul, plugin memang dilewati.
    expect(find.image(const AssetImage(AppAssets.photoPotSoil)), findsOneWidget);
    expect(find.text('Deteksi Jenis Tanah'), findsOneWidget);
    expect(find.text('Arahkan kamera ke permukaan tanah'), findsOneWidget);
  });

  testWidgets('tanpa saklar contoh, bingkai tetap tampil walau kamera gagal', (
    tester,
  ) async {
    useDesignSize(tester);
    // Tanpa CameraScope: plugin tidak ada di widget test, jadi AgroCameraView
    // mencatat kegagalannya dan tetap menggambar foto contoh.
    await tester.pumpWidget(
      ChangeNotifierProvider<AddPlantController>(
        create: (_) => AddPlantController(dataSource: _FakeRepository()),
        child: const MaterialApp(home: SoilDetectionScreen()),
      ),
    );
    await settleRoute(tester);

    expect(find.byType(AgroCameraView), findsOneWidget);
    expect(find.text('Deteksi Jenis Tanah'), findsOneWidget);
    expect(find.image(const AssetImage(AppAssets.photoPotSoil)), findsOneWidget);
  });

  testWidgets('menekan rana menandai tanah terdeteksi lalu menutup layar', (
    tester,
  ) async {
    useDesignSize(tester);
    final repository = _FakeRepository();
    final controller = AddPlantController(dataSource: repository);

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SoilDetectionScreen(),
                  ),
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
        controller: controller,
      ),
    );

    await tester.tap(find.text('buka'));
    await settleRoute(tester);
    expect(controller.draft.soilDetected, isFalse);

    // Rana bundar 80px di tengah baris kontrol (baris 734, tinggi 223).
    await tester.tapAt(const Offset(220, 845.5));
    await tester.pump(); // ganti ke keadaan "menganalisis"
    await settleRoute(tester); // analisis selesai → jenis tanah tersimpan → pop

    expect(controller.draft.soilDetected, isTrue);
    expect(controller.draft.soil, SoilCatalog.types[1]);
    // Mode contoh tidak punya berkas jepretan, jadi jalurnya null — tetapi
    // jalurnya tetap diteruskan supaya backend bisa dikirimi foto saat kamera
    // sungguhan yang menjepret.
    expect(repository.lastImagePath, isNull);
    expect(controller.draft.soilPhotoPath, isNull);
    // Layar sudah ditutup, kembali ke tombol pembuka.
    expect(find.text('buka'), findsOneWidget);
  });
}
