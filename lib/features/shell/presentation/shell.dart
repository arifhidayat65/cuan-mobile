import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../accounts/presentation/accounts_page.dart';
import '../../activity/presentation/activity_page.dart';
import '../../assistant/presentation/assistant_page.dart';
import '../../budgets/presentation/budgets_page.dart';
import '../../home/presentation/home_page.dart';
import '../../settings/bloc/theme_cubit.dart';
import '../bloc/navigation_cubit.dart';

/// Bottom navigation shell — Assistant is the raised centerpiece.
class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _screens = [
    HomePage(),
    ActivityPage(),
    AssistantPage(),
    BudgetsPage(),
    AccountsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, bool>(
      builder: (context, _) {
        return BlocBuilder<NavigationCubit, int>(
          builder: (context, index) {
            return Scaffold(
              backgroundColor: LedgerTheme.bg,
              body: IndexedStack(index: index, children: _screens),
              bottomNavigationBar: _LedgerNav(
                index: index,
                onTap: (i) => context.read<NavigationCubit>().selectTab(i),
              ),
            );
          },
        );
      },
    );
  }
}

class _LedgerNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _LedgerNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LedgerTheme.surface,
        border: Border(top: BorderSide(color: LedgerTheme.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.home_outlined, Icons.home, 'Home'),
              _item(1, Icons.receipt_long_outlined, Icons.receipt_long,
                  'Activity'),
              _assistantFab(),
              _item(3, Icons.pie_chart_outline, Icons.pie_chart, 'Budgets'),
              _item(4, Icons.wallet_outlined, Icons.wallet, 'Accounts'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData outlined, IconData filled, String label) {
    final active = index == i;
    return InkWell(
      onTap: () => onTap(i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? filled : outlined,
              size: 24,
              color: active ? LedgerTheme.accent : LedgerTheme.muted,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? LedgerTheme.text : LedgerTheme.muted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The "super power" — raised Assistant button at the center.
  Widget _assistantFab() {
    final active = index == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 60,
        height: 60,
        margin: EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? LedgerTheme.accent : LedgerTheme.accentDim,
          boxShadow: [
            BoxShadow(
              color: LedgerTheme.accent.withValues(alpha: 0.22),
              blurRadius: 14,
            ),
          ],
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 26,
          color: active ? LedgerTheme.bg : LedgerTheme.accent,
        ),
      ),
    );
  }
}
