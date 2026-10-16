import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/accounts_cubit.dart';
import '../bloc/accounts_state.dart';

/// Accounts — stacked balance cards with per-account detail.
/// Sign out lives here (mobile convention).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        title: Text('Accounts', style: LedgerTheme.displaySerif(26)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: LedgerTheme.muted),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            if (state.status == AccountsStatus.loading ||
                state.status == AccountsStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              );
            }
            final accounts = state.accounts;
            return RefreshIndicator(
              color: LedgerTheme.accent,
              backgroundColor: LedgerTheme.surface,
              onRefresh: () => context.read<AccountsCubit>().load(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Total — stacked hero card.
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LedgerTheme.heroGradient,
                      borderRadius:
                          BorderRadius.circular(LedgerTheme.radiusHero),
                      border: Border.all(
                        color: LedgerTheme.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KEKAYAAN BERSIH',
                          style: LedgerTheme.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          idr(state.total),
                          style: LedgerTheme.displaySerif(34),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${accounts.length} akun terhubung',
                          style: LedgerTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...accounts
                      .asMap()
                      .entries
                      .map((e) => _AccountCard(account: e.value, index: e.key)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final int index;
  const _AccountCard({required this.account, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final type = (account['type'] as String?) ?? 'other';
    final icon = switch (type) {
      'bank' => Icons.account_balance_outlined,
      'e-wallet' => Icons.smartphone_outlined,
      'cash' => Icons.payments_outlined,
      _ => Icons.wallet_outlined,
    };
    final isDefault = account['isDefault'] == true;

    return FadeIn(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LedgerTheme.surface,
            borderRadius: BorderRadius.circular(LedgerTheme.radiusCard),
            border: Border.all(color: LedgerTheme.border),
          ),
          child: Row(
            children: [
              GradientAvatar.solid(
                icon: icon,
                iconColor: LedgerTheme.accent,
                size: 48,
                iconSize: 24,
                radius: LedgerTheme.radiusTile,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (account['name'] as String?) ?? '-',
                            style: LedgerTheme.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: LedgerTheme.accentDim,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'UTAMA',
                              style: TextStyle(
                                // Chip accentDim is mode-independent dark;
                                // pick readable foreground via theme helper.
                                color: LedgerTheme.foregroundForColor(
                                    LedgerTheme.accentDim),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      type,
                      style: LedgerTheme.caption,
                    ),
                  ],
                ),
              ),
              Text(
                idr((account['balance'] as num?)?.toDouble() ?? 0),
                style: LedgerTheme.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ));
  }
}
