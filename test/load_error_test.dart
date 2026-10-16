import 'package:cuan_mobile/core/utils/load_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio({
  required DioExceptionType type,
  int? statusCode,
}) {
  final opts = RequestOptions(path: '/x');
  return DioException(
    requestOptions: opts,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: opts, statusCode: statusCode),
  );
}

void main() {
  group('classifyLoadError', () {
    test('401 → session expired', () {
      final err = classifyLoadError(
        _dio(type: DioExceptionType.badResponse, statusCode: 401),
      );
      expect(err.sessionExpired, isTrue);
      expect(err.message, contains('Sesi'));
    });

    test('403 → session expired', () {
      final err = classifyLoadError(
        _dio(type: DioExceptionType.badResponse, statusCode: 403),
      );
      expect(err.sessionExpired, isTrue);
    });

    test('connection error → network message, not session expired', () {
      final err = classifyLoadError(
        _dio(type: DioExceptionType.connectionError),
      );
      expect(err.sessionExpired, isFalse);
      expect(err.message, contains('internet'));
    });

    test('unknown dio error → network message', () {
      final err =
          classifyLoadError(_dio(type: DioExceptionType.unknown));
      expect(err.sessionExpired, isFalse);
      expect(err.message, contains('internet'));
    });

    test('500 → server message with code', () {
      final err = classifyLoadError(
        _dio(type: DioExceptionType.badResponse, statusCode: 500),
      );
      expect(err.sessionExpired, isFalse);
      expect(err.message, contains('500'));
    });

    test('generic exception → generic message', () {
      final err = classifyLoadError(Exception('boom'));
      expect(err.sessionExpired, isFalse);
      expect(err.message, isNotEmpty);
    });
  });
}
