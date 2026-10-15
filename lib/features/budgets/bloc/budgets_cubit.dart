import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format.dart';
import '../data/budgets_repository.dart';
import 'budgets_state.dart';

/// Monthly budget rings + add-budget sheet data.
class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit(this._repo) : super(const BudgetsState());

  final BudgetsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: BudgetsStatus.loading));
    try {
      final budgets = await _repo.budgets(monthKey(DateTime.now()));
      emit(state.copyWith(status: BudgetsStatus.loaded, budgets: budgets));
    } catch (_) {
      emit(state.copyWith(status: BudgetsStatus.error));
    }
  }

  Future<void> loadCategories() async {
    try {
      final cats = await _repo.categories();
      emit(state.copyWith(categories: cats));
    } catch (_) {
      // Sheet shows an empty dropdown — non-fatal.
    }
  }

  void selectCategory(int? id) => emit(state.copyWith(selectedCategoryId: id));

  /// Returns true when the budget was saved.
  Future<bool> createBudget(
      {required int categoryId, required double limit}) async {
    emit(state.copyWith(saving: true));
    try {
      await _repo.createBudget(
        categoryId: categoryId,
        limit: limit,
        month: monthKey(DateTime.now()),
      );
      emit(state.copyWith(saving: false));
      await load();
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false));
      return false;
    }
  }
}
