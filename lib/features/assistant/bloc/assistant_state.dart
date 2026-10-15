import 'package:equatable/equatable.dart';

/// A single chat message. [transactions] holds inline cards recorded by the AI.
final class ChatMessage extends Equatable {
  const ChatMessage(this.me, this.text, [this.transactions]);

  final bool me;
  final String text;
  final List<Map<String, dynamic>>? transactions;

  @override
  List<Object?> get props => [me, text, transactions];
}

/// Assistant screen state — message list + in-flight reply flag + voice.
final class AssistantState extends Equatable {
  const AssistantState({
    this.messages = const [],
    this.busy = false,
    this.listening = false,
    this.recognized = '',
  });

  final List<ChatMessage> messages;
  final bool busy;
  final bool listening;
  final String recognized;

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? busy,
    bool? listening,
    String? recognized,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      busy: busy ?? this.busy,
      listening: listening ?? this.listening,
      recognized: recognized ?? this.recognized,
    );
  }

  @override
  List<Object?> get props => [messages, busy, listening, recognized];
}
