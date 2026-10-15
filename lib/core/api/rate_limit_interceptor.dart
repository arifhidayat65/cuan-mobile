import 'package:dio/dio.dart';

/// Client-side rate limiter interceptor for Dio.
/// Queues requests when exceeding maxRequests per window.
/// Prevents 429s from the backend and accidental API spam.
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({
    this.maxRequests = 90,
    this.window = const Duration(minutes: 1),
  });

  final int maxRequests;
  final Duration window;

  late int _tokens = maxRequests;
  DateTime _windowStart = DateTime.now();
  final List<_QueuedRequest> _queue = [];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _refill();
    if (_tokens > 0) {
      _tokens--;
      handler.next(options);
    } else {
      // Queue the request until next window
      _queue.add(_QueuedRequest(options, handler));
      final wait = window - DateTime.now().difference(_windowStart);
      Future.delayed(
        wait.isNegative ? Duration.zero : wait,
        _drainQueue,
      );
    }
  }

  void _refill() {
    final now = DateTime.now();
    if (now.difference(_windowStart) >= window) {
      _tokens = maxRequests;
      _windowStart = now;
    }
  }

  void _drainQueue() {
    _refill();
    while (_tokens > 0 && _queue.isNotEmpty) {
      final q = _queue.removeAt(0);
      _tokens--;
      q.handler.next(q.options);
    }
    if (_queue.isNotEmpty) {
      final wait = window - DateTime.now().difference(_windowStart);
      Future.delayed(
        wait.isNegative ? Duration.zero : wait,
        _drainQueue,
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If backend says 429, respect Retry-After
    if (err.response?.statusCode == 429) {
      final retryAfter =
          int.tryParse(err.response?.headers.value('retry-after') ?? '');
      if (retryAfter != null) {
        _tokens = 0;
        _windowStart = DateTime.now().add(
          Duration(seconds: retryAfter) - window,
        );
      }
    }
    handler.next(err);
  }
}

class _QueuedRequest {
  _QueuedRequest(this.options, this.handler);
  final RequestOptions options;
  final RequestInterceptorHandler handler;
}
