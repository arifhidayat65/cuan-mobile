import '../../../core/api/cuan_api.dart';

/// Budgets data layer.
class BudgetsRepository {
  Future<List<Map<String, dynamic>>> budgets(String month) =>
      api.budgets(month);

  Future<List<Map<String, dynamic>>> categories() => api.categories();

  Future<void> createBudget({
    required int categoryId,
    required double limit,
    required String month,
  }) =>
      api.createBudget(categoryId: categoryId, limit: limit, month: month);
}
