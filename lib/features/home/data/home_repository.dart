import '../../../core/api/cuan_api.dart';

/// Home data layer — accounts + recent transactions.
class HomeRepository {
  Future<List<Map<String, dynamic>>> accounts() => api.accounts();

  Future<List<Map<String, dynamic>>> recentTransactions({int limit = 8}) =>
      api.transactions(limit: limit);

  /// Real monthly stats for the summary strip (current month).
  Future<Map<String, double>> monthlyStats() {
    final now = DateTime.now();
    final from = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final to =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    return api.transactionStats(from: from, to: to);
  }
}
