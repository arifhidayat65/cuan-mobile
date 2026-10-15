import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/cuan_api.dart';

/// Health score state.
class HealthScoreState {
  const HealthScoreState({this.data, this.loading = true});

  final Map<String, dynamic>? data;
  final bool loading;

  HealthScoreState copyWith({Map<String, dynamic>? data, bool? loading}) {
    return HealthScoreState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
    );
  }
}

/// Fetches financial health score from /api/insights/health-score.
/// Replaces StatefulWidget setState — BLoC only.
class HealthScoreCubit extends Cubit<HealthScoreState> {
  HealthScoreCubit() : super(const HealthScoreState());

  Future<void> load() async {
    try {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final data = await api.healthScore(month);
      emit(state.copyWith(data: data, loading: false));
    } catch (_) {
      // Silent — card just won't show.
      emit(state.copyWith(loading: false));
    }
  }
}
