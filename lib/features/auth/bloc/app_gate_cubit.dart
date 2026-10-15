import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/biometric_service.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

/// App startup gate state.
class AppGateState {
  const AppGateState({
    this.checking = true,
    this.locked = false,
    this.showOnboarding = false,
  });

  final bool checking;
  final bool locked;
  final bool showOnboarding;

  AppGateState copyWith({
    bool? checking,
    bool? locked,
    bool? showOnboarding,
  }) {
    return AppGateState(
      checking: checking ?? this.checking,
      locked: locked ?? this.locked,
      showOnboarding: showOnboarding ?? this.showOnboarding,
    );
  }
}

/// Startup gates (onboarding → biometric lock → auth).
/// Replaces _AppRootState setState — BLoC only.
class AppGateCubit extends Cubit<AppGateState> {
  AppGateCubit() : super(const AppGateState());

  Future<void> checkGates() async {
    final onboardDone = await OnboardingScreen.isDone;
    final bioEnabled = await BiometricService.instance.isEnabled;
    final bioAvailable = await BiometricService.instance.isAvailable;
    emit(AppGateState(
      checking: false,
      showOnboarding: !onboardDone,
      locked: bioEnabled && bioAvailable && onboardDone,
    ));
  }

  Future<void> completeOnboarding() async {
    final enabled = await BiometricService.instance.isEnabled;
    final available = await BiometricService.instance.isAvailable;
    emit(state.copyWith(
      showOnboarding: false,
      locked: enabled && available,
    ));
  }

  void unlock() => emit(state.copyWith(locked: false));
}
