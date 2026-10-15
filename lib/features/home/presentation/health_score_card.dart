import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/fade_in.dart';
import '../bloc/health_score_cubit.dart';

/// Financial health score card — fetched from /api/insights/health-score.
class HealthScoreCard extends StatelessWidget {
  const HealthScoreCard({super.key});

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return LedgerTheme.accent;
      case 'B':
        return LedgerTheme.sky;
      case 'C':
        return LedgerTheme.amber;
      default:
        return LedgerTheme.rose;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HealthScoreCubit()..load(),
      child: BlocBuilder<HealthScoreCubit, HealthScoreState>(
        builder: (context, state) {
          if (state.loading) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LedgerTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LedgerTheme.border),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: LedgerTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          final score = (data['score'] as num).toInt();
          final grade = '${data['grade']}';
          final color = _gradeColor(grade);
          final tips = (data['tips'] as List?)?.cast<String>() ?? [];

          return FadeIn(
            child: Container(
              padding: const EdgeInsets.all(20),
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
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Skor Keuangan',
                                  style: TextStyle(
                                    color: LedgerTheme.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grade,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bulan ini',
                              style: TextStyle(
                                color: LedgerTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (tips.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...tips.take(2).map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 14,
                                  color: LedgerTheme.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: LedgerTheme.muted,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
