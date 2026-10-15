import 'package:flutter/material.dart';
import '../utils/format.dart';
import '../theme/ledger_theme.dart';
import 'gradient_avatar.dart';

/// A single transaction row — flush list style, no card chrome.
class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool showDate;
  const TransactionTile({super.key, required this.tx, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx['type'] == 'income';
    final amount = ((tx['amount'] as num?)?.toDouble() ?? 0);
    final color = isIncome ? LedgerTheme.income : LedgerTheme.expense;
    final label = (tx['category'] as String?)?.isNotEmpty == true
        ? tx['category'] as String
        : (tx['description'] as String? ?? '-');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GradientAvatar.solid(
            icon: isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            iconColor: color,
            iconSize: 18,
            radius: LedgerTheme.radiusAvatar,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (tx['description'] as String?)?.isNotEmpty == true
                      ? tx['description'] as String
                      : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LedgerTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: LedgerTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '−'}${idr(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
