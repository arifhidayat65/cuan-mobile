import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/load_error.dart';
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
    } catch (e) {
      final err = classifyLoadError(e);
      emit(
        state.copyWith(
          status: AccountsStatus.error,
          errorMessage: err.message,
          sessionExpired: err.sessionExpired,
        ),
      );
    }
  }
}
