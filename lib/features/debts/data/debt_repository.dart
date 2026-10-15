import '../../../core/api/cuan_api.dart';

class DebtRepository {
  Future<List<Map<String, dynamic>>> list({String? type}) =>
      api.debts(type: type);

  Future<void> create({
    required String type,
    required String personName,
    required String amount,
    String? description,
    String? dueDate,
  }) =>
      api.createDebt({
        'type': type,
        'personName': personName,
        'amount': amount,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate,
      });

  Future<void> pay(String id, String amount) => api.payDebt(id, amount);

  Future<void> delete(String id) => api.deleteDebt(id);
}
