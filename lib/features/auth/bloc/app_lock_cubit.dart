import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/biometric_service.dart';

/// App lock state — biometric failure flag.
class AppLockState {
  const AppLockState({this.failed = false});

  final bool failed;

  AppLockState copyWith({bool? failed}) =>
      AppLockState(failed: failed ?? this.failed);
}

/// Biometric lock — replaces setState. BLoC only.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit() : super(const AppLockState());

  Future<bool> tryUnlock() async {
    final ok = await BiometricService.instance.authenticate();
    if (!ok) emit(state.copyWith(failed: true));
    return ok;
  }

  void retry() => emit(state.copyWith(failed: false));
}
