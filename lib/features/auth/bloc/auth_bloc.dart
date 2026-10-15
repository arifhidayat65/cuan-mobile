import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication flow: session check → login/register → logout.
///
/// Side effects: syncs the FCM device token after login, and unregisters it
/// (while still authed) before sign-out.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthModeToggled>(_onModeToggled);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repo;

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final loggedIn = await _repo.isLoggedIn();
    if (loggedIn) {
      emit(const AuthAuthenticated());
    } else {
      emit(const AuthFormState());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthFormState || current.submitting) return;
    emit(current.copyWith(submitting: true, errorMessage: null));
    try {
      await _repo.signIn(event.email, event.password);
      // Now authed — sync the FCM device token to the backend.
      await notifications.syncToken();
      emit(const AuthAuthenticated());
    } catch (e) {
      // Distinguish network failures from wrong credentials so the next
      // debug session doesn't start from a misleading message.
      emit(
        AuthFormState(
          mode: AuthMode.login,
          errorMessage: _loginErrorMessage(e),
        ),
      );
    }
  }

  /// Map a sign-in failure to a message that says what actually went wrong.
  String _loginErrorMessage(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return 'Tidak bisa terhubung ke server. Periksa koneksi internet HP.';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 401 || code == 400) {
            return 'Login gagal. Periksa email & kata sandi.';
          }
          return 'Server bermasalah (kode $code). Coba lagi nanti.';
        case DioExceptionType.cancel:
          return 'Login dibatalkan. Coba lagi.';
      }
    }
    return 'Login gagal. Coba lagi.';
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthFormState || current.submitting) return;
    emit(current.copyWith(submitting: true, errorMessage: null));
    try {
      await _repo.signUp(event.name, event.email, event.password);
      // Signup no longer auto-logs in (anti-enumeration).
      // Show login form with success message.
      emit(
        const AuthFormState(
          mode: AuthMode.login,
          errorMessage: 'Pendaftaran berhasil. Silakan login.',
        ),
      );
    } catch (_) {
      emit(
        const AuthFormState(
          mode: AuthMode.register,
          errorMessage: 'Pendaftaran gagal. Coba lagi.',
        ),
      );
    }
  }

  void _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! AuthFormState || current.submitting) return;
    emit(
      current.copyWith(
        mode:
            current.mode == AuthMode.login ? AuthMode.register : AuthMode.login,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Unregister push token while still authed, then sign out.
    await notifications.onLogout();
    await _repo.signOut();
    emit(const AuthFormState());
  }
}
