import 'dart:typed_data';

import 'package:cuan_mobile/core/api/session_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always answers with the given HTTP status, no network involved.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithInterceptor({
  required int statusCode,
  required Future<void> Function() onSessionInvalidated,
}) {
  return Dio()
    ..httpClientAdapter = _FakeAdapter(statusCode)
    ..interceptors.add(
      SessionInvalidatedInterceptor(
        onSessionInvalidated: onSessionInvalidated,
      ),
    );
}

void main() {
  group('SessionInvalidatedInterceptor', () {
    test('401 triggers onSessionInvalidated', () async {
      var invalidated = false;
      final dio = _dioWithInterceptor(
        statusCode: 401,
        onSessionInvalidated: () async {
          invalidated = true;
        },
      );

      await expectLater(
        dio.get('https://example.com/api/x'),
        throwsA(isA<DioException>()),
      );
      // The interceptor fires the callback via unawaited(): flush it.
      await Future<void>.delayed(Duration.zero);

      expect(invalidated, isTrue);
    });

    test('non-401 error does not trigger onSessionInvalidated', () async {
      var invalidated = false;
      final dio = _dioWithInterceptor(
        statusCode: 500,
        onSessionInvalidated: () async {
          invalidated = true;
        },
      );

      await expectLater(
        dio.get('https://example.com/api/x'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(invalidated, isFalse);
    });
  });
}
