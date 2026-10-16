import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/load_error.dart';
import '../data/activity_repository.dart';
import 'activity_state.dart';

/// Transaction ledger with filter chips + search.
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit(this._repo) : super(const ActivityState());

  final ActivityRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: ActivityStatus.loading));
    try {
      final txs = await _repo.transactions();
      emit(state.copyWith(status: ActivityStatus.loaded, transactions: txs));
    } catch (e) {
      final err = classifyLoadError(e);
      emit(
        state.copyWith(
          status: ActivityStatus.error,
          errorMessage: err.message,
          sessionExpired: err.sessionExpired,
        ),
      );
    }
  }

  void setFilter(String filter) => emit(state.copyWith(filter: filter));

  void setQuery(String query) => emit(state.copyWith(query: query));
}
