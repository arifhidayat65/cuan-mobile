import 'package:equatable/equatable.dart';

enum SavingsStatus { initial, loading, loaded, error }

final class SavingsState extends Equatable {
  const SavingsState({
    this.status = SavingsStatus.initial,
    this.items = const [],
    this.error = '',
    this.errorMessage = '',
    this.sessionExpired = false,
  });

  final SavingsStatus status;
  final List<Map<String, dynamic>> items;
  final String error;

  /// Set when [status] is error: user-facing message + whether the session died.
  final String errorMessage;
  final bool sessionExpired;

  SavingsState copyWith({
    SavingsStatus? status,
    List<Map<String, dynamic>>? items,
    String? error,
    String? errorMessage,
    bool? sessionExpired,
  }) {
    return SavingsState(
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
