import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/ledger_fab.dart';
import '../bloc/recurring_cubit.dart';
import '../bloc/recurring_form_cubit.dart';
import '../bloc/recurring_state.dart';
import '../data/recurring_repository.dart';

/// Recurring transactions page — list + create + toggle + delete.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  static const _freqLabels = {
    'daily': 'Harian',
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecurringCubit(RecurringRepository())..load(),
      child: Scaffold(
        backgroundColor: LedgerTheme.bg,
        appBar: AppBar(
          backgroundColor: LedgerTheme.bg,
          elevation: 0,
          title: Text(
            'Transaksi Berulang',
            style: LedgerTheme.displaySerif(26),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Generate sekarang',
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  final n = await ctx.read<RecurringCubit>().generateNow();
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          n > 0
                              ? '$n transaksi dibuat'
                              : 'Tidak ada yang jatuh tempo',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) => LedgerFab(
            onPressed: () => _showCreateSheet(ctx),
          ),
        ),
        body: BlocBuilder<RecurringCubit, RecurringState>(
          builder: (context, state) {
            if (state.status == RecurringStatus.loading ||
                state.status == RecurringStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              );
            }
            if (state.items.isEmpty) {
              return EmptyState(
                icon: Icons.repeat,
                message:
                    'Belum ada transaksi berulang.\nTambahkan gaji, langganan, atau cicilan.',
                actionLabel: 'Tambah',
                onAction: () => _showCreateSheet(context),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: state.items.length,
              itemBuilder: (_, i) {
                final r = state.items[i];
                final active = (r['isActive'] as num?)?.toInt() == 1;
                final isIncome = r['type'] == 'income';
                return FadeIn(
                  delay: Duration(milliseconds: (i % 8) * 40),
                  child: Dismissible(
                    key: ValueKey(r['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: LedgerTheme.rose.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          Icon(Icons.delete_outline, color: LedgerTheme.rose),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: LedgerTheme.surface,
                              title: Text('Hapus?',
                                  style: LedgerTheme.displaySerif(22)),
                              content:
                                  Text('Hapus "${r['description']}" permanen?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(color: LedgerTheme.rose),
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) => context
                        .read<RecurringCubit>()
                        .remove(r['id'] as String),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: LedgerTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LedgerTheme.border),
                      ),
                      child: Row(
                        children: [
                          GradientAvatar.solid(
                            icon: isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            iconColor: isIncome
                                ? LedgerTheme.income
                                : LedgerTheme.expense,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${r['description']}',
                                  style: TextStyle(
                                    color: LedgerTheme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_freqLabels[r['frequency']] ?? r['frequency']} • ${idr(num.tryParse('${r['amount']}') ?? 0)}',
                                  style: TextStyle(
                                    color: LedgerTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: active,
                            activeThumbColor: LedgerTheme.accent,
                            onChanged: (v) => context
                                .read<RecurringCubit>()
                                .toggleActive(r['id'] as String, v),
                          ),
                        ],
                      ),
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
      // M5: theme radius (28) — no manual override.
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<RecurringCubit>()),
          BlocProvider(create: (_) => RecurringFormCubit()),
        ],
        child: const _CreateRecurringSheet(),
      ),
    );
  }
}

class _CreateRecurringSheet extends StatefulWidget {
  const _CreateRecurringSheet();

  @override
  State<_CreateRecurringSheet> createState() => _CreateRecurringSheetState();
}

class _CreateRecurringSheetState extends State<_CreateRecurringSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    // QA-003: controllers must survive rebuilds (e.g. keyboard open/close
    // re-invokes the bottom-sheet builder) — create once, dispose once.
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecurringFormCubit, RecurringFormState>(
      builder: (context, form) => Padding(
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
              'Transaksi Berulang Baru',
              style: LedgerTheme.displaySerif(22),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Keluar')),
                ButtonSegment(value: 'income', label: Text('Masuk')),
              ],
              selected: {form.type},
              onSelectionChanged: (s) =>
                  context.read<RecurringFormCubit>().setType(s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (mis. Gaji, Netflix)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: form.frequency,
              decoration: const InputDecoration(
                labelText: 'Frekuensi',
                border: OutlineInputBorder(),
              ),
              items: RecurringPage._freqLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => context
                  .read<RecurringFormCubit>()
                  .setFrequency(v ?? 'monthly'),
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
                  final desc = _descCtrl.text.trim();
                  final amount = _amountCtrl.text.trim();
                  if (desc.isEmpty || amount.isEmpty) return;
                  final ok = await context.read<RecurringCubit>().create(
                        type: form.type,
                        amount: amount,
                        categoryId: 1,
                        description: desc,
                        frequency: form.frequency,
                        startDate:
                            DateTime.now().toIso8601String().split('T').first,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Berhasil ditambahkan' : 'Gagal'),
                      ),
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
}
