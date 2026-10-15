import '../../../core/api/cuan_api.dart';

/// Savings goals data layer.
class SavingsGoalRepository {
  Future<List<Map<String, dynamic>>> list() => api.savingsGoals();

  Future<void> create({
    required String name,
    required String targetAmount,
    String? deadline,
  }) =>
      api.createSavingsGoal({
        'name': name,
        'targetAmount': targetAmount,
        if (deadline != null) 'deadline': deadline,
      });

  Future<void> addFunds(String id, String amount) => api.addFunds(id, amount);

  Future<void> delete(String id) => api.deleteSavingsGoal(id);
}
