import '../../../core/api/cuan_api.dart';

/// Auth data layer — thin wrapper around [CuanApi] auth endpoints.
class AuthRepository {
  Future<bool> isLoggedIn() => api.isLoggedIn;

  Future<void> signIn(String email, String password) =>
      api.signIn(email, password);

  Future<void> signUp(String name, String email, String password) =>
      api.signUp(name, email, password);

  Future<void> signOut() => api.signOut();

  /// Current session user (`name`, `email`), or null when logged out.
  Future<Map<String, String>?> sessionUser() async {
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
}
