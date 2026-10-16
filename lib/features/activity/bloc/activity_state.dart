import 'package:equatable/equatable.dart';

enum ActivityStatus { initial, loading, loaded, error }

/// Activity screen state — ledger + filter + search query.
final class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.initial,
    this.transactions = const [],
    this.filter = 'all',
    this.query = '',
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final ActivityStatus status;
  final List<Map<String, dynamic>> transactions;
  final String filter; // all | income | expense
  final String query;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  List<Map<String, dynamic>> get visible {
    return transactions.where((t) {
      if (filter != 'all' && t['type'] != filter) return false;
      if (query.isNotEmpty) {
        final hay =
            '${t['description'] ?? ''} ${t['category'] ?? ''}'.toLowerCase();
        if (!hay.contains(query.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  ActivityState copyWith({
    ActivityStatus? status,
    List<Map<String, dynamic>>? transactions,
    String? filter,
    String? query,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return ActivityState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props =>
      [status, transactions, filter, query, errorMessage, sessionExpired];
}
