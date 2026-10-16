import 'package:cuan_mobile/features/activity/bloc/add_transaction_cubit.dart';
import 'package:cuan_mobile/features/activity/bloc/add_transaction_state.dart';
import 'package:cuan_mobile/features/activity/data/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository — records createTransaction calls, no network.
class _FakeActivityRepository extends ActivityRepository {
  final List<Map<String, dynamic>> calls = [];
  bool failLoad = false;
  bool failSubmit = false;

  @override
  Future<List<Map<String, dynamic>>> categories() async {
    if (failLoad) throw Exception('offline');
    return [
      {'id': 1, 'name': 'Gaji', 'label': 'Gaji'},
      {'id': 2, 'name': 'Makanan & Minuman', 'label': 'Makanan & Minuman'},
      {'id': 3, 'name': 'Bonus', 'label': 'Bonus'},
      {'id': 4, 'name': 'Transportasi', 'label': 'Transportasi'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> accounts() async {
    if (failLoad) throw Exception('offline');
    return [
      {'id': 'acc-1', 'name': 'Tunai'},
      {'id': 'acc-2', 'name': 'E-Wallet'},
    ];
  }

  @override
  Future<void> createTransaction({
    required String type,
    required double amount,
    required int categoryId,
    required String accountId,
    String? description,
    String? date,
  }) async {
    if (failSubmit) throw Exception('server error');
    calls.add({
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'description': description,
      'date': date,
    });
  }
}

AddTransactionCubit _cubit(_FakeActivityRepository repo) =>
    AddTransactionCubit(repo);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('categoriesForType', () {
    final cats = [
      {'id': 1, 'name': 'Gaji'},
      {'id': 2, 'name': 'Makanan & Minuman'},
      {'id': 3, 'name': 'Bonus'},
      {'id': 4, 'name': 'Transportasi'},
    ];

    test('expense excludes income-like categories', () {
      final result = categoriesForType(cats, 'expense');
      final names = result.map((c) => c['name']).toList();
      expect(names, contains('Makanan & Minuman'));
      expect(names, contains('Transportasi'));
      expect(names, isNot(contains('Gaji')));
      expect(names, isNot(contains('Bonus')));
    });

    test('income includes only income-like categories', () {
      final result = categoriesForType(cats, 'income');
      final names = result.map((c) => c['name']).toList();
      expect(names, contains('Gaji'));
      expect(names, contains('Bonus'));
      expect(names, isNot(contains('Makanan & Minuman')));
    });
  });

  group('AddTransactionCubit', () {
    test('load() populates categories and accounts', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      await cubit.load();
      expect(cubit.state.status, AddTransactionStatus.ready);
      expect(cubit.state.categories.length, 4);
      expect(cubit.state.accounts.length, 2);
      await cubit.close();
    });

    test('load() failure surfaces error message', () async {
      final repo = _FakeActivityRepository()..failLoad = true;
      final cubit = _cubit(repo);
      await cubit.load();
      expect(cubit.state.status, AddTransactionStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });

    test('setType switches type', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      expect(cubit.state.type, 'expense');
      cubit.setType('income');
      expect(cubit.state.type, 'income');
      await cubit.close();
    });

    test('submit rejects empty amount without calling API', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      await cubit.load();
      final ok = await cubit.submit(
        amountText: '',
        categoryId: 2,
        accountId: 'acc-1',
        description: 'kopi',
        date: '2026-10-16',
      );
      expect(ok, isFalse);
      expect(repo.calls, isEmpty);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });

    test('submit rejects zero/negative amount without calling API', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      await cubit.load();
      for (final bad in ['0', '-5000', 'abc']) {
        final ok = await cubit.submit(
          amountText: bad,
          categoryId: 2,
          accountId: 'acc-1',
          description: null,
          date: '2026-10-16',
        );
        expect(ok, isFalse, reason: 'amount=$bad');
      }
      expect(repo.calls, isEmpty);
      await cubit.close();
    });

    test('submit rejects missing category/account without calling API', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      await cubit.load();
      var ok = await cubit.submit(
        amountText: '25000',
        categoryId: null,
        accountId: 'acc-1',
        description: null,
        date: '2026-10-16',
      );
      expect(ok, isFalse);
      ok = await cubit.submit(
        amountText: '25000',
        categoryId: 2,
        accountId: null,
        description: null,
        date: '2026-10-16',
      );
      expect(ok, isFalse);
      expect(repo.calls, isEmpty);
      await cubit.close();
    });

    test('submit calls API with correct params and succeeds', () async {
      final repo = _FakeActivityRepository();
      final cubit = _cubit(repo);
      await cubit.load();
      cubit.setType('income');
      final ok = await cubit.submit(
        amountText: '50000',
        categoryId: 1,
        accountId: 'acc-2',
        description: 'gaji lembur',
        date: '2026-10-16',
      );
      expect(ok, isTrue);
      expect(cubit.state.status, AddTransactionStatus.success);
      expect(repo.calls.length, 1);
      final call = repo.calls.single;
      expect(call['type'], 'income');
      expect(call['amount'], 50000.0);
      expect(call['categoryId'], 1);
      expect(call['accountId'], 'acc-2');
      expect(call['description'], 'gaji lembur');
      expect(call['date'], '2026-10-16');
      await cubit.close();
    });

    test('submit failure surfaces server error', () async {
      final repo = _FakeActivityRepository()..failSubmit = true;
      final cubit = _cubit(repo);
      await cubit.load();
      final ok = await cubit.submit(
        amountText: '25000',
        categoryId: 2,
        accountId: 'acc-1',
        description: null,
        date: '2026-10-16',
      );
      expect(ok, isFalse);
      expect(cubit.state.status, AddTransactionStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);
      await cubit.close();
    });
  });
}
