import '../../../core/api/cuan_api.dart';

/// Settings data layer — profile info for the settings screen.
class SettingsRepository {
  Future<Map<String, String>?> profile() async {
    try {
      final res = await api.dio.get('/auth/api/get-session');
      final user = res.data?['data']?['user'];
      if (user == null) return null;
      return {
        'name': user['name']?.toString() ?? '',
        'email': user['email']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> changePassword(String current, String next) async {
    try {
      await api.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
