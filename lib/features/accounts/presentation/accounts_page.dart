import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/error_state_card.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/accounts_cubit.dart';
import '../bloc/accounts_state.dart';
import 'add_account_sheet.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddAccountSheet.show(context),
        backgroundColor: LedgerTheme.accent,
        foregroundColor: LedgerTheme.onAccent,
        tooltip: 'Tambah akun',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: BlocConsumer<AccountsCubit, AccountsState>(
          listenWhen: (prev, curr) =>
              curr.sessionExpired && !prev.sessionExpired,
          listener: (context, _) {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
          builder: (context, state) {
            if (state.status == AccountsStatus.loading ||
                state.status == AccountsStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              );
            }
            if (state.status == AccountsStatus.error) {
              return ErrorStateCard(
                message: state.errorMessage,
                onRetry: () => context.read<AccountsCubit>().load(),
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
                  ...accounts.asMap().entries.map(
                        (e) => _AccountCard(
                          account: e.value,
                          index: e.key,
                          onDelete: () => _confirmDelete(context, e.value),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Long-press delete with confirmation. Failures (e.g. account still has
  /// transactions, or the default account) surface through the cubit's
  /// error state, which the page already renders with a retry button.
  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> account) async {
    final name = (account['name'] as String?) ?? 'akun ini';
    final id = account['id'] as String?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Hapus akun?', style: LedgerTheme.headlineMedium),
        content: Text(
          '"$name" akan dihapus permanen.',
          style: LedgerTheme.bodyMedium.copyWith(color: LedgerTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: LedgerTheme.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: LedgerTheme.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AccountsCubit>().deleteAccount(id);
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final int index;
  final VoidCallback? onDelete;
  const _AccountCard({required this.account, this.index = 0, this.onDelete});

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

    return GestureDetector(
      onLongPress: onDelete,
      child: FadeIn(
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
        )),
  );
  }
}
