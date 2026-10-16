import 'package:cuan_mobile/features/assistant/bloc/assistant_cubit.dart';
import 'package:cuan_mobile/features/assistant/data/assistant_repository.dart';
import 'package:cuan_mobile/features/assistant/data/mic_feedback.dart';
import 'package:cuan_mobile/features/assistant/presentation/assistant_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Test double: speech recognition whose behavior can be scripted.
class FakeSpeech extends SpeechToText {
  FakeSpeech({required this.available, this.initError})
      : super.withMethodChannel();

  final bool available;
  final SpeechRecognitionError? initError;
  bool listenCalled = false;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = const Duration(seconds: 30),
    List<SpeechConfigOption>? options,
  }) async {
    if (initError != null) onError?.call(initError!);
    return available;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<dynamic> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    listenCalled = true;
  }
}

Future<void> _pumpPage(WidgetTester tester, SpeechToText speech) {
  return tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => AssistantCubit(AssistantRepository()),
        child: Scaffold(body: AssistantPage(speech: speech)),
      ),
    ),
  );
}

void main() {
  group('classifyMicFailure', () {
    test('null error -> unsupported', () {
      expect(classifyMicFailure(null), MicFailure.unsupported);
    });

    test('permission error -> permissionDenied', () {
      expect(
        classifyMicFailure(
          SpeechRecognitionError('error_permission', true),
        ),
        MicFailure.permissionDenied,
      );
    });

    test('non-permission error -> unsupported', () {
      expect(
        classifyMicFailure(
          SpeechRecognitionError('error_network', false),
        ),
        MicFailure.unsupported,
      );
    });
  });

  group('micFailureMessage', () {
    test('permission denied message guides to settings', () {
      final msg = micFailureMessage(MicFailure.permissionDenied);
      expect(msg, contains('Izin mikrofon'));
      expect(msg, contains('Pengaturan'));
    });

    test('unsupported message names the device', () {
      final msg = micFailureMessage(MicFailure.unsupported);
      expect(msg, contains('tidak mendukung'));
    });
  });

  group('mic button feedback (widget)', () {
    testWidgets('unavailable speech -> snackbar, stays silent no more',
        (tester) async {
      await _pumpPage(tester, FakeSpeech(available: false));
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('tidak mendukung'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('permission denied -> snackbar explains how to enable',
        (tester) async {
      await _pumpPage(
        tester,
        FakeSpeech(
          available: false,
          initError: SpeechRecognitionError('error_permission', true),
        ),
      );
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Izin mikrofon'), findsOneWidget);
    });

    testWidgets('available speech -> listening state with stop icon',
        (tester) async {
      final speech = FakeSpeech(available: true);
      await _pumpPage(tester, speech);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      expect(speech.listenCalled, isTrue);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // Stop listening so the pulse animation timer doesn't leak past dispose.
      // (tap -> async toggle -> rebuild needs two pump cycles to complete.)
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      await tester.pump();
      // Flush the page's scroll-to-bottom delayed future (BlocConsumer listener).
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('mic button has a tooltip for discoverability', (tester) async {
      await _pumpPage(tester, FakeSpeech(available: false));
      expect(find.byTooltip('Input suara'), findsOneWidget);
    });
  });
}
