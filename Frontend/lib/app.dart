import 'package:flutter/material.dart';

import 'package:frontend/core/data/add_plant_repository.dart';
import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/http_disease_repository.dart';
import 'package:frontend/core/data/api/http_plant_repository.dart';
import 'package:frontend/core/data/api/http_weather_repository.dart';
import 'package:frontend/core/data/api/token_store.dart';
import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/data/chat_repository.dart';
import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/data/mock_disease_repository.dart';
import 'package:frontend/core/data/mock_weather_repository.dart';
import 'package:frontend/core/data/notification_repository.dart';
import 'package:frontend/core/data/plant_repository.dart';
import 'package:frontend/core/data/weather_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/add_plant_controller.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/state/notification_controller.dart';
import 'package:frontend/core/state/plant_controller.dart';
import 'package:frontend/core/state/session_expiry.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_camera_view.dart';
import 'package:provider/provider.dart';

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

  final PlantRepository? plantRepository;

  final AddPlantRepository? addPlantRepository;

  final WeatherRepository? weatherRepository;

  final DiseaseRepository? diseaseRepository;

  final AuthRepository? authRepository;

  final bool useSampleData;

  final String initialRoute;

  final Widget? home;

  final AppUser? signedInUser;

  final bool sampleCamera;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStore>(
          create: (_) =>
              useSampleData ? InMemoryTokenStore() : const SecureTokenStore(),
        ),
        ChangeNotifierProvider<SessionExpiry>(create: (_) => SessionExpiry()),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(
            tokenStore: ctx.read<TokenStore>(),
            sessionExpiry: ctx.read<SessionExpiry>(),
          ),
        ),

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

        Provider<DiseaseRepository>(
          create: (ctx) =>
              diseaseRepository ??
              (useSampleData
                  ? const MockDiseaseRepository()
                  : HttpDiseaseRepository(apiClient: ctx.read<ApiClient>())),
        ),

        Provider<ChatRepository>(
          create: (ctx) =>
              useSampleData
                  ? SampleChatRepository()
                  : HttpChatRepository(apiClient: ctx.read<ApiClient>()),
        ),

        Provider<NotificationRepository>(
          create: (ctx) =>
              useSampleData
                  ? SampleNotificationRepository()
                  : HttpNotificationRepository(
                      apiClient: ctx.read<ApiClient>(),
                    ),
        ),

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
          create: (ctx) => ChatController(
            chatSource: ctx.read<ChatRepository>(),
            detector: ctx.read<DiseaseRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NotificationController(
            ctx.read<NotificationRepository>(),
          ),
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
    context.read<NotificationController>().reset();
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
