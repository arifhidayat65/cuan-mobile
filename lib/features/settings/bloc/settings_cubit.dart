import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/security/biometric_service.dart';
import '../data/settings_repository.dart';
import 'settings_state.dart';

/// Settings: profile info + local preference toggles.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo, {NotificationService? push})
      : _push = push ?? notifications,
        super(const SettingsState());

  final SettingsRepository _repo;
  final NotificationService _push;

  Future<void> loadProfile() async {
    final profile = await _repo.profile();
    final bioEnabled = await BiometricService.instance.isEnabled;
    final bioAvailable = await BiometricService.instance.isAvailable;
    final pushEnabled = await _push.isPushEnabled();
    emit(
      state.copyWith(
        loading: false,
        userName: profile?['name'] ?? '',
        userEmail: profile?['email'] ?? '',
        biometricEnabled: bioEnabled,
        biometricAvailable: bioAvailable,
        notificationsEnabled: pushEnabled,
      ),
    );
  }

  /// Toggle push notifications — persists the preference AND actually
  /// controls token sync / foreground display via [NotificationService].
  Future<void> toggleNotifications(bool value) async {
    await _push.setPushEnabled(value);
    emit(state.copyWith(notificationsEnabled: value));
  }

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
