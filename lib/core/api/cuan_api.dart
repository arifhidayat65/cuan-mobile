import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_state_cache.dart';
import 'rate_limit_interceptor.dart';
import 'secure_cookie_storage.dart';
import 'session_interceptor.dart';

/// API client for the Cuan backend.
/// Uses persistent cookies (Better Auth session) via dio_cookie_manager.
class CuanApi {
  static const baseUrl = 'https://cuan-core.akudong85.workers.dev';

  late final Dio dio;
  bool _ready = false;

  /// Local login-state cache: avoids a network hit on every app start.
  /// Authoritative state still lives server-side; a 401 on any
  /// authenticated call invalidates the cache (see
  /// [SessionInvalidatedInterceptor]).
  final AuthStateCache _authState = AuthStateCache();

  Future<void> init() async {
    if (_ready) return;
    final dir = await getApplicationDocumentsDirectory();
    final secureStorage = SecureCookieStorage();
    // One-time migration from the legacy plaintext cookie files.
    // Best-effort: on failure the user simply re-logs in.
    try {
      await migrateLegacyCookies(
        legacyDirPath: '${dir.path}/cookies',
        target: secureStorage,
      );
    } catch (_) {}
    final jar = PersistCookieJar(storage: secureStorage);
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'x-timezone': 'Asia/Jakarta',
        },
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    dio.interceptors.add(RateLimitInterceptor());
    dio.interceptors.add(
      SessionInvalidatedInterceptor(
        onSessionInvalidated: () => _authState.clear(),
      ),
    );
    _ready = true;
  }

  /// Cached login check: trusts the local cache and skips the network.
  /// On first run (cache empty) it verifies once via the network and caches
  /// the result. A stale `true` self-heals: the first authenticated call
  /// that returns 401 clears the cache (see [SessionInvalidatedInterceptor]).
  Future<bool> get isLoggedIn async {
    final cached = await _authState.read();
    if (cached != null) return cached;
    try {
      final res = await dio.get('/api/financial-accounts');
      final ok = res.statusCode == 200;
      await _authState.write(ok);
      return ok;
    } catch (_) {
      await _authState.write(false);
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    await dio.post(
      '/auth/api/sign-in/email',
      data: {'email': email, 'password': password},
      options: Options(headers: {'Origin': baseUrl}),
    );
    await _authState.write(true);
  }

  Future<void> signUp(String name, String email, String password) async {
    await dio.post(
      '/auth/api/sign-up/email',
      data: {'name': name, 'email': email, 'password': password},
      options: Options(headers: {'Origin': baseUrl}),
    );
    // Sign-up does not create a session (user must log in afterwards),
    // so explicitly record logged-out rather than leaving stale state.
    await _authState.write(false);
  }

  Future<void> signOut() async {
    try {
      await dio.post('/auth/api/sign-out');
    } catch (e) {
      // Best-effort sign-out: log in debug so failures are visible to devs,
      // but don't block the user from being signed out locally.
      debugPrint('CuanApi.signOut failed: $e');
    } finally {
      await _authState.clear();
    }
  }

  /// Register this device for push notifications (FCM).
  Future<void> registerFcmToken(String token) async {
    await dio
        .post('/api/fcm-tokens', data: {'token': token, 'platform': 'android'});
  }

  /// Remove this device's push token (call before sign-out while authed).
  Future<void> unregisterFcmToken(String token) async {
    try {
      await dio.delete('/api/fcm-tokens', data: {'token': token});
    } catch (e) {
      // Best-effort cleanup: log in debug so failures are visible to devs,
      // but don't block the sign-out flow.
      debugPrint('CuanApi.unregisterFcmToken failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> accounts() async {
    final res = await dio.get('/api/financial-accounts');
    return List<Map<String, dynamic>>.from(res.data['data'] as List);
  }

  Future<List<Map<String, dynamic>>> transactions({int limit = 50}) async {
    final res =
        await dio.get('/api/transactions', queryParameters: {'limit': limit});
    final data = res.data['data'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['items'] is List) {
      return List<Map<String, dynamic>>.from(data['items'] as List);
    }
    return [];
  }

  /// Monthly stats (income/expense/net) for a date range — real data.
  Future<Map<String, double>> transactionStats({
    required String from,
    required String to,
  }) async {
    try {
      final res = await dio.get(
        '/api/transactions/stats',
        queryParameters: {'from': from, 'to': to},
      );
      final summary = res.data?['data']?['summary'] as Map?;
      if (summary == null) return {};
      return {
        'income': ((summary['totalIncome'] as num?)?.toDouble() ?? 0),
        'expense': ((summary['totalExpense'] as num?)?.toDouble() ?? 0),
        'net': ((summary['netSavings'] as num?)?.toDouble() ?? 0),
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> budgets(String month) async {
    final res =
        await dio.get('/api/budgets', queryParameters: {'month': month});
    return List<Map<String, dynamic>>.from(res.data['data'] as List);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final res = await dio.get('/api/categories');
    return List<Map<String, dynamic>>.from(res.data['data'] as List);
  }

  Future<Map<String, dynamic>> chat(String message) async {
    final res = await dio.post(
      '/api/chat/',
      data: {
        'message': message,
        'locale': 'id',
        'history': [],
        'timezone': 'Asia/Jakarta',
      },
    );
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }

  Future<void> createTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String accountId,
    String? description,
  }) async {
    await dio.post(
      '/api/transactions',
      data: {
        'type': type,
        'amount': amount,
        'categoryId': categoryId,
        'accountId': accountId,
        'description': description ?? '',
        'date': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<void> createBudget({
    required int categoryId,
    required double limit,
    required String month,
  }) async {
    // Backend expects amount as decimal string (ADR-004, no float arithmetic).
    final amount = limit % 1 == 0 ? limit.toInt().toString() : limit.toString();
    await dio.post(
      '/api/budgets',
      data: {'categoryId': categoryId, 'amount': amount, 'month': month},
    );
  }

  /// Change password via better-auth.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await dio.post(
      '/auth/api/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // --- Recurring transactions ---

  Future<List<Map<String, dynamic>>> recurring() async {
    final res = await dio.get('/api/recurring');
    final data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> createRecurring(Map<String, dynamic> payload) async {
    await dio.post('/api/recurring', data: payload);
  }

  Future<void> updateRecurring(String id, Map<String, dynamic> payload) async {
    await dio.patch('/api/recurring/$id', data: payload);
  }

  Future<void> deleteRecurring(String id) async {
    await dio.delete('/api/recurring/$id');
  }

  Future<int> generateRecurring() async {
    final res = await dio.post('/api/recurring/generate');
    return (res.data['data']['generated'] as num?)?.toInt() ?? 0;
  }

  // --- Insights ---

  Future<Map<String, dynamic>> healthScore(String month) async {
    final res = await dio.get(
      '/api/insights/health-score',
      queryParameters: {'month': month},
    );
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  // --- Savings goals ---

  Future<List<Map<String, dynamic>>> savingsGoals() async {
    final res = await dio.get('/api/savings-goals');
    return (res.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> createSavingsGoal(Map<String, dynamic> payload) async {
    await dio.post('/api/savings-goals', data: payload);
  }

  Future<void> addFunds(String id, String amount) async {
    await dio
        .post('/api/savings-goals/$id/add-funds', data: {'amount': amount});
  }

  Future<void> deleteSavingsGoal(String id) async {
    await dio.delete('/api/savings-goals/$id');
  }

  // --- Debts ---

  Future<List<Map<String, dynamic>>> debts({String? type}) async {
    final res = await dio.get(
      '/api/debts',
      queryParameters: {if (type != null) 'type': type},
    );
    return (res.data['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> createDebt(Map<String, dynamic> payload) async {
    await dio.post('/api/debts', data: payload);
  }

  Future<void> payDebt(String id, String amount) async {
    await dio.post('/api/debts/$id/pay', data: {'amount': amount});
  }

  Future<void> deleteDebt(String id) async {
    await dio.delete('/api/debts/$id');
  }

  // --- Backup ---

  Future<Map<String, dynamic>> backupExport() async {
    final res = await dio.get('/api/backup/export');
    return (res.data as Map).cast<String, dynamic>();
  }
}

final api = CuanApi();
