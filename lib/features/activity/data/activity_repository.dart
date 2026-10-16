import '../../../core/api/cuan_api.dart';

/// Activity data layer — transaction ledger.
class ActivityRepository {
  Future<List<Map<String, dynamic>>> transactions({int limit = 100}) =>
      api.transactions(limit: limit);

  Future<List<Map<String, dynamic>>> categories() => api.categories();

  Future<List<Map<String, dynamic>>> accounts() => api.accounts();

  Future<void> createTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String accountId,
    String? description,
    String? date,
  }) =>
      api.createTransaction(
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
        description: description,
        date: date,
      );
}
