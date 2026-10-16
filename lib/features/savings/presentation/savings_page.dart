import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state_card.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/ledger_fab.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/savings_cubit.dart';
import '../bloc/savings_state.dart';
import '../data/savings_repository.dart';

/// Savings goals page — target tabungan dengan progress.
class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SavingsCubit(SavingsGoalRepository())..load(),
      child: Scaffold(
        backgroundColor: LedgerTheme.bg,
        appBar: AppBar(
          backgroundColor: LedgerTheme.bg,
          elevation: 0,
          title: Text(
            'Target Tabungan',
            style: LedgerTheme.displaySerif(26),
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => LedgerFab(
            onPressed: () => _showCreateSheet(ctx),
          ),
        ),
        body: BlocConsumer<SavingsCubit, SavingsState>(
          listenWhen: (prev, curr) =>
              curr.sessionExpired && !prev.sessionExpired,
          listener: (context, _) {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
          builder: (context, state) {
            if (state.status == SavingsStatus.loading ||
                state.status == SavingsStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              );
            }
            if (state.status == SavingsStatus.error) {
              return ErrorStateCard(
                message: state.errorMessage,
                onRetry: () => context.read<SavingsCubit>().load(),
              );
            }
            if (state.items.isEmpty) {
              return EmptyState(
                icon: Icons.savings_outlined,
                message: 'Belum ada target.\nBuat target tabungan pertamamu!',
                actionLabel: 'Buat target',
                onAction: () => _showCreateSheet(context),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: state.items.length,
              itemBuilder: (_, i) {
                final g = state.items[i];
                final target =
                    (num.tryParse('${g['targetAmount']}') ?? 0).toDouble();
                final current =
                    (num.tryParse('${g['currentAmount']}') ?? 0).toDouble();
                final progress =
                    target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
                final completed = g['isCompleted'] == 1 || progress >= 1.0;
                return FadeIn(
                  delay: Duration(milliseconds: (i % 8) * 40),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LedgerTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LedgerTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GradientAvatar.solid(
                              icon: completed
                                  ? Icons.check
                                  : Icons.savings_outlined,
                              iconColor: completed
                                  ? LedgerTheme.income
                                  : LedgerTheme.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${g['name']}',
                                    style: LedgerTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${idr(current)} / ${idr(target)}',
                                    style: LedgerTheme.caption.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (completed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: LedgerTheme.income
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tercapai',
                                  style: LedgerTheme.caption.copyWith(
                                    color: LedgerTheme.income,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: LedgerTheme.muted,
                                  size: 20,
                                ),
                                onPressed: () => context
                                    .read<SavingsCubit>()
                                    .remove(g['id'] as String),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                LedgerTheme.muted.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(
                              completed
                                  ? LedgerTheme.income
                                  : LedgerTheme.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: LedgerTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              'Sisa ${idr(target - current)}',
                              style: LedgerTheme.caption,
                            ),
                          ],
                        ),
                        if (!completed) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: Text('Tambah dana'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LedgerTheme.accent,
                                side:
                                    const BorderSide(color: LedgerTheme.accent),
                              ),
                              onPressed: () =>
                                  _showAddFunds(context, g['id'] as String),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerTheme.surface,
      // M5: theme radius (28) + drag handle.
      builder: (_) => const _CreateSavingsSheet(),
    );
  }

  void _showAddFunds(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => _AddFundsDialog(id: id),
    );
  }
}

/// QA-003: sheet content as StatefulWidget so controllers survive rebuilds
/// (keyboard open/close re-invokes the bottom-sheet builder).
class _CreateSavingsSheet extends StatefulWidget {
  const _CreateSavingsSheet();

  @override
  State<_CreateSavingsSheet> createState() => _CreateSavingsSheetState();
}

class _CreateSavingsSheetState extends State<_CreateSavingsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LedgerTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Target Baru',
            style: LedgerTheme.displaySerif(22),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama (mis. DP Motor)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LedgerTheme.accent,
                foregroundColor: LedgerTheme.onAccent,
              ),
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty ||
                    _targetCtrl.text.trim().isEmpty) {
                  return;
                }
                final ok = await context.read<SavingsCubit>().create(
                      name: _nameCtrl.text.trim(),
                      targetAmount: _targetCtrl.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Target dibuat' : 'Gagal')),
                  );
                }
              },
              child: Text(
                'Simpan',
                // Inherits foregroundColor (onAccent) from the button style.
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// QA-003: dialog content as StatefulWidget so the controller survives
/// rebuilds and is properly disposed.
class _AddFundsDialog extends StatefulWidget {
  const _AddFundsDialog({required this.id});

  final String id;

  @override
  State<_AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<_AddFundsDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LedgerTheme.surface,
      title: Text('Tambah dana', style: LedgerTheme.displaySerif(22)),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Nominal (Rp)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LedgerTheme.accent,
            foregroundColor: LedgerTheme.onAccent,
          ),
          onPressed: () async {
            if (_ctrl.text.trim().isEmpty) return;
            await context
                .read<SavingsCubit>()
                .addFunds(widget.id, _ctrl.text.trim());
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
