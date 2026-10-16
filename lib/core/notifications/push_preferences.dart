import 'package:shared_preferences/shared_preferences.dart';

/// Persisted push-notification preference.
///
/// Single source of truth for the settings toggle; [NotificationService]
/// reads it on init so the toggle actually controls token sync and
/// foreground display.
class PushPreferences {
  static const key = 'push_notifications_enabled';

  /// Defaults to true — notifications on unless the user opted out.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
