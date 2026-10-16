import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's login state locally so the app doesn't need a
/// network round-trip on every start to know whether a session exists.
///
/// The cache is advisory, not authoritative:
/// - written `true` after a successful sign-in,
/// - cleared (`false`) on sign-out and whenever the backend answers 401,
/// - `null` means "never checked on this device" and triggers one network
///   verification that is then cached.
class AuthStateCache {
  static const key = 'cuan_logged_in';

  /// Returns the cached login state, or `null` if never recorded.
  Future<bool?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> write(bool loggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, loggedIn);
  }

  /// Marks the user as logged out.
  Future<void> clear() => write(false);
}
