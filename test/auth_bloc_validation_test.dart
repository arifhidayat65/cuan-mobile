import 'package:cuan_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:cuan_mobile/features/auth/bloc/auth_event.dart';
import 'package:cuan_mobile/features/auth/bloc/auth_state.dart';
import 'package:cuan_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// No network — validation errors must surface without touching the API.
class _FakeAuthRepository extends AuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;
}

/// Validation errors flow through the same inline error UI as server errors
/// (QA-004), without triggering a network call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AuthValidationError sets errorMessage without submitting', () async {
    final bloc = AuthBloc(_FakeAuthRepository());
    bloc.add(const AuthAppStarted());
    await bloc.stream.firstWhere((s) => s is AuthFormState);

    bloc.add(const AuthValidationError('Format email tidak valid.'));
    final withError = await bloc.stream.firstWhere(
      (s) =>
          s is AuthFormState && s.errorMessage == 'Format email tidak valid.',
    ) as AuthFormState;

    expect(withError.submitting, isFalse);
    expect(withError.errorMessage, 'Format email tidak valid.');
    await bloc.close();
  });

  test('toggling mode clears the validation error', () async {
    final bloc = AuthBloc(_FakeAuthRepository());
    bloc.add(const AuthAppStarted());
    await bloc.stream.firstWhere((s) => s is AuthFormState);

    bloc.add(const AuthValidationError('Kata sandi minimal 8 karakter.'));
    await bloc.stream.firstWhere(
      (s) =>
          s is AuthFormState &&
          s.errorMessage == 'Kata sandi minimal 8 karakter.',
    );

    bloc.add(AuthModeToggled());
    final toggled = await bloc.stream.firstWhere(
      (s) => s is AuthFormState && s.mode == AuthMode.register,
    ) as AuthFormState;

    expect(toggled.errorMessage, isNull);
    await bloc.close();
  });

  test('validation error is ignored when not on the form', () async {
    final bloc = AuthBloc(_FakeAuthRepository());
    // Still AuthInitial — never pumped to the form.
    bloc.add(const AuthValidationError('whatever'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<AuthInitial>());
    await bloc.close();
  });
}
