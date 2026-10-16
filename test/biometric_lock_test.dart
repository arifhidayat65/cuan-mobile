import 'package:cuan_mobile/core/security/biometric_service.dart';
import 'package:cuan_mobile/features/auth/bloc/app_gate_cubit.dart';
import 'package:cuan_mobile/features/auth/presentation/app_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake LocalAuthentication — no platform channel involved.
class FakeLocalAuth extends LocalAuthentication {
  FakeLocalAuth({
    this.canCheck = true,
    this.supported = true,
    this.authResult = true,
  });

  final bool canCheck;
  final bool supported;
  final bool authResult;
  int authCalls = 0;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    authCalls++;
    return authResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BiometricService.resetInstance();
  });

  tearDown(() {
    BiometricService.resetInstance();
  });

  group('AppGateCubit.checkGates', () {
    test('locked when biometric enabled, available, onboarding done',
        () async {
      SharedPreferences.setMockInitialValues({
        'biometric_enabled': true,
        'onboarding_done': true,
      });
      BiometricService.testInstance =
          BiometricService.forTest(FakeLocalAuth());

      final cubit = AppGateCubit();
      await cubit.checkGates();

      expect(cubit.state.checking, isFalse);
      expect(cubit.state.locked, isTrue);
      await cubit.close();
    });

    test('not locked when biometric disabled', () async {
      SharedPreferences.setMockInitialValues({
        'biometric_enabled': false,
        'onboarding_done': true,
      });
      BiometricService.testInstance =
          BiometricService.forTest(FakeLocalAuth());

      final cubit = AppGateCubit();
      await cubit.checkGates();

      expect(cubit.state.locked, isFalse);
      await cubit.close();
    });

    test('not locked when device has no biometrics', () async {
      SharedPreferences.setMockInitialValues({
        'biometric_enabled': true,
        'onboarding_done': true,
      });
      BiometricService.testInstance = BiometricService.forTest(
        FakeLocalAuth(canCheck: false, supported: false),
      );

      final cubit = AppGateCubit();
      await cubit.checkGates();

      expect(cubit.state.locked, isFalse);
      await cubit.close();
    });
  });

  group('AppLockScreen', () {
    testWidgets('auto-unlocks exactly once on success', (tester) async {
      final fake = FakeLocalAuth(authResult: true);
      BiometricService.testInstance = BiometricService.forTest(fake);

      var unlocked = 0;
      await tester.pumpWidget(
        MaterialApp(home: AppLockScreen(onUnlocked: () => unlocked++)),
      );
      await tester.pumpAndSettle();

      expect(unlocked, 1);
      expect(fake.authCalls, 1);

      // A rebuild must not fire a second biometric prompt.
      await tester.pumpWidget(
        MaterialApp(home: AppLockScreen(onUnlocked: () => unlocked++)),
      );
      await tester.pump();
      expect(fake.authCalls, 1);
    });

    testWidgets('shows error and stays locked on failure', (tester) async {
      final fake = FakeLocalAuth(authResult: false);
      BiometricService.testInstance = BiometricService.forTest(fake);

      var unlocked = 0;
      await tester.pumpWidget(
        MaterialApp(home: AppLockScreen(onUnlocked: () => unlocked++)),
      );
      await tester.pumpAndSettle();

      expect(unlocked, 0);
      expect(fake.authCalls, 1);
      expect(find.text('Verifikasi gagal. Coba lagi.'), findsOneWidget);
    });
  });
}
