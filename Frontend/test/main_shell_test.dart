import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/data/mock_data.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/plant.dart';
import 'package:frontend/core/models/weather.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/app_shell.dart';
import 'package:frontend/core/widgets/main_shell.dart';

/// Repository tiruan: Beranda memuat daftar tanaman lewat antarmuka ini.
class _FakePlantRepository implements PlantRepository {
  @override
  Future<List<Plant>> getPlants() async => MockData.plants;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<Weather> current(String city) async => MockData.weather;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  Future<void> pumpShell(WidgetTester tester, {int initialIndex = 0}) async {
    // Kanvas 440x956 seperti design; layar uji bawaan membuat tombol keluar.
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(
            create: (_) => AuthController(
              authSource: SampleAuthRepository(),
              initialUser: MockData.user,
            ),
          ),
          ChangeNotifierProvider<PlantController>(
            create: (_) => PlantController(
              plantRepository: _FakePlantRepository(),
              weatherSource: _FakeWeatherRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MainShell(initialIndex: initialIndex),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan Beranda, lalu Profil setelah tab ditekan', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('Tanaman Saya'), findsOneWidget);
    expect(find.text('PREFERENSI'), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('PREFERENSI'), findsOneWidget);
    expect(find.text('Tanaman Saya'), findsNothing);
  });

  testWidgets('tab yang ditinggalkan tetap hidup, tidak dibangun ulang', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    // Isi Profil masih ada di tree (offstage) — kalau `PageView` membuangnya,
    // sakelar dan posisi gulirnya akan tereset tiap kali berpindah.
    expect(find.text('PREFERENSI', skipOffstage: false), findsOneWidget);
    expect(find.text('Tanaman Saya'), findsOneWidget);
  });

  testWidgets('MainShell yang dibuka dari tab Profil langsung ke Profil', (
    tester,
  ) async {
    await pumpShell(tester, initialIndex: 1);

    expect(find.text('PREFERENSI'), findsOneWidget);
    expect(find.text('Tanaman Saya'), findsNothing);
  });

  testWidgets('menu FAB hanya berisi dua aksi, tanpa baris "Tutup"', (
    tester,
  ) async {
    // Kanvas bawaan (800x600) dipakai apa adanya: font uji Ahem membuat teks
    // jauh lebih lebar dari aslinya, sehingga kanvas 440 akan melaporkan
    // overflow palsu pada label "Diagnosis penyakit tanaman".
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAgroFabMenu(context),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah tanaman'), findsOneWidget);
    expect(find.text('Diagnosis penyakit tanaman'), findsOneWidget);
    // Sheet sudah bisa ditutup lewat gagang geser / ketukan di luar; baris
    // "Tutup" dari design sengaja dibuang supaya tidak ada aksi mubazir.
    expect(find.text('Tutup'), findsNothing);
  });
}
