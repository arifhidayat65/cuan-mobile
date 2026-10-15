import 'package:equatable/equatable.dart';

/// Settings screen state — profile + preference toggles.
final class SettingsState extends Equatable {
  const SettingsState({
    this.loading = true,
    this.userName = '',
    this.userEmail = '',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
  });

  final bool loading;
  final String userName;
  final String userEmail;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;

  SettingsState copyWith({
    bool? loading,
    String? userName,
    String? userEmail,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
  }) {
    return SettingsState(
      loading: loading ?? this.loading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        userName,
        userEmail,
        notificationsEnabled,
        biometricEnabled,
        biometricAvailable,
      ];
}
