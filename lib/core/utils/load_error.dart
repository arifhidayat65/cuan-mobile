import 'package:dio/dio.dart';

/// A classified load failure: a user-facing Indonesian message plus whether
/// the failure means the session is dead (→ redirect to login).
class LoadError {
  const LoadError({required this.message, this.sessionExpired = false});

  final String message;
  final bool sessionExpired;
}

/// Map a thrown error to a [LoadError] with a message the user can act on.
LoadError classifyLoadError(Object e) {
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return const LoadError(
        message: 'Sesi berakhir. Silakan masuk kembali.',
        sessionExpired: true,
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const LoadError(
          message:
              'Tidak bisa terhubung ke server. Periksa koneksi internet HP, lalu coba lagi.',
        );
      case DioExceptionType.badResponse:
        return LoadError(
          message: 'Server bermasalah (kode $code). Coba lagi nanti.',
        );
      case DioExceptionType.cancel:
        return const LoadError(message: 'Permintaan dibatalkan. Coba lagi.');
    }
  }
  return const LoadError(message: 'Terjadi kesalahan. Coba lagi.');
}
