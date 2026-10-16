import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fade_in.dart';
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
              ],
            );
          },
        ),
      ),
    );
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
