import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/home_repository.dart';
import 'home_state.dart';

/// Home data: accounts + recent transactions for the balance hero.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo) : super(const HomeState());

  final HomeRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final accounts = await _repo.accounts();
      final txs = await _repo.recentTransactions();
      final stats = await _repo.monthlyStats();
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          accounts: accounts,
          transactions: txs,
          monthlyStats: stats,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: HomeStatus.error));
    }
  }
}
