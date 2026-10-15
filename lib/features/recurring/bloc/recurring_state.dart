import 'package:equatable/equatable.dart';

enum RecurringStatus { initial, loading, loaded, error }

/// Recurring transactions state.
final class RecurringState extends Equatable {
  const RecurringState({
    this.status = RecurringStatus.initial,
    this.items = const [],
    this.error = '',
  });

  final RecurringStatus status;
  final List<Map<String, dynamic>> items;
  final String error;

  RecurringState copyWith({
    RecurringStatus? status,
    List<Map<String, dynamic>>? items,
    String? error,
  }) {
    return RecurringState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
