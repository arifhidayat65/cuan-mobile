import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../activity/data/activity_repository.dart';
import '../bloc/add_transaction_cubit.dart';
import '../bloc/add_transaction_state.dart';

/// Bottom sheet: manual add-transaction form (Task 13 — QA audit MEDIUM).
/// Opens from the Activity page FAB; returns true when a transaction was saved.
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider(
        create: (_) => AddTransactionCubit(ActivityRepository())..load(),
        child: const AddTransactionSheet(),
      ),
    );
    return saved == true;
  }

  @override
  Widget build(BuildContext context) => const _AddTransactionForm();
}

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm();

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  int? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: LedgerTheme.accent)
              .copyWith(primary: LedgerTheme.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final cubit = context.read<AddTransactionCubit>();
    final dateKey =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final ok = await cubit.submit(
      amountText: _amount.text,
      categoryId: _categoryId,
      accountId: _accountId,
      description: _description.text,
      date: dateKey,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      builder: (context, state) {
        final categories = categoriesForType(state.categories, state.type);
        // Reset category if it doesn't belong to the current type.
        if (_categoryId != null &&
            !categories.any((c) => (c['id'] as num).toInt() == _categoryId)) {
          _categoryId = null;
        }
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
              const SizedBox(height: 16),
              Text('Tambah transaksi', style: LedgerTheme.displaySerif(22)),
              const SizedBox(height: 16),
              _TypeToggle(
                type: state.type,
                onChanged: (t) {
                  context.read<AddTransactionCubit>().setType(t);
                  setState(() => _categoryId = null);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                style: LedgerTheme.bodyLarge.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: 'Nominal (Rp)',
                  prefixIcon:
                      Icon(Icons.payments_outlined, color: LedgerTheme.muted),
                ),
              ),
              const SizedBox(height: 12),
              if (state.status == AddTransactionStatus.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: LedgerTheme.accent),
                  ),
                )
              else ...[
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use — consistent with budgets sheet
                  initialValue: _categoryId,
                  items: categories
                      .map((c) => DropdownMenuItem<int>(
                            value: (c['id'] as num).toInt(),
                            child: Text(
                              (c['label'] as String?) ??
                                  (c['name'] as String?) ??
                                  '-',
                              style: TextStyle(color: LedgerTheme.text),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  decoration:
                      const InputDecoration(hintText: 'Pilih kategori'),
                  dropdownColor: LedgerTheme.surface2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use — consistent with budgets sheet
                  initialValue: _accountId,
                  items: state.accounts
                      .map((a) => DropdownMenuItem<String>(
                            value: a['id'] as String,
                            child: Text(
                              (a['name'] as String?) ?? '-',
                              style: TextStyle(color: LedgerTheme.text),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  decoration: const InputDecoration(hintText: 'Pilih akun'),
                  dropdownColor: LedgerTheme.surface2,
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: LedgerTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LedgerTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: LedgerTheme.muted, size: 20),
                      const SizedBox(width: 12),
                      Text(_formatDate(_date), style: LedgerTheme.bodyMedium),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: LedgerTheme.muted, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                style: LedgerTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Catatan (opsional)',
                  prefixIcon:
                      Icon(Icons.note_outlined, color: LedgerTheme.muted),
                ),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: LedgerTheme.caption.copyWith(color: LedgerTheme.expense),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      state.status == AddTransactionStatus.saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: LedgerTheme.accent,
                    foregroundColor: LedgerTheme.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state.status == AddTransactionStatus.saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: LedgerTheme.bg,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
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

/// Keluar / Masuk segmented toggle.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LedgerTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LedgerTheme.border),
      ),
      child: Row(
        children: [
          _option('expense', 'Keluar', Icons.arrow_downward, LedgerTheme.expense),
          _option('income', 'Masuk', Icons.arrow_upward, LedgerTheme.income),
        ],
      ),
    );
  }

  Widget _option(String value, String label, IconData icon, Color color) {
    final active = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? LedgerTheme.accentDim : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? LedgerTheme.accent : LedgerTheme.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: LedgerTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: active ? LedgerTheme.text : LedgerTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
