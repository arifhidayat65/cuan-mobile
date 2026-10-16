import 'package:speech_to_text/speech_recognition_error.dart';

/// Why voice input failed to start.
enum MicFailure { permissionDenied, unsupported }

/// Map a speech-recognition error to a user-facing failure kind.
/// A `null` error (no detail from the platform) means the device or the
/// speech service simply isn't available.
MicFailure classifyMicFailure(SpeechRecognitionError? error) {
  final msg = error?.errorMsg.toLowerCase() ?? '';
  if (msg.contains('permission') ||
      msg.contains('not-allowed') ||
      msg.contains('denied')) {
    return MicFailure.permissionDenied;
  }
  return MicFailure.unsupported;
}

/// Indonesian user-facing message for a mic failure.
String micFailureMessage(MicFailure failure) {
  switch (failure) {
    case MicFailure.permissionDenied:
      return 'Izin mikrofon ditolak. Aktifkan di Pengaturan › Aplikasi › Cuan › Izin.';
    case MicFailure.unsupported:
      return 'Perangkat ini tidak mendukung pengenalan suara.';
  }
}
