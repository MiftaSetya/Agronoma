import 'package:flutter/material.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/data/mock_disease_repository.dart';
import 'package:frontend/core/data/mock_weather_repository.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';
import 'package:provider/provider.dart';

/// Seluruh "kabel" aplikasi: repositori disuntikkan sebagai **antarmuka**
/// ([PlantRepository] dkk., bukan kelas mock-nya) sehingga saat backend siap
/// cukup ganti satu baris di sini tanpa menyentuh layar. Parameter repositori
/// dan [initialRoute] juga disediakan agar widget test bisa menyuntikkan data
/// yang pasti dan langsung membuka layar yang diuji.
class AgronomaApp extends StatelessWidget {
  const AgronomaApp({
    super.key,
    this.plantRepository,
    this.addPlantRepository,
    this.weatherRepository,
    this.diseaseRepository,
    this.initialRoute = Routes.splash,
    this.home,
    this.signedInUser,
    this.sampleCamera = false,
    this.authRepository,
    this.useSampleData = false,
  });

  /// Sumber data tanaman; default [MockPlantRepository].
  final PlantRepository? plantRepository;

  /// Sumber data wizard "Tambah Tanaman" (scan tanah, rekomendasi AI, simpan
  /// lewat `POST /plants`). `null` = otomatis: [HttpAddPlantRepository] bila
  /// [useSampleData] `false`, [SampleAddPlantRepository] bila `true`.
  final AddPlantRepository? addPlantRepository;

  /// Sumber data cuaca; default [MockWeatherRepository].
  final WeatherRepository? weatherRepository;

  /// Sumber data diagnosis; default [MockDiseaseRepository].
  final DiseaseRepository? diseaseRepository;

  /// Sumber autentikasi. `null` = otomatis: [HttpAuthRepository] bila
  /// [useSampleData] `false`, [SampleAuthRepository] bila `true`.
  final AuthRepository? authRepository;

  /// Memakai data contoh alih-alih backend.
  ///
  /// `true` saat pratinjau desain & widget test (tanpa server), `false` untuk
  /// aplikasi sungguhan. Saat `false`, [authRepository] boleh diisi sendiri —
  /// dipakai test integrasi yang mengganti [TokenStore] dengan versi memori.
  final bool useSampleData;

  /// Rute pertama yang dibuka. Default splash.
  final String initialRoute;

  /// Layar yang langsung ditampilkan tanpa lewat router; dipakai widget test
  /// dan `lib/dev_preview.dart`. Di produksi biarkan `null` agar
  /// [initialRoute] yang berlaku.
  final Widget? home;

  /// Pengguna awal. Bila diisi, sesi langsung dianggap sudah masuk.
  ///
  /// Dipakai `lib/dev_preview.dart` supaya Home dan Profile bisa dipotret
  /// dengan data yang benar tanpa melewati layar Login — kalau tidak, kedua
  /// layar itu hanya menampilkan nilai kosong.
  final AppUser? signedInUser;

  /// Memaksa layar kamera memakai foto contoh alih-alih pratinjau langsung.
  ///
  /// Dinyalakan pipeline tangkapan layar: frame Figma menggambar sebuah foto,
  /// jadi membandingkan pikselnya dengan pratinjau kamera sungguhan tidak akan
  /// pernah masuk akal.
  final bool sampleCamera;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Sumber data — tukar di sini saat backend siap.
        Provider<PlantRepository>(
          create: (_) => plantRepository ?? MockPlantRepository(),
        ),
        Provider<WeatherRepository>(
          create: (_) => weatherRepository ?? const MockWeatherRepository(),
        ),
        Provider<DiseaseRepository>(
          create: (_) => diseaseRepository ?? const MockDiseaseRepository(),
        ),

        // Autentikasi: backend sungguhan, atau contoh saat [useSampleData].
        // `TokenStore` disuntikkan ke `ApiClient` supaya test bisa memakai
        // penyimpanan dalam memori.
        Provider<TokenStore>(
          create: (_) =>
              useSampleData ? InMemoryTokenStore() : const SecureTokenStore(),
        ),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(tokenStore: ctx.read<TokenStore>()),
        ),
        // Sumber data wizard "Tambah Tanaman". Didaftarkan **sesudah**
        // [ApiClient] karena `Provider` hanya bisa membaca provider yang
        // dituliskan lebih dulu.
        Provider<AddPlantRepository>(
          create: (ctx) =>
              addPlantRepository ??
              (useSampleData
                  ? SampleAddPlantRepository()
                  : HttpAddPlantRepository(apiClient: ctx.read<ApiClient>())),
        ),
        Provider<AuthRepository>(
          create: (ctx) =>
              authRepository ??
              (useSampleData
                  ? SampleAuthRepository()
                  : HttpAuthRepository(
                      apiClient: ctx.read<ApiClient>(),
                      tokenStore: ctx.read<TokenStore>(),
                    )),
        ),

        // Controller didaftarkan di root supaya state-nya tidak hilang saat
        // berpindah halaman: sesi login, daftar tanaman, draft wizard, dan
        // percakapan bot.
        ChangeNotifierProvider(
          create: (ctx) => AuthController(
            authSource: ctx.read<AuthRepository>(),
            initialUser: signedInUser,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PlantController(
            plantRepository: ctx.read<PlantRepository>(),
            weatherSource: ctx.read<WeatherRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              AddPlantController(dataSource: ctx.read<AddPlantRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              ChatController(detector: ctx.read<DiseaseRepository>()),
        ),
      ],
      child: CameraScope(
        sampleOnly: sampleCamera,
        child: MaterialApp(
          title: 'Agronoma',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          // Kanvas Figma memakai status bar setinggi 64px (iPhone 16 Pro Max),
          // sedangkan Android lebih pendek — inset-nya diseragamkan sekali di
          // sini agar setiap layar tidak meleset ke atas. Lihat
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
          // `home` dan `initialRoute` tidak boleh dua-duanya menentukan layar
          // pertama: kalau `home` diisi, rute awal dibiarkan null karena
          // `onGenerateRoute` tidak akan sempat dipanggil.
          home: home,
          initialRoute: home == null ? initialRoute : null,
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    );
  }
}
