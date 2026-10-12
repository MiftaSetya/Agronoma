import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_text_field.dart';
import 'package:frontend/features/auth/widgets/auth_layout.dart';

/// Layar Login — frame `Login` (node `150:951`) pada Figma.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.home,
        (route) => false,
      );
    } else {
      setState(() => _errors = auth.consumeErrors());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthController, bool>(
      (a) => a.status == AuthStatus.signingIn,
    );

    return AuthLayout(
      title: 'Selamat Datang',
      subtitle: 'Masuk untuk melanjutkan perawatan tanamanmu.',
      fields: [
        AgroTextField(
          label: 'Email',
          hint: 'nama@email.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _errors['email'],
        ),
        AgroTextField(
          label: 'Password',
          hint: 'Masukkan password',
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _errors['password'],
          suffix: PasswordVisibilityToggle(
            visible: !_obscure,
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ],
      submit: AgroButton(label: 'Masuk', loading: loading, onPressed: _submit),
      footer: AuthFooterLink(
        prefix: 'Belum punya akun? ',
        actionLabel: 'Daftar',
        onTap: () => Navigator.of(context).pushNamed(Routes.register),
      ),
    );
  }
}
