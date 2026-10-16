import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/animated_balance.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../settings/presentation/settings_page.dart';
import '../../shell/bloc/navigation_cubit.dart';
import '../../savings/presentation/savings_page.dart';
import '../../debts/presentation/debts_page.dart';
import '../../splitbill/presentation/split_bill_page.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import 'weekly_expense_chart.dart';
import 'health_score_card.dart';

/// Home — "one big object": balance hero → AI prompt → recent activity.
/// Deliberately NOT the web's KPI card grid.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 19
                ? 'Selamat sore'
                : 'Selamat malam';

    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: LedgerTheme.accent,
          backgroundColor: LedgerTheme.surface,
          onRefresh: () => context.read<HomeCubit>().load(),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state.status == HomeStatus.loading ||
                  state.status == HomeStatus.initial) {
                return const Center(
                  child: CircularProgressIndicator(color: LedgerTheme.accent),
                );
              }
              final recent = state.transactions;
              return ListView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: LedgerTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsPage(),
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: LedgerTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: LedgerTheme.border),
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: LedgerTheme.muted,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Hero card — the one big object. Serif balance, no glow.
                  FadeIn(
                      child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LedgerTheme.heroGradient,
                      borderRadius:
                          BorderRadius.circular(LedgerTheme.radiusHero),
                      border: Border.all(
                        color: LedgerTheme.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LedgerTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Total saldo',
                                style: TextStyle(
                                  color: LedgerTheme.onAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        AnimatedBalance(
                          value: state.total,
                          // Hero card bg is always dark — keep text light.
                          color: const Color(0xFFF2F5F3),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${state.accounts.length} akun terhubung',
                          style: TextStyle(
                            color:
                                const Color(0xFFF2F5F3).withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  // AI prompt bar — the super power, one tap away.
                  FadeIn(
                    delay: const Duration(milliseconds: 80),
                    child: _AiPromptBar(onTap: () => _goAssistant(context)),
                  ),
                  const SizedBox(height: 16),
                  // Quick actions — savings, debts, split bill.
                  // Single consistent treatment: solid tile, accent icon.
                  Row(
                    children: [
                      _quickAction(
                        context,
                        Icons.savings_outlined,
                        'Target',
                        const SavingsPage(),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        context,
                        Icons.handshake_outlined,
                        'Hutang',
                        const DebtsPage(),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        context,
                        Icons.groups_outlined,
                        'Patungan',
                        const SplitBillPage(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MonthStrip(stats: state.monthlyStats),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terakhir',
                        style: TextStyle(
                          color: LedgerTheme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<NavigationCubit>().selectTab(1),
                        child: Text(
                          'Lihat semua',
                          style: TextStyle(
                              color: LedgerTheme.accent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (recent.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi.\nCeritakan ke Cuan lewat chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: LedgerTheme.muted),
                        ),
                      ),
                    )
                  else ...[
                    WeeklyExpenseChart(transactions: recent),
                    const SizedBox(height: 12),
                    const HealthScoreCard(),
                    const SizedBox(height: 16),
                    ...recent.take(6).map((t) => TransactionTile(tx: t)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _goAssistant(BuildContext context) {
    context.read<NavigationCubit>().selectTab(2);
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => page),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: LedgerTheme.surface,
            borderRadius: BorderRadius.circular(LedgerTheme.radiusTile),
            border: Border.all(color: LedgerTheme.border),
          ),
          child: Column(
            children: [
              GradientAvatar.solid(
                icon: icon,
                iconColor: LedgerTheme.accent,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: LedgerTheme.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPromptBar extends StatelessWidget {
  final VoidCallback onTap;
  const _AiPromptBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: LedgerTheme.accentGradient,
          borderRadius: BorderRadius.circular(LedgerTheme.radiusCard),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: LedgerTheme.surface,
            borderRadius: BorderRadius.circular(LedgerTheme.radiusTile),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LedgerTheme.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: LedgerTheme.onAccent,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ceritakan pengeluaranmu…',
                  style: TextStyle(color: LedgerTheme.muted, fontSize: 14),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: LedgerTheme.accent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthStrip extends StatelessWidget {
  /// Real monthly stats from /api/transactions/stats — empty if unavailable.
  final Map<String, double> stats;
  const _MonthStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final income = stats['income'] ?? 0;
    final expense = stats['expense'] ?? 0;
    final net = stats['net'] ?? (income - expense);
    final now = DateTime.now();
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: LedgerTheme.surface,
        borderRadius: BorderRadius.circular(LedgerTheme.radiusCard),
        border: Border.all(color: LedgerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulan ini · ${months[now.month]} ${now.year}',
            style: TextStyle(
              color: LedgerTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(
                    'Masuk', income, LedgerTheme.income, Icons.arrow_upward),
              ),
              Container(width: 1, height: 40, color: LedgerTheme.border),
              Expanded(
                child: _stat('Keluar', expense, LedgerTheme.expense,
                    Icons.arrow_downward),
              ),
              Container(width: 1, height: 40, color: LedgerTheme.border),
              Expanded(
                child: _stat('Bersih', net, LedgerTheme.text, Icons.balance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: LedgerTheme.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          idrCompact(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
