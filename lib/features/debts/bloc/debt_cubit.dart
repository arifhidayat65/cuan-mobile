import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/debt_repository.dart';
import 'debt_state.dart';

class DebtCubit extends Cubit<DebtState> {
  DebtCubit(this._repo) : super(const DebtState());

  final DebtRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: DebtStatus.loading));
    try {
      final items = await _repo.list(type: state.filter);
      emit(state.copyWith(status: DebtStatus.loaded, items: items));
    } catch (_) {
      emit(state.copyWith(status: DebtStatus.error));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(filter: filter));
    load();
  }

  Future<bool> create({
    required String type,
    required String personName,
    required String amount,
    String? description,
  }) async {
    try {
      await _repo.create(
          type: type,
          personName: personName,
          amount: amount,
          description: description);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pay(String id, String amount) async {
    try {
      await _repo.pay(id, amount);
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
