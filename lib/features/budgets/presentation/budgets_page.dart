import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fade_in.dart';
import '../bloc/budgets_cubit.dart';
import '../bloc/budgets_state.dart';

/// Budgets — progress rings per category, not the web's progress bars.
/// Add via bottom sheet.
class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetsCubit>().load();
  }

  void _addSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetsCubit>(),
        child: const _AddBudgetSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        title: Text('Budgets', style: LedgerTheme.displaySerif(26)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: LedgerTheme.accent),
            onPressed: _addSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BudgetsCubit, BudgetsState>(
          builder: (context, state) {
            if (state.status == BudgetsStatus.loading ||
                state.status == BudgetsStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(color: LedgerTheme.accent),
              );
            }
            final budgets = state.budgets;
            return RefreshIndicator(
              color: LedgerTheme.accent,
              backgroundColor: LedgerTheme.surface,
              onRefresh: () => context.read<BudgetsCubit>().load(),
              child: budgets.isEmpty
                  ? EmptyState(
                      icon: Icons.pie_chart_outline,
                      message:
                          'Belum ada budget bulan ini.\n${monthLabel(now)}',
                      actionLabel: 'Buat budget pertama',
                      onAction: _addSheet,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.92,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: budgets.length,
                      itemBuilder: (ctx, i) => FadeIn(
                        delay: Duration(milliseconds: (i % 8) * 40),
                        child:
                            _BudgetRing(budget: budgets[i]),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetRing extends StatelessWidget {
  final Map<String, dynamic> budget;
  const _BudgetRing({required this.budget});

  @override
  Widget build(BuildContext context) {
    final limit = (double.tryParse(budget['amount']?.toString() ?? '') ??
        (budget['limit'] as num?)?.toDouble() ??
        1);
    final spent = ((budget['spent'] as num?)?.toDouble() ?? 0);
    final pct = (spent / limit).clamp(0.0, 1.0);
    final over = spent > limit;
    final name = (budget['category'] as String?) ??
        (budget['categoryName'] as String?) ??
        'Budget';
    final ringColor = over
        ? LedgerTheme.expense
        : LedgerTheme.accent;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LedgerTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LedgerTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 7,
                    backgroundColor: LedgerTheme.surface2,
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: LedgerTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LedgerTheme.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '${idrCompact(spent)} / ${idrCompact(limit)}',
            style: TextStyle(
              color: LedgerTheme.muted,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet();

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _limit = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BudgetsCubit>().loadCategories();
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save(int? catId) async {
    if (catId == null || _limit.text.isEmpty) return;
    final saved = await context.read<BudgetsCubit>().createBudget(
          categoryId: catId,
          limit: double.parse(_limit.text.replaceAll(RegExp(r'[^0-9]'), '')),
        );
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetsCubit, BudgetsState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LedgerTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Budget baru', style: LedgerTheme.displaySerif(22)),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: state.selectedCategoryId,
                items: state.categories
                    .map((c) => DropdownMenuItem<int>(
                          value: (c['id'] as num).toInt(),
                          child: Text(
                            (c['name'] as String?) ?? '-',
                            style: TextStyle(color: LedgerTheme.text),
                          ),
                        ))
                    .toList(),
                onChanged: (v) =>
                    context.read<BudgetsCubit>().selectCategory(v),
                decoration: InputDecoration(hintText: 'Pilih kategori'),
                dropdownColor: LedgerTheme.surface2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _limit,
                keyboardType: TextInputType.number,
                style: TextStyle(color: LedgerTheme.text),
                decoration: InputDecoration(
                  hintText: 'Batas bulanan (Rp)',
                  prefixIcon:
                      Icon(Icons.payments_outlined, color: LedgerTheme.muted),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: state.saving
                      ? null
                      : () => _save(state.selectedCategoryId),
                  style: FilledButton.styleFrom(
                    backgroundColor: LedgerTheme.accent,
                    foregroundColor: LedgerTheme.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: LedgerTheme.bg,
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: TextStyle(
                              color: LedgerTheme.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
