import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Simple email shape check used by [validateAuthForm].
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Client-side validation for the auth form (QA-004).
/// Returns the message to show inline, or null when the input is valid.
String? validateAuthForm({
  required bool registerMode,
  required String name,
  required String email,
  required String password,
}) {
  final trimmedEmail = email.trim();
  if (registerMode && name.trim().isEmpty) {
    return 'Nama tidak boleh kosong.';
  }
  if (trimmedEmail.isEmpty) {
    return 'Email tidak boleh kosong.';
  }
  if (!_emailPattern.hasMatch(trimmedEmail)) {
    return 'Format email tidak valid.';
  }
  if (password.isEmpty) {
    return 'Kata sandi tidak boleh kosong.';
  }
  if (registerMode && password.length < 8) {
    return 'Kata sandi minimal 8 karakter.';
  }
  return null;
}

/// Midnight Ledger auth — quiet, premium, no marketing fluff.
/// Supports both sign-in and sign-up. State lives in [AuthBloc].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(AuthFormState form) {
    final registerMode = form.mode == AuthMode.register;
    final validationError = validateAuthForm(
      registerMode: registerMode,
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (validationError != null) {
      // Client-side failure: show inline, skip the network call entirely.
      context.read<AuthBloc>().add(AuthValidationError(validationError));
      return;
    }
    final bloc = context.read<AuthBloc>();
    if (registerMode) {
      bloc.add(
        AuthRegisterSubmitted(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ),
      );
    } else {
      bloc.add(
        AuthLoginSubmitted(
          email: _email.text.trim(),
          password: _password.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final form = state is AuthFormState ? state : const AuthFormState();
        final registerMode = form.mode == AuthMode.register;

        return Scaffold(
          backgroundColor: LedgerTheme.bg,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacer(),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: LedgerTheme.accentDim,
                      borderRadius:
                          BorderRadius.circular(LedgerTheme.radiusTile),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: LedgerTheme.accent,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text('Cuan', style: LedgerTheme.displaySerif(44)),
                  SizedBox(height: 8),
                  Text(
                    'Private finance, tracked by chat.',
                    style: TextStyle(color: LedgerTheme.muted, fontSize: 15),
                  ),
                  SizedBox(height: 40),
                  if (registerMode) ...[
                    TextField(
                      controller: _name,
                      style: TextStyle(color: LedgerTheme.text),
                      decoration: InputDecoration(
                        hintText: 'Nama',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: LedgerTheme.muted,
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: LedgerTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon:
                          Icon(Icons.mail_outline, color: LedgerTheme.muted),
                    ),
                  ),
                  SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    style: TextStyle(color: LedgerTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Kata sandi',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: LedgerTheme.muted),
                    ),
                    onSubmitted: (_) => _submit(form),
                  ),
                  if (form.errorMessage != null) ...[
                    SizedBox(height: 12),
                    Text(
                      form.errorMessage!,
                      style: TextStyle(color: LedgerTheme.expense),
                    ),
                  ],
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: form.submitting ? null : () => _submit(form),
                      style: FilledButton.styleFrom(
                        backgroundColor: LedgerTheme.accent,
                        foregroundColor: LedgerTheme.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: form.submitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: LedgerTheme.bg,
                              ),
                            )
                          : Text(
                              registerMode ? 'Daftar' : 'Masuk',
                              style: TextStyle(
                                color: LedgerTheme.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: form.submitting
                          ? null
                          : () =>
                              context.read<AuthBloc>().add(AuthModeToggled()),
                      child: Text(
                        registerMode
                            ? 'Sudah punya akun? Masuk'
                            : 'Belum punya akun? Daftar',
                        style: TextStyle(color: LedgerTheme.accent),
                      ),
                    ),
                  ),
                  Spacer(),
                  Center(
                    child: Text(
                      'Uangmu tetap milikmu. Selalu.',
                      style: TextStyle(color: LedgerTheme.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
