import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/activity_repository.dart';
import 'add_transaction_state.dart';

/// Income-like category names — matched by name since the backend has no
/// category `type` field (same regex as the web budget dialog).
final _incomeLike =
    RegExp(r'gaji|salary|bonus|pendapatan|income|pemasukan|investasi|hadiah',
        caseSensitive: false);

/// Filter categories by transaction type: expense shows non-income
/// categories, income shows only income-like ones.
List<Map<String, dynamic>> categoriesForType(
    List<Map<String, dynamic>> categories, String type) {
  return categories.where((c) {
    final name = '${c['name'] ?? c['label'] ?? ''}';
    final isIncomeLike = _incomeLike.hasMatch(name);
    return type == 'income' ? isIncomeLike : !isIncomeLike;
  }).toList();
}

/// Manual add-transaction form logic (Task 13 — QA audit MEDIUM finding).
class AddTransactionCubit extends Cubit<AddTransactionState> {
  AddTransactionCubit(this._repo) : super(const AddTransactionState());

  final ActivityRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: AddTransactionStatus.loading));
    try {
      final cats = await _repo.categories();
      final accs = await _repo.accounts();
      emit(state.copyWith(
        status: AddTransactionStatus.ready,
        categories: cats,
        accounts: accs,
        errorMessage: null,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AddTransactionStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi lalu coba lagi.',
      ));
    }
  }

  void setType(String type) {
    if (type != 'expense' && type != 'income') return;
    emit(state.copyWith(type: type));
  }

  void clearError() => emit(state.copyWith(errorMessage: null));

  /// Validates and submits. Returns true on success.
  Future<bool> submit({
    required String amountText,
    required int? categoryId,
    required String? accountId,
    required String? description,
    required String date,
  }) async {
    final amount = double.tryParse(
      amountText.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      emit(state.copyWith(
        status: AddTransactionStatus.failure,
        errorMessage: 'Nominal harus lebih dari 0.',
      ));
      return false;
    }
    if (categoryId == null) {
      emit(state.copyWith(
        status: AddTransactionStatus.failure,
        errorMessage: 'Pilih kategori dulu.',
      ));
      return false;
    }
    if (accountId == null || accountId.isEmpty) {
      emit(state.copyWith(
        status: AddTransactionStatus.failure,
        errorMessage: 'Pilih akun dulu.',
      ));
      return false;
    }
    emit(state.copyWith(
        status: AddTransactionStatus.saving, errorMessage: null));
    try {
      await _repo.createTransaction(
        type: state.type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        description: description?.trim().isEmpty == true ? null : description,
        date: date,
      );
      emit(state.copyWith(status: AddTransactionStatus.success));
      return true;
    } catch (_) {
      emit(state.copyWith(
        status: AddTransactionStatus.failure,
        errorMessage: 'Gagal menyimpan. Periksa koneksi lalu coba lagi.',
      ));
      return false;
    }
  }
}
