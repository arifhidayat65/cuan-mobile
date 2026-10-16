import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../bloc/accounts_cubit.dart';

/// Bottom sheet: add a financial account (Task 14 — QA audit MEDIUM).
/// Opens from the Accounts page FAB; the page's [AccountsCubit] reloads
/// the list itself, so this sheet just reports success.
class AddAccountSheet extends StatelessWidget {
  const AddAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<AccountsCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _AddAccountForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const _AddAccountForm();
}

/// Backend account types with Indonesian labels.
const _accountTypes = <String, String>{
  'bank': 'Bank',
  'e-wallet': 'E-Wallet',
  'cash': 'Tunai',
  'other': 'Lainnya',
};

class _AddAccountForm extends StatefulWidget {
  const _AddAccountForm();

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  String _type = 'e-wallet';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama akun wajib diisi.');
      return;
    }
    final balanceText = _balance.text.trim().replaceAll('.', '');
    final balance =
        balanceText.isEmpty ? null : double.tryParse(balanceText);
    if (balanceText.isNotEmpty && (balance == null || balance < 0)) {
      setState(() => _error = 'Saldo awal tidak valid.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context.read<AccountsCubit>().createAccount(
          name: name,
          type: _type,
          initialBalance: balance,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = 'Gagal menyimpan akun. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Tambah akun', style: LedgerTheme.displaySerif(22)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: LedgerTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Nama akun (mis. DANA)',
              prefixIcon: Icon(
                Icons.account_balance_wallet_outlined,
                color: LedgerTheme.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use — consistent with other sheets
            initialValue: _type,
            items: _accountTypes.entries
                .map((e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value,
                          style: TextStyle(color: LedgerTheme.text)),
                    ))
                .toList(),
            onChanged: _saving ? null : (v) => setState(() => _type = v!),
            decoration: const InputDecoration(hintText: 'Tipe akun'),
            dropdownColor: LedgerTheme.surface2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balance,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: LedgerTheme.bodyLarge.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: 'Saldo awal (Rp, opsional)',
              prefixIcon: Icon(
                Icons.payments_outlined,
                color: LedgerTheme.muted,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: LedgerTheme.caption.copyWith(color: LedgerTheme.expense),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: LedgerTheme.accent,
                foregroundColor: LedgerTheme.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: LedgerTheme.onAccent,
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
  }
}
