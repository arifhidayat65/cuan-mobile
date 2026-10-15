import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/assistant_repository.dart';
import 'assistant_state.dart';

/// AI chat — appends user/assistant messages, tracks in-flight replies.
class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this._repo)
      : super(
          const AssistantState(
            messages: [
              ChatMessage(
                false,
                'Halo! Aku Cuan. Ceritakan pengeluaran atau pemasukanmu, '
                'nanti aku catat otomatis.\n\nContoh: "Makan siang 35rb bayar pakai e-wallet"',
              ),
            ],
          ),
        );

  final AssistantRepository _repo;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.busy) return;
    emit(
      state.copyWith(
        messages: [...state.messages, ChatMessage(true, trimmed)],
        busy: true,
      ),
    );
    try {
      final data = await _repo.chat(trimmed);
      final reply = (data['reply'] as String?) ?? 'OK.';
      final txs = data['transactions'] is List
          ? List<Map<String, dynamic>>.from(data['transactions'] as List)
          : null;
      emit(
        state.copyWith(
          messages: [...state.messages, ChatMessage(false, reply, txs)],
          busy: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            const ChatMessage(
              false,
              'Maaf, aku lagi nggak bisa dihubungi. Coba lagi ya.',
            ),
          ],
          busy: false,
        ),
      );
    }
  }

  void clear() => emit(state.copyWith(messages: []));

  /// Voice input state — driven by the page's speech callbacks.
  void setListening(bool listening) =>
      emit(state.copyWith(listening: listening));

  void setRecognized(String text) =>
      emit(state.copyWith(recognized: text));
}
