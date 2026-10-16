import 'package:equatable/equatable.dart';

enum AccountsStatus { initial, loading, loaded, error }

/// Accounts screen state.
final class AccountsState extends Equatable {
  const AccountsState({
    this.status = AccountsStatus.initial,
    this.accounts = const [],
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final AccountsStatus status;
  final List<Map<String, dynamic>> accounts;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  double get total => accounts.fold(
      0.0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0));

  AccountsState copyWith({
    AccountsStatus? status,
    List<Map<String, dynamic>>? accounts,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [status, accounts, errorMessage, sessionExpired];
}
