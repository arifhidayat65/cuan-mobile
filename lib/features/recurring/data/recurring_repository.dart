import '../../../core/api/cuan_api.dart';

/// Recurring transactions data layer.
class RecurringRepository {
  Future<List<Map<String, dynamic>>> list() => api.recurring();

  Future<void> create({
    required String type,
    required String amount,
    required int categoryId,
    String? accountId,
    required String description,
    required String frequency,
    int interval = 1,
    required String startDate,
    String? endDate,
  }) =>
      api.createRecurring({
        'type': type,
        'amount': amount,
        'categoryId': categoryId,
        if (accountId != null) 'accountId': accountId,
        'description': description,
        'frequency': frequency,
        'interval': interval,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });

  Future<void> update(String id, Map<String, dynamic> payload) =>
      api.updateRecurring(id, payload);

  Future<void> delete(String id) => api.deleteRecurring(id);

  Future<int> generate() => api.generateRecurring();
}
