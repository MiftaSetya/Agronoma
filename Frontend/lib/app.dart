import 'package:flutter/material.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/http_disease_repository.dart';
import 'package:frontend/core/data/api/http_plant_repository.dart';
import 'package:frontend/core/data/api/http_weather_repository.dart';
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
import 'package:frontend/core/state/session_expiry.dart';
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
        // Autentikasi: backend sungguhan, atau contoh saat [useSampleData].
        // `TokenStore` disuntikkan ke `ApiClient` supaya test bisa memakai
        // penyimpanan dalam memori.
        Provider<TokenStore>(
          create: (_) =>
              useSampleData ? InMemoryTokenStore() : const SecureTokenStore(),
        ),
        ChangeNotifierProvider<SessionExpiry>(
          create: (_) => SessionExpiry(),
        ),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(
            tokenStore: ctx.read<TokenStore>(),
            sessionExpiry: ctx.read<SessionExpiry>(),
          ),
        ),

        // Sumber data yang membaca backend. Didaftarkan **sesudah** [ApiClient]
        // karena `Provider` hanya bisa membaca provider yang ditulis lebih dulu.
        // Cuaca ikut lewat backend (`GET /plants/{id}/weather`) dan bukan lagi
        // satu kota tetap, karena tanaman pengguna bisa berada di banyak lokasi.
        Provider<PlantRepository>(
          create: (ctx) =>
              plantRepository ??
              (useSampleData
                  ? MockPlantRepository()
                  : HttpPlantRepository(apiClient: ctx.read<ApiClient>())),
        ),
        Provider<WeatherRepository>(
          create: (ctx) =>
              weatherRepository ??
              (useSampleData
                  ? const MockWeatherRepository()
                  : HttpWeatherRepository(apiClient: ctx.read<ApiClient>())),
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

        // Deteksi penyakit butuh [ApiClient] (multipart ke `POST /pest-scans`),
        // jadi didaftarkan sesudahnya. Mode contoh tetap memakai hasil contoh.
        Provider<DiseaseRepository>(
          create: (ctx) =>
              diseaseRepository ??
              (useSampleData
                  ? const MockDiseaseRepository()
                  : HttpDiseaseRepository(apiClient: ctx.read<ApiClient>())),
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
      child: _SessionResetGate(
        sampleCamera: sampleCamera,
        home: home,
        initialRoute: initialRoute,
      ),
    );
  }
}

/// Menjaga agar data satu sesi tidak tertinggal ke sesi berikutnya.
///
/// Dua jalan keluar yang harus sama-sama membersihkan:
///
/// 1. pengguna menekan "Keluar" ([AuthController.signOut]);
/// 2. server menolak token yang tersimpan (401), ditandai [SessionExpiry] oleh
///    [ApiClient].
///
/// Tanpa ini daftar tanaman, cuaca, kalender, dan percakapan milik pengguna
/// sebelumnya tetap ada di memori — pengguna berikutnya melihat tanaman orang
/// lain sampai aplikasi ditutup paksa.
class _SessionResetGate extends StatefulWidget {
  const _SessionResetGate({
    required this.sampleCamera,
    required this.home,
    required this.initialRoute,
  });

  final bool sampleCamera;
  final Widget? home;
  final String initialRoute;

  @override
  State<_SessionResetGate> createState() => _SessionResetGateState();
}

class _SessionResetGateState extends State<_SessionResetGate> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  AuthController? _auth;
  SessionExpiry? _expiry;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    final expiry = context.read<SessionExpiry>();
    if (identical(_auth, auth) && identical(_expiry, expiry)) return;

    _auth?.removeListener(_onAuthChanged);
    _expiry?.removeListener(_onExpired);

    _auth = auth..addListener(_onAuthChanged);
    _expiry = expiry..addListener(_onExpired);
    _signedIn = auth.isSignedIn;

    if (expiry.expired) _onExpired();
  }

  void _onAuthChanged() {
    final auth = _auth;
    if (auth == null) return;

    final signedIn = auth.isSignedIn;
    if (signedIn == _signedIn) return;

    if (!signedIn) _clearSessionData();
    _signedIn = signedIn;
  }

  void _onExpired() {
    _auth?.clearLocalSession();
    _clearSessionData();

    final expiry = _expiry;
    if (expiry != null && expiry.expired) {
      expiry.acknowledge();
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.login,
        (route) => false,
      );
    }
  }

  void _clearSessionData() {
    context.read<PlantController>().reset();
    context.read<ChatController>().reset();
    context.read<AddPlantController>().reset();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    _expiry?.removeListener(_onExpired);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraScope(
      sampleOnly: widget.sampleCamera,
      child: MaterialApp(
        title: 'Agronoma',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light,
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
        home: widget.home,
        initialRoute: widget.home == null ? widget.initialRoute : null,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}
