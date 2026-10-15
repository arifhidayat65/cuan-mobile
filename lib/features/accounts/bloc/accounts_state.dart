import 'package:equatable/equatable.dart';

enum AccountsStatus { initial, loading, loaded, error }

/// Accounts screen state.
final class AccountsState extends Equatable {
  const AccountsState({
    this.status = AccountsStatus.initial,
    this.accounts = const [],
  });

  final AccountsStatus status;
  final List<Map<String, dynamic>> accounts;

  double get total => accounts.fold(
      0.0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0));

  AccountsState copyWith({
    AccountsStatus? status,
    List<Map<String, dynamic>>? accounts,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
    );
  }

  @override
  List<Object?> get props => [status, accounts];
}
