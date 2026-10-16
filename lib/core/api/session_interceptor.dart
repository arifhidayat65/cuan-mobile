import 'dart:async';

import 'package:dio/dio.dart';

/// Clears the locally cached login state the moment the backend reports
/// the session is no longer valid.
///
/// This is the lazy re-validation half of the login cache: `isLoggedIn`
/// trusts the cache and skips the network, so the first authenticated call
/// that comes back 401 is what tells us the session actually died.
class SessionInvalidatedInterceptor extends Interceptor {
  SessionInvalidatedInterceptor({required this.onSessionInvalidated});

  final Future<void> Function() onSessionInvalidated;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Don't hold up error propagation for the cache write.
      unawaited(onSessionInvalidated());
    }
    handler.next(err);
  }
}
