import 'package:cuan_mobile/features/accounts/bloc/accounts_cubit.dart';
import 'package:cuan_mobile/features/accounts/bloc/accounts_state.dart';
import 'package:cuan_mobile/features/accounts/data/accounts_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory accounts repository for CRUD tests.
class _FakeAccountsRepo extends AccountsRepository {
  _FakeAccountsRepo(this.store);

  final List<Map<String, dynamic>> store;

  @override
  Future<List<Map<String, dynamic>>> accounts() async => List.of(store);

  @override
  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String type,
    double? initialBalance,
  }) async {
    final account = <String, dynamic>{
      'id': 'acc-${store.length}',
      'name': name,
      'type': type,
      'balance': initialBalance ?? 0.0,
      'isDefault': false,
    };
    store.add(account);
    return account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    store.removeWhere((a) => a['id'] == id);
  }
}

/// Repository that always throws — simulates a failed mutation.
class _ThrowingAccountsRepo extends AccountsRepository {
  @override
  Future<List<Map<String, dynamic>>> accounts() async => [];

  @override
  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String type,
    double? initialBalance,
  }) =>
      throw DioException(
        requestOptions: RequestOptions(path: '/api/financial-accounts'),
      );

  @override
  Future<void> deleteAccount(String id) => throw DioException(
        requestOptions: RequestOptions(path: '/api/financial-accounts/$id'),
      );
}

/// Repository that fails deletes with the backend's "has transactions" error.
class _ProtectedAccountsRepo extends AccountsRepository {
  @override
  Future<List<Map<String, dynamic>>> accounts() async => [];

  @override
  Future<Map<String, dynamic>> createAccount({
    required String name,
    required String type,
    double? initialBalance,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount(String id) => throw DioException(
        requestOptions: RequestOptions(path: '/api/financial-accounts/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/financial-accounts/$id'),
          statusCode: 400,
          data: {
            'error':
                'Cannot delete an account with transactions. Reassign them first.'
          },
        ),
      );
}

void main() {
  Map<String, dynamic> acc(String id, String name) => {
        'id': id,
        'name': name,
        'type': 'e-wallet',
        'balance': 100.0,
        'isDefault': false,
      };

  test('createAccount adds to the list and reloads', () async {
    final cubit = AccountsCubit(_FakeAccountsRepo([acc('a1', 'DANA')]));
    await cubit.load();
    expect(cubit.state.accounts, hasLength(1));

    final ok = await cubit.createAccount(
      name: 'OVO',
      type: 'e-wallet',
      initialBalance: 50000,
    );
    expect(ok, isTrue);
    expect(cubit.state.status, AccountsStatus.loaded);
    expect(cubit.state.accounts, hasLength(2));
    expect(cubit.state.accounts.last['name'], 'OVO');
    expect(cubit.state.accounts.last['balance'], 50000);
    await cubit.close();
  });

  test('createAccount surfaces error on failure', () async {
    final cubit = AccountsCubit(_ThrowingAccountsRepo());
    final ok = await cubit.createAccount(name: 'X', type: 'cash');
    expect(ok, isFalse);
    expect(cubit.state.status, AccountsStatus.error);
    expect(cubit.state.errorMessage, isNotEmpty);
    await cubit.close();
  });

  test('deleteAccount removes from the list and reloads', () async {
    final cubit =
        AccountsCubit(_FakeAccountsRepo([acc('a1', 'DANA'), acc('a2', 'OVO')]));
    await cubit.load();
    expect(cubit.state.accounts, hasLength(2));

    final ok = await cubit.deleteAccount('a1');
    expect(ok, isTrue);
    expect(cubit.state.status, AccountsStatus.loaded);
    expect(cubit.state.accounts, hasLength(1));
    expect(cubit.state.accounts.single['id'], 'a2');
    await cubit.close();
  });

  test('deleteAccount surfaces error on failure', () async {
    final cubit = AccountsCubit(_ThrowingAccountsRepo());
    final ok = await cubit.deleteAccount('a1');
    expect(ok, isFalse);
    expect(cubit.state.status, AccountsStatus.error);
    await cubit.close();
  });

  test('deleteAccount translates backend "has transactions" error', () async {
    final cubit = AccountsCubit(_ProtectedAccountsRepo());
    final ok = await cubit.deleteAccount('a1');
    expect(ok, isFalse);
    expect(cubit.state.status, AccountsStatus.error);
    expect(
      cubit.state.errorMessage,
      'Akun tidak bisa dihapus karena masih ada transaksi.',
    );
    await cubit.close();
  });
}
