import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/core/state/auth_controller.dart';
import 'package:frontend/core/widgets/agro_button.dart';
import 'package:frontend/core/widgets/agro_text_field.dart';
import 'package:frontend/features/auth/widgets/auth_layout.dart';

/// Layar Register — frame `Register` (node `155:1357`) pada Figma;
/// field-nya memakai komponen `textfield/with title`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      confirmation: _confirmation.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.home, (route) => false);
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
      title: 'Buat Akun Baru',
      subtitle: 'Mulai langkah awal untuk kebun yang lebih sehat.',
      fields: [
        AgroTextField(
          label: 'Nama Pengguna',
          hint: 'Masukkan nama pengguna',
          controller: _name,
          textInputAction: TextInputAction.next,
          errorText: _errors['name'],
        ),
        AgroTextField(
          label: 'Email',
          hint: 'Contoh: nama@email.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _errors['email'],
        ),
        AgroTextField(
          label: 'Password',
          hint: 'Minimal 8 karakter',
          controller: _password,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          errorText: _errors['password'],
          suffix: PasswordVisibilityToggle(
            visible: !_obscurePassword,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        AgroTextField(
          label: 'Konfirmasi Password',
          hint: 'Konfirmasi password',
          controller: _confirmation,
          obscureText: _obscureConfirmation,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _errors['confirmation'],
          suffix: PasswordVisibilityToggle(
            visible: !_obscureConfirmation,
            onPressed: () =>
                setState(() => _obscureConfirmation = !_obscureConfirmation),
          ),
        ),
      ],
      submit: AgroButton(label: 'Masuk', loading: loading, onPressed: _submit),
      error: _errors['general'],
      footer: AuthFooterLink(
        prefix: 'Sudah punya akun? ',
        actionLabel: 'Masuk',
        onTap: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
