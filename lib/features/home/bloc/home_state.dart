import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, loaded, error }

/// Home screen state — accounts + recent transactions for the hero.
final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.accounts = const [],
    this.transactions = const [],
    this.monthlyStats = const {},
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final HomeStatus status;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> transactions;

  /// Real monthly stats: {income, expense, net} — empty if unavailable.
  final Map<String, double> monthlyStats;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  double get total => accounts.fold(
      0.0, (s, a) => s + ((a['balance'] as num?)?.toDouble() ?? 0));

  HomeState copyWith({
    HomeStatus? status,
    List<Map<String, dynamic>>? accounts,
    List<Map<String, dynamic>>? transactions,
    Map<String, double>? monthlyStats,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return HomeState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [
        status,
        accounts,
        transactions,
        monthlyStats,
        errorMessage,
        sessionExpired,
      ];
}
