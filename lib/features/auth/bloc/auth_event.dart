import 'package:equatable/equatable.dart';

/// Auth events.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once at app start — checks for an existing session.
final class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

/// Toggles the login/register form mode.
final class AuthModeToggled extends AuthEvent {
  const AuthModeToggled();
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
