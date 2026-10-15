import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/ledger_fab.dart';
import '../bloc/debt_cubit.dart';
import '../bloc/debt_form_cubit.dart';
import '../bloc/debt_state.dart';
import '../data/debt_repository.dart';

/// Hutang & piutang page.
class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtCubit(DebtRepository())..load(),
      child: Scaffold(
        backgroundColor: LedgerTheme.bg,
        appBar: AppBar(
          backgroundColor: LedgerTheme.bg,
          elevation: 0,
          title: Text(
            'Hutang & Piutang',
            style: LedgerTheme.displaySerif(26),
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => LedgerFab(
            onPressed: () => _showCreateSheet(ctx),
          ),
        ),
        body: BlocBuilder<DebtCubit, DebtState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'hutang', label: Text('Hutang Saya')),
                      ButtonSegment(
                          value: 'piutang', label: Text('Piutang Saya')),
                    ],
                    selected: {state.filter},
                    onSelectionChanged: (s) =>
                        context.read<DebtCubit>().setFilter(s.first),
                  ),
                ),
                Expanded(
                  child: _buildList(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, DebtState state) {
    if (state.status == DebtStatus.loading ||
        state.status == DebtStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: LedgerTheme.accent),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_outlined,
        message: state.filter == 'hutang'
            ? 'Tidak ada hutang.\nBagus, pertahankan!'
            : 'Tidak ada piutang.',
        actionLabel: 'Catat',
        onAction: () => _showCreateSheet(context),
      );
    }
    final isHutang = state.filter == 'hutang';
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: state.items.length,
      itemBuilder: (_, i) {
        final d = state.items[i];
        final amount = (num.tryParse('${d['amount']}') ?? 0).toDouble();
        final paid = (num.tryParse('${d['paidAmount']}') ?? 0).toDouble();
        final remaining = amount - paid;
        final settled = d['isSettled'] == 1 || remaining <= 0;
        return FadeIn(
          delay: Duration(milliseconds: (i % 8) * 40),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LedgerTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LedgerTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GradientAvatar.solid(
                      icon:
                          isHutang ? Icons.arrow_upward : Icons.arrow_downward,
                      iconColor: isHutang
                          ? LedgerTheme.expense
                          : LedgerTheme.income,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d['personName']}',
                            style: TextStyle(
                              color: LedgerTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ('${d['description']}'.isNotEmpty)
                            Text(
                              '${d['description']}',
                              style: TextStyle(
                                color: LedgerTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          idr(remaining),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                settled ? LedgerTheme.muted : LedgerTheme.text,
                          ),
                        ),
                        Text(
                          settled ? 'Lunas' : 'Sisa',
                          style: TextStyle(
                            fontSize: 11,
                            color: settled
                                ? LedgerTheme.income
                                : LedgerTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!settled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LedgerTheme.accent,
                            side: BorderSide(color: LedgerTheme.accent),
                          ),
                          onPressed: () =>
                              _showPay(context, d['id'] as String, isHutang),
                          child: Text(isHutang ? 'Bayar' : 'Terima'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: LedgerTheme.muted, size: 20),
                        onPressed: () =>
                            context.read<DebtCubit>().remove(d['id'] as String),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final initialType = context.read<DebtCubit>().state.filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerTheme.surface,
      // M5: use theme radius (28) + drag handle.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => DebtFormCubit(initialType),
        child: BlocBuilder<DebtFormCubit, String>(
          builder: (ctx, type) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                Text('Catat Baru', style: LedgerTheme.displaySerif(22)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'hutang', label: Text('Hutang')),
                    ButtonSegment(value: 'piutang', label: Text('Piutang')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) =>
                      ctx.read<DebtFormCubit>().setType(s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama orang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal (Rp)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (opsional)',
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
                          amountCtrl.text.trim().isEmpty) return;
                      final ok = await context.read<DebtCubit>().create(
                            type: type,
                            personName: nameCtrl.text.trim(),
                            amount: amountCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Tersimpan' : 'Gagal')),
                        );
                      }
                    },
                    child: Text('Simpan',
                        style: TextStyle(
                            color: LedgerTheme.text,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPay(BuildContext context, String id, bool isHutang) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        title: Text(
          isHutang ? 'Bayar hutang' : 'Terima piutang',
          style: LedgerTheme.displaySerif(22),
        ),
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
              await context.read<DebtCubit>().pay(id, ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
