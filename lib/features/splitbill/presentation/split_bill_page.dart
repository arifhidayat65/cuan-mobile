import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fade_in.dart';
import '../../debts/presentation/debts_page.dart';
import '../bloc/split_bill_cubit.dart';

/// Split bill calculator — patungan makan bareng.
class SplitBillPage extends StatelessWidget {
  const SplitBillPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplitBillCubit(),
      child: Scaffold(
        backgroundColor: LedgerTheme.bg,
        appBar: AppBar(
          backgroundColor: LedgerTheme.bg,
          elevation: 0,
          title: Text(
            'Split Bill',
            style: LedgerTheme.displaySerif(26),
          ),
        ),
        body: BlocBuilder<SplitBillCubit, SplitBillState>(
          builder: (context, state) {
            final cubit = context.read<SplitBillCubit>();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total tagihan (Rp)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  onChanged: cubit.setTotal,
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah orang',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  onChanged: cubit.setPeople,
                ),
                const SizedBox(height: 24),
                _sliderRow(
                  'Pajak & servis',
                  state.taxPercent,
                  cubit.setTax,
                ),
                _sliderRow(
                  'Tip',
                  state.tipPercent,
                  cubit.setTip,
                ),
                const SizedBox(height: 24),
                FadeIn(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LedgerTheme.accentGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _resultRow('Subtotal', idr(state.total),
                            LedgerTheme.onAccent.withValues(alpha: 0.7)),
                        _resultRow(
                            'Pajak (${state.taxPercent.toStringAsFixed(0)}%)',
                            idr(state.tax),
                            LedgerTheme.onAccent.withValues(alpha: 0.7)),
                        _resultRow(
                            'Tip (${state.tipPercent.toStringAsFixed(0)}%)',
                            idr(state.tip),
                            LedgerTheme.onAccent.withValues(alpha: 0.7)),
                        Divider(
                            color: LedgerTheme.onAccent.withValues(alpha: 0.2)),
                        _resultRow(
                          'Per orang (${state.people} orang)',
                          idr(state.perPerson),
                          LedgerTheme.onAccent,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Save the split as a piutang so it can be revisited
                // on the debts page.
                BlocBuilder<SplitBillCubit, SplitBillState>(
                  buildWhen: (p, c) =>
                      p.total != c.total ||
                      p.people != c.people ||
                      p.saving != c.saving,
                  builder: (context, s) {
                    final cubit = context.read<SplitBillCubit>();
                    final canSave = cubit.receivableAmount > 0 && !s.saving;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: LedgerTheme.accent,
                          foregroundColor: LedgerTheme.onAccent,
                          disabledBackgroundColor:
                              LedgerTheme.surface2,
                          disabledForegroundColor: LedgerTheme.muted,
                        ),
                        onPressed: canSave
                            ? () => _showSaveDialog(context, cubit)
                            : null,
                        icon: s.saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bookmark_add_outlined,
                                size: 20),
                        label: Text(
                          'Simpan sebagai piutang',
                          style: LedgerTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(
      BuildContext context, SplitBillCubit cubit) async {
    final labelCtrl = TextEditingController(text: 'Patungan');
    var saving = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: LedgerTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LedgerTheme.radiusCard),
          ),
          title: Text('Simpan split bill',
              style: LedgerTheme.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cubit.state.people - 1} orang berutang '
                '${idr(cubit.receivableAmount)} ke kamu.',
                style: LedgerTheme.bodyMedium.copyWith(
                  color: LedgerTheme.muted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  saving ? null : () => Navigator.pop(ctx, false),
              child: Text('Batal',
                  style: TextStyle(color: LedgerTheme.muted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LedgerTheme.accent,
                foregroundColor: LedgerTheme.onAccent,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      final saved =
                          await cubit.save(label: labelCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx, saved);
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    labelCtrl.dispose();
    if (!context.mounted) return;
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tersimpan di Piutang'),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DebtsPage()),
            ),
          ),
        ),
      );
    } else if (ok == false && cubit.state.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cubit.state.saveError!)),
      );
    }
  }

  Widget _sliderRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: LedgerTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600)),
            Text('${value.toStringAsFixed(0)}%',
                style: LedgerTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
        Slider(
          value: value,
          max: 25,
          divisions: 25,
          activeColor: LedgerTheme.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _resultRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: LedgerTheme.bodyMedium.copyWith(
                  color: color,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: LedgerTheme.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: bold ? 20 : 14)),
        ],
      ),
    );
  }
}
