import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../shell/presentation/shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

/// Routes to the login page or the app shell based on [AuthBloc] state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthAuthenticated() => Shell(),
          AuthFormState() => LoginPage(),
          _ => Scaffold(
              backgroundColor: LedgerTheme.bg,
              body: Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              ),
            ),
        };
      },
    );
  }
}
