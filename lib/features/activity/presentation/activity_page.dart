import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../bloc/activity_cubit.dart';
import '../bloc/activity_state.dart';
import '../../recurring/presentation/recurring_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        title: Text('Activity', style: LedgerTheme.displaySerif(26)),
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                style: TextStyle(color: LedgerTheme.text),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi…',
                  prefixIcon: Icon(Icons.search, color: LedgerTheme.muted),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => context.read<ActivityCubit>().setQuery(v),
              ),
            ),
            BlocBuilder<ActivityCubit, ActivityState>(
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
                        ? Center(
                            child: Text(
                              'Tidak ada transaksi.',
                              style: TextStyle(color: LedgerTheme.muted),
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
        labelStyle: TextStyle(
          color: active ? LedgerTheme.accent : LedgerTheme.muted,
          fontSize: 13,
        ),
      ),
    );
  }
}
