import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/accounts_repository.dart';
import 'accounts_state.dart';

/// Financial accounts list.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repo) : super(const AccountsState());

  final AccountsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: AccountsStatus.loading));
    try {
      final accounts = await _repo.accounts();
      emit(state.copyWith(status: AccountsStatus.loaded, accounts: accounts));
    } catch (_) {
      emit(state.copyWith(status: AccountsStatus.error));
    }
  }
}
