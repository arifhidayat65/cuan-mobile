import 'package:cuan_mobile/features/accounts/bloc/accounts_cubit.dart';
import 'package:cuan_mobile/features/accounts/bloc/accounts_state.dart';
import 'package:cuan_mobile/features/accounts/data/accounts_repository.dart';
import 'package:cuan_mobile/features/activity/bloc/activity_cubit.dart';
import 'package:cuan_mobile/features/activity/bloc/activity_state.dart';
import 'package:cuan_mobile/features/activity/data/activity_repository.dart';
import 'package:cuan_mobile/features/budgets/bloc/budgets_cubit.dart';
import 'package:cuan_mobile/features/budgets/bloc/budgets_state.dart';
import 'package:cuan_mobile/features/budgets/data/budgets_repository.dart';
import 'package:cuan_mobile/features/debts/bloc/debt_cubit.dart';
import 'package:cuan_mobile/features/debts/bloc/debt_state.dart';
import 'package:cuan_mobile/features/debts/data/debt_repository.dart';
import 'package:cuan_mobile/features/home/bloc/home_cubit.dart';
import 'package:cuan_mobile/features/home/bloc/home_state.dart';
import 'package:cuan_mobile/features/home/data/home_repository.dart';
import 'package:cuan_mobile/features/recurring/bloc/recurring_cubit.dart';
import 'package:cuan_mobile/features/recurring/bloc/recurring_state.dart';
import 'package:cuan_mobile/features/recurring/data/recurring_repository.dart';
import 'package:cuan_mobile/features/savings/bloc/savings_cubit.dart';
import 'package:cuan_mobile/features/savings/bloc/savings_state.dart';
import 'package:cuan_mobile/features/savings/data/savings_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositories that always throw — simulating a failed load.
DioException _dio401() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 401,
      ),
    );

class _ThrowingHomeRepo extends HomeRepository {
  _ThrowingHomeRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> accounts() => throw error;
  @override
  Future<List<Map<String, dynamic>>> recentTransactions({int limit = 8}) =>
      throw error;
  @override
  Future<Map<String, double>> monthlyStats() => throw error;
}

class _ThrowingActivityRepo extends ActivityRepository {
  _ThrowingActivityRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> transactions({int limit = 100}) =>
      throw error;
}

class _ThrowingBudgetsRepo extends BudgetsRepository {
  _ThrowingBudgetsRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> budgets(String month) => throw error;
}

class _ThrowingAccountsRepo extends AccountsRepository {
  _ThrowingAccountsRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> accounts() => throw error;
}

class _ThrowingRecurringRepo extends RecurringRepository {
  _ThrowingRecurringRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> list() => throw error;
}

class _ThrowingSavingsRepo extends SavingsGoalRepository {
  _ThrowingSavingsRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> list() => throw error;
}

class _ThrowingDebtRepo extends DebtRepository {
  _ThrowingDebtRepo(this.error);
  final Object error;
  @override
  Future<List<Map<String, dynamic>>> list({String? type}) => throw error;
}

void main() {
  group('cubit load() failure → error status + message', () {
    test('HomeCubit', () async {
      final cubit = HomeCubit(_ThrowingHomeRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('ActivityCubit', () async {
      final cubit = ActivityCubit(_ThrowingActivityRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, ActivityStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('BudgetsCubit', () async {
      final cubit = BudgetsCubit(_ThrowingBudgetsRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, BudgetsStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('AccountsCubit', () async {
      final cubit = AccountsCubit(_ThrowingAccountsRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, AccountsStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('RecurringCubit', () async {
      final cubit = RecurringCubit(_ThrowingRecurringRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, RecurringStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('SavingsCubit', () async {
      final cubit = SavingsCubit(_ThrowingSavingsRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, SavingsStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });

    test('DebtCubit', () async {
      final cubit = DebtCubit(_ThrowingDebtRepo(Exception('boom')));
      await cubit.load();
      expect(cubit.state.status, DebtStatus.error);
      expect(cubit.state.errorMessage, isNotEmpty);
      expect(cubit.state.sessionExpired, isFalse);
      await cubit.close();
    });
  });

  group('401 → sessionExpired flag', () {
    test('HomeCubit menandai sesi kedaluwarsa', () async {
      final cubit = HomeCubit(_ThrowingHomeRepo(_dio401()));
      await cubit.load();
      expect(cubit.state.status, HomeStatus.error);
      expect(cubit.state.sessionExpired, isTrue);
      expect(cubit.state.errorMessage, contains('Sesi'));
      await cubit.close();
    });

    test('ActivityCubit menandai sesi kedaluwarsa', () async {
      final cubit = ActivityCubit(_ThrowingActivityRepo(_dio401()));
      await cubit.load();
      expect(cubit.state.sessionExpired, isTrue);
      await cubit.close();
    });
  });
}
