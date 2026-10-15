import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/savings_repository.dart';
import 'savings_state.dart';

class SavingsCubit extends Cubit<SavingsState> {
  SavingsCubit(this._repo) : super(const SavingsState());

  final SavingsGoalRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: SavingsStatus.loading));
    try {
      final items = await _repo.list();
      emit(state.copyWith(status: SavingsStatus.loaded, items: items));
    } catch (e) {
      emit(state.copyWith(status: SavingsStatus.error, error: '$e'));
    }
  }

  Future<bool> create({
    required String name,
    required String targetAmount,
    String? deadline,
  }) async {
    try {
      await _repo.create(
          name: name, targetAmount: targetAmount, deadline: deadline);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addFunds(String id, String amount) async {
    try {
      await _repo.addFunds(id, amount);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _repo.delete(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
