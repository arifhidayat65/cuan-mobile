import 'package:equatable/equatable.dart';

/// Which form the auth page shows.
enum AuthMode { login, register }

/// Auth states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Before [AuthAppStarted] is processed.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking for an existing session at startup.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Logged in — the app shell is shown.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

/// Login/register form is visible.
final class AuthFormState extends AuthState {
  const AuthFormState({
    this.mode = AuthMode.login,
    this.submitting = false,
    this.errorMessage,
  });

  final AuthMode mode;
  final bool submitting;
  final String? errorMessage;

  AuthFormState copyWith({
    AuthMode? mode,
    bool? submitting,
    String? errorMessage,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mode, submitting, errorMessage];
}
