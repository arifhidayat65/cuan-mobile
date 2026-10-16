import 'package:equatable/equatable.dart';

enum RecurringStatus { initial, loading, loaded, error }

/// Recurring transactions state.
final class RecurringState extends Equatable {
  const RecurringState({
    this.status = RecurringStatus.initial,
    this.items = const [],
    this.error = '',
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final RecurringStatus status;
  final List<Map<String, dynamic>> items;
  final String error;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  RecurringState copyWith({
    RecurringStatus? status,
    List<Map<String, dynamic>>? items,
    String? error,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return RecurringState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, error, errorMessage, sessionExpired];
}
