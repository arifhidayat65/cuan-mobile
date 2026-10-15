import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/security/biometric_service.dart';
import '../data/settings_repository.dart';
import 'settings_state.dart';

/// Settings: profile info + local preference toggles.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo) : super(const SettingsState());

  final SettingsRepository _repo;

  Future<void> loadProfile() async {
    final profile = await _repo.profile();
    final bioEnabled = await BiometricService.instance.isEnabled;
    final bioAvailable = await BiometricService.instance.isAvailable;
    emit(
      state.copyWith(
        loading: false,
        userName: profile?['name'] ?? '',
        userEmail: profile?['email'] ?? '',
        biometricEnabled: bioEnabled,
        biometricAvailable: bioAvailable,
      ),
    );
  }

  void toggleNotifications(bool value) =>
      emit(state.copyWith(notificationsEnabled: value));

  /// Toggle biometric — verifies with actual biometric prompt when enabling.
  Future<bool> toggleBiometric(bool value) async {
    if (value) {
      final ok = await BiometricService.instance.authenticate();
      if (!ok) return false;
    }
    await BiometricService.instance.setEnabled(value);
    emit(state.copyWith(biometricEnabled: value));
    return true;
  }

  /// Change password — returns true on success.
  Future<bool> changePassword(String current, String next) =>
      _repo.changePassword(current, next);
}
