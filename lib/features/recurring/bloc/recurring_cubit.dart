import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/load_error.dart';
import '../data/recurring_repository.dart';
import 'recurring_state.dart';

/// Recurring transactions cubit.
class RecurringCubit extends Cubit<RecurringState> {
  RecurringCubit(this._repo) : super(const RecurringState());

  final RecurringRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: RecurringStatus.loading));
    try {
      final items = await _repo.list();
      emit(state.copyWith(status: RecurringStatus.loaded, items: items));
    } catch (e) {
      final err = classifyLoadError(e);
      emit(
        state.copyWith(
          status: RecurringStatus.error,
          errorMessage: err.message,
          sessionExpired: err.sessionExpired,
        ),
      );
    }
  }

  Future<bool> create({
    required String type,
    required String amount,
    required int categoryId,
    String? accountId,
    required String description,
    required String frequency,
    int interval = 1,
    required String startDate,
    String? endDate,
  }) async {
    try {
      await _repo.create(
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        description: description,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool active) async {
    try {
      await _repo.update(id, {'isActive': active});
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

  /// Trigger manual generation of due transactions. Returns count generated.
  Future<int> generateNow() async {
    try {
      final count = await _repo.generate();
      await load();
      return count;
    } catch (_) {
      return 0;
    }
  }
}
