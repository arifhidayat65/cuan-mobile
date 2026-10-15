import '../../../core/api/cuan_api.dart';

/// Accounts data layer.
class AccountsRepository {
  Future<List<Map<String, dynamic>>> accounts() => api.accounts();
}
