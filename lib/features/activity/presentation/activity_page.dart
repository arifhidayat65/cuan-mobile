import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../bloc/activity_cubit.dart';
import '../bloc/activity_state.dart';
import '../../recurring/presentation/recurring_page.dart';
import 'add_transaction_sheet.dart';

/// Activity — transaction ledger with filter chips. Flush list, no cards.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityCubit>().load();
  }

  Future<void> _openAddSheet() async {
    final saved = await AddTransactionSheet.show(context);
    if (saved && mounted) context.read<ActivityCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        // Title style comes from the theme (displaySerif 26).
        title: const Text('Activity'),
        actions: [
          IconButton(
            tooltip: 'Transaksi berulang',
            icon: Icon(Icons.repeat),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RecurringPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: LedgerTheme.accent,
        foregroundColor: LedgerTheme.onAccent,
        tooltip: 'Tambah transaksi',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  style: LedgerTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi…',
                    prefixIcon: Icon(Icons.search, color: LedgerTheme.muted),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => context.read<ActivityCubit>().setQuery(v),
                ),
              ),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 60),
              duration: const Duration(milliseconds: 250),
              child: BlocBuilder<ActivityCubit, ActivityState>(
                buildWhen: (a, b) => a.filter != b.filter,
                builder: (context, state) {
                  return SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _chip(context, state, 'all', 'Semua'),
                        _chip(context, state, 'expense', 'Keluar'),
                        _chip(context, state, 'income', 'Masuk'),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<ActivityCubit, ActivityState>(
                builder: (context, state) {
                  if (state.status == ActivityStatus.loading ||
                      state.status == ActivityStatus.initial) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: LedgerTheme.accent),
                    );
                  }
                  final visible = state.visible;
                  return RefreshIndicator(
                    color: LedgerTheme.accent,
                    backgroundColor: LedgerTheme.surface,
                    onRefresh: () => context.read<ActivityCubit>().load(),
                    child: visible.isEmpty
                        ? FadeIn(
                            delay: const Duration(milliseconds: 120),
                            duration: const Duration(milliseconds: 250),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: LedgerTheme.surface2,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: LedgerTheme.border),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        color: LedgerTheme.muted,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada transaksi',
                                      style: LedgerTheme.headlineMedium
                                          .copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Catat pengeluaran lewat chat AI, dan semuanya akan tercatat di sini.',
                                      style: LedgerTheme.caption,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => Divider(
                              color: LedgerTheme.border,
                              height: 1,
                            ),
                            itemBuilder: (ctx, i) =>
                                TransactionTile(tx: visible[i]),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    ActivityState state,
    String value,
    String label,
  ) {
    final active = state.filter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => context.read<ActivityCubit>().setFilter(value),
        selectedColor: LedgerTheme.accentDim,
        backgroundColor: LedgerTheme.surface,
        side: BorderSide(
          color: active ? LedgerTheme.accent : LedgerTheme.border,
        ),
        labelStyle: LedgerTheme.bodyMedium.copyWith(
          // Selected chip label keeps the accent: it IS the interactive
          // control's selected state, not body copy.
          color: active ? LedgerTheme.accent : LedgerTheme.muted,
          fontSize: 13,
        ),
      ),
    );
  }
}
