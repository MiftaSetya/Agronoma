import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/data/auth_repository.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/features/auth/login_screen.dart';
import 'package:frontend/features/auth/session_gate.dart';

void main() {
  Widget wrap(AuthController auth) =>
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SessionGate(),
          onGenerateRoute: (settings) {
            if (settings.name == Routes.home) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('LAYAR-TUJUAN')),
              );
            }
            return onGenerateRoute(settings);
          },
        ),
      );

  testWidgets('tanpa token tersimpan mengarah ke Login', (tester) async {
    final auth = AuthController(authSource: SampleAuthRepository());

    await tester.pumpWidget(wrap(auth));
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('token tersimpan memulihkan sesi dan meninggalkan gerbang', (
    tester,
  ) async {
    final auth = AuthController(authSource: _RestoringAuthRepository());

    await tester.pumpWidget(wrap(auth));
    await tester.pumpAndSettle();

    expect(auth.isSignedIn, isTrue);
    expect(find.text('LAYAR-TUJUAN'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}

class _RestoringAuthRepository implements AuthRepository {
  @override
  Future<bool> hasSession() async => true;

  @override
  Future<AppUser> uploadPhoto(AppUser user, String imagePath) async => user;

  @override
  Future<AppUser?> currentUser() async => const AppUser(
    id: '11',
    name: 'Pulih Sesi',
    email: 'pulih@agronoma.test',
    photoAsset: '',
    totalPlants: 0,
    harvestedThisSeason: 0,
  );

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser> refreshStats(AppUser user) async => user;

  @override
  Future<AppUser> saveWateringReminder(AppUser user, bool enabled) async =>
      user.copyWith(wateringReminderEnabled: enabled);

  @override
  Future<void> registerDeviceToken(String token) async {}
}
