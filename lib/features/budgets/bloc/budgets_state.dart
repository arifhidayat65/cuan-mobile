import 'package:equatable/equatable.dart';

enum BudgetsStatus { initial, loading, loaded, error }

/// Budgets screen state — monthly rings + category list for the add sheet.
final class BudgetsState extends Equatable {
  const BudgetsState({
    this.status = BudgetsStatus.initial,
    this.budgets = const [],
    this.categories = const [],
    this.saving = false,
    this.selectedCategoryId,
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final BudgetsStatus status;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> categories;
  final bool saving;
  final int? selectedCategoryId;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  BudgetsState copyWith({
    BudgetsStatus? status,
    List<Map<String, dynamic>>? budgets,
    List<Map<String, dynamic>>? categories,
    bool? saving,
    int? selectedCategoryId,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return BudgetsState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      categories: categories ?? this.categories,
      saving: saving ?? this.saving,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
        status,
        budgets,
        categories,
        saving,
        selectedCategoryId,
        errorMessage,
        sessionExpired,
      ];
}
