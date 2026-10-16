import 'package:equatable/equatable.dart';

enum DebtStatus { initial, loading, loaded, error }

final class DebtState extends Equatable {
  const DebtState({
    this.status = DebtStatus.initial,
    this.items = const [],
    this.filter = 'hutang',
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final DebtStatus status;
  final List<Map<String, dynamic>> items;
  final String filter;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  DebtState copyWith({
    DebtStatus? status,
    List<Map<String, dynamic>>? items,
    String? filter,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return DebtState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, filter, errorMessage, sessionExpired];
}
