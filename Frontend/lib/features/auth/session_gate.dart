import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/theme/theme.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthController>();
    await auth.restoreSession();
    if (!mounted) return;

    Navigator.of(context)
        .pushReplacementNamed(auth.isSignedIn ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.mainWhite,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
