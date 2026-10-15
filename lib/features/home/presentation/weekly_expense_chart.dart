import 'package:flutter/material.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';

/// 7-day expense bar chart — computed client-side from transactions.
class WeeklyExpenseChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const WeeklyExpenseChart({super.key, required this.transactions});

  /// Aggregate expenses per day for the last 7 days.
  List<double> get _dailyTotals {
    final now = DateTime.now();
    final totals = List<double>.filled(7, 0);
    for (final tx in transactions) {
      if (tx['type'] != 'expense') continue;
      final dateStr = tx['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        totals[6 - diff] += amount;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _dailyTotals;
    final maxVal = totals.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxVal <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LedgerTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LedgerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengeluaran 7 hari',
            style: TextStyle(
                color: LedgerTheme.text,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final date = DateTime.now().subtract(Duration(days: 6 - i));
                final value = totals[i];
                final ratio = maxVal > 0 ? value / maxVal : 0.0;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Text(
                            idrCompact(value),
                            style: TextStyle(
                              fontSize: 9,
                              color: LedgerTheme.muted,
                            ),
                          ),
                        SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.04, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  // Today: brand accent. Others: quiet surface.
                                  // Data-first — no decorative purple bars.
                                  gradient: isToday
                                      ? LedgerTheme.accentGradient
                                      : null,
                                  color: isToday
                                      ? null
                                      : LedgerTheme.surface2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          ['S', 'S', 'R', 'K', 'J', 'S', 'M'][date.weekday % 7],
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? LedgerTheme.accent
                                : LedgerTheme.muted,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
