import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/load_error.dart';
import '../data/accounts_repository.dart';
import 'accounts_state.dart';

/// Financial accounts list.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repo) : super(const AccountsState());

  final AccountsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: AccountsStatus.loading));
    try {
      final accounts = await _repo.accounts();
      emit(state.copyWith(status: AccountsStatus.loaded, accounts: accounts));
    } catch (e) {
      emit(_asError(e));
    }
  }

  /// Create an account, then reload. Returns true on success.
  Future<bool> createAccount({
    required String name,
    required String type,
    double? initialBalance,
  }) async {
    try {
      await _repo.createAccount(
        name: name,
        type: type,
        initialBalance: initialBalance,
      );
      await load();
      return true;
    } catch (e) {
      emit(_asMutationError(e));
      return false;
    }
  }

  /// Delete an account, then reload. Returns true on success.
  Future<bool> deleteAccount(String id) async {
    try {
      await _repo.deleteAccount(id);
      await load();
      return true;
    } catch (e) {
      emit(_asMutationError(e));
      return false;
    }
  }

  AccountsState _asError(Object e) {
    final err = classifyLoadError(e);
    return state.copyWith(
      status: AccountsStatus.error,
      errorMessage: err.message,
      sessionExpired: err.sessionExpired,
    );
  }

  /// Mutation errors keep the classified session handling but prefer the
  /// backend's own message (e.g. "cannot delete an account with
  /// transactions") over the generic "server bermasalah (kode 400)".
  AccountsState _asMutationError(Object e) {
    final err = classifyLoadError(e);
    return state.copyWith(
      status: AccountsStatus.error,
      errorMessage: _serverMessage(e) ?? err.message,
      sessionExpired: err.sessionExpired,
    );
  }

  /// Extract a user-facing message from a backend error response, if any.
  static String? _serverMessage(Object e) {
    if (e is! DioException) return null;
    final data = e.response?.data;
    String? raw;
    if (data is Map) {
      final m = data['message'];
      if (m is String) raw = m;
      final err = data['error'];
      if (raw == null && err is String) raw = err;
      if (raw == null && err is Map && err['message'] is String) {
        raw = err['message'] as String;
      }
    }
    if (raw == null || raw.isEmpty) return null;
    return _translateAccountError(raw);
  }

  /// Backend speaks English; map the known account-mutation errors to
  /// Indonesian. Unknown messages pass through untouched.
  static String _translateAccountError(String msg) => switch (msg) {
        'Cannot delete an account with transactions. Reassign them first.' =>
          'Akun tidak bisa dihapus karena masih ada transaksi.',
        'Cannot delete the default account. Set another account as default first.' =>
          'Akun utama tidak bisa dihapus. Jadikan akun lain sebagai utama dulu.',
        _ => msg,
      };
}
