import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/cuan_api.dart';
import '../../../core/utils/load_error.dart';

/// Health score state.
class HealthScoreState {
  const HealthScoreState({this.data, this.loading = true, this.errorMessage});

  final Map<String, dynamic>? data;
  final bool loading;
  final String? errorMessage;

  HealthScoreState copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HealthScoreState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Fetches financial health score from /api/insights/health-score.
/// Replaces StatefulWidget setState — BLoC only.
class HealthScoreCubit extends Cubit<HealthScoreState> {
  HealthScoreCubit({
    Future<Map<String, dynamic>> Function(String month)? fetchHealthScore,
  })  : _fetch = fetchHealthScore ?? _defaultFetch,
        super(const HealthScoreState());

  final Future<Map<String, dynamic>> Function(String month) _fetch;

  static Future<Map<String, dynamic>> _defaultFetch(String month) =>
      api.healthScore(month);

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final data = await _fetch(month);
      emit(state.copyWith(data: data, loading: false));
    } catch (e) {
      // Explain the failure instead of silently hiding the card.
      emit(state.copyWith(
        loading: false,
        errorMessage: classifyLoadError(e).message,
      ));
    }
  }
}
