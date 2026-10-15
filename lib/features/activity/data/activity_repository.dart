import '../../../core/api/cuan_api.dart';

/// Activity data layer — transaction ledger.
class ActivityRepository {
  Future<List<Map<String, dynamic>>> transactions({int limit = 100}) =>
      api.transactions(limit: limit);
}
