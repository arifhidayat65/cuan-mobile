import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/border_beam.dart';
import '../../../core/widgets/fade_in.dart';
import '../bloc/assistant_cubit.dart';
import '../bloc/assistant_state.dart';

/// The super power — chat-first AI finance assistant.
/// Dark, calm, streaming replies with inline transaction cards.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechToText();

  static const _suggestions = [
    'Kopi 25rb',
    'Berapa saldo dompetku?',
    'Pengeluaran makan minggu ini?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final cubit = context.read<AssistantCubit>();
    if (cubit.state.listening) {
      await _speech.stop();
      cubit.setListening(false);
      return;
    }
    final available = await _speech.initialize(
      onError: (_) => cubit.setListening(false),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          cubit.setListening(false);
        }
      },
    );
    if (!available) return;
    cubit.setListening(true);
    await _speech.listen(
      onResult: (r) {
        _ctrl.text = r.recognizedWords;
        cubit.setRecognized(r.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
      ),
    );
  }

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<AssistantCubit>().send(text);
    _jump();
  }

  void _jump() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            // The signature AI accent — the one place BorderBeam is allowed.
            BorderBeam(
              size: 32,
              child: Icon(
                Icons.auto_awesome,
                color: LedgerTheme.accent,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Assistant',
              style: LedgerTheme.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: LedgerTheme.muted),
            onPressed: () => context.read<AssistantCubit>().clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<AssistantCubit, AssistantState>(
                listener: (_, __) => _jump(),
                builder: (context, state) {
                  final msgs = state.messages;
                  final isEmpty = msgs.isEmpty && !state.busy;
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount:
                        isEmpty ? 1 : msgs.length + (state.busy ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (isEmpty) {
                        return const _WelcomeBlock();
                      }
                      if (i >= msgs.length) {
                        return const _TypingBubble();
                      }
                      return _Bubble(msg: msgs[i]);
                    },
                  );
                },
              ),
            ),
            BlocBuilder<AssistantCubit, AssistantState>(
              buildWhen: (a, b) => a.messages.length != b.messages.length,
              builder: (context, state) {
                if (state.messages.length > 1) return const SizedBox.shrink();
                return Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8),
                        itemBuilder: (ctx, i) => ActionChip(
                          label: Text(_suggestions[i]),
                          backgroundColor: LedgerTheme.surface,
                          side: BorderSide(color: LedgerTheme.border),
                          labelStyle: LedgerTheme.bodyMedium
                              .copyWith(fontSize: 13),
                          onPressed: () => _send(_suggestions[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: LedgerTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Ceritakan ke Cuan…',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<AssistantCubit, AssistantState>(
                    buildWhen: (a, b) => a.listening != b.listening,
                    builder: (context, state) {
                      final listening = state.listening;
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: listening
                              ? LedgerTheme.rose
                              : LedgerTheme.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: LedgerTheme.border),
                        ),
                        child: IconButton(
                          icon: Icon(
                            listening ? Icons.stop : Icons.mic,
                            color: listening
                                ? Colors.white
                                : LedgerTheme.text,
                          ),
                          onPressed: _toggleListening,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<AssistantCubit, AssistantState>(
                    buildWhen: (a, b) => a.busy != b.busy,
                    builder: (context, state) {
                      // Also disable when the field is empty, so the button
                      // never looks tappable with nothing to send.
                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _ctrl,
                        builder: (context, value, _) {
                          final disabled =
                              state.busy || value.text.trim().isEmpty;
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: disabled
                                  ? LedgerTheme.surface2
                                  : LedgerTheme.accent,
                              shape: BoxShape.circle,
                              border: disabled
                                  ? Border.all(color: LedgerTheme.border)
                                  : null,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_upward,
                                color: disabled
                                    ? LedgerTheme.muted
                                    : LedgerTheme.bg,
                              ),
                              onPressed: disabled ? null : () => _send(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Designed empty-chat state — the AI greeting before the first message.
class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock();

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: LedgerTheme.surface2,
                shape: BoxShape.circle,
                border: Border.all(
                  color: LedgerTheme.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: LedgerTheme.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mau catat apa hari ini?',
              style: LedgerTheme.headlineMedium.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ceritakan pengeluaranmu dengan bahasa sehari-hari, saya yang mencatatnya.',
              style: LedgerTheme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.me) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(left: 64, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: LedgerTheme.accentDim,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: const Radius.circular(6),
            ),
          ),
          child: Text(
            msg.text,
            style: LedgerTheme.bodyMedium,
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(right: 48, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: LedgerTheme.surface,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: LedgerTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: LedgerTheme.bodyMedium.copyWith(height: 1.45),
            ),
            if (msg.transactions?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              ...msg.transactions!.map((t) => _TxCard(tx: t)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx['type'] == 'income';
    final amount = ((tx['amount'] as num?)?.toDouble() ?? 0);
    return Container(
      margin: EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LedgerTheme.surface2,
        borderRadius: BorderRadius.circular(LedgerTheme.radiusTile),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isIncome ? LedgerTheme.income : LedgerTheme.expense,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (tx['description'] as String?) ?? '-',
              style: LedgerTheme.bodyMedium.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            idr(amount),
            style: LedgerTheme.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? LedgerTheme.income : LedgerTheme.expense,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(right: 48, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: LedgerTheme.surface,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: LedgerTheme.border),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_c.value * 3 - i).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LedgerTheme.accent.withValues(alpha: 0.3 + 0.7 * t),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
