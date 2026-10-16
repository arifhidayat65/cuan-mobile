import '../../../core/api/cuan_api.dart';

/// Accounts data layer.
class AccountsRepository {
  Future<List<Map<String, dynamic>>> accounts() => api.accounts();

  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String type,
    double? initialBalance,
  }) =>
      api.createAccount(
        name: name,
        type: type,
        initialBalance: initialBalance,
      );

  Future<void> deleteAccount(String id) => api.deleteAccount(id);
}
