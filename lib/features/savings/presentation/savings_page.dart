import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/ledger_fab.dart';
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
        body: BlocBuilder<SavingsCubit, SavingsState>(
          builder: (context, state) {
            if (state.status == SavingsStatus.loading ||
                state.status == SavingsStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
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
                                    style: TextStyle(
                                      color: LedgerTheme.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${idr(current)} / ${idr(target)}',
                                    style: TextStyle(
                                      color: LedgerTheme.muted,
                                      fontSize: 12,
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
                                  style: TextStyle(
                                    color: LedgerTheme.income,
                                    fontSize: 11,
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
                              style: TextStyle(
                                color: LedgerTheme.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Sisa ${idr(target - current)}',
                              style: TextStyle(
                                color: LedgerTheme.muted,
                                fontSize: 12,
                              ),
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
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerTheme.surface,
      // M5: theme radius (28) + drag handle.
      builder: (_) => Padding(
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
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama (mis. DP Motor)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
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
                  if (nameCtrl.text.trim().isEmpty ||
                      targetCtrl.text.trim().isEmpty) return;
                  final ok = await context.read<SavingsCubit>().create(
                        name: nameCtrl.text.trim(),
                        targetAmount: targetCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Target dibuat' : 'Gagal')),
                    );
                  }
                },
                child: Text('Simpan',
                    style: TextStyle(
                        color: LedgerTheme.text, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFunds(BuildContext context, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        title: Text('Tambah dana', style: LedgerTheme.displaySerif(22)),
        content: TextField(
          controller: ctrl,
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
              if (ctrl.text.trim().isEmpty) return;
              await context.read<SavingsCubit>().addFunds(id, ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
