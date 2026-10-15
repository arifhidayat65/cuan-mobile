import 'package:equatable/equatable.dart';

enum SavingsStatus { initial, loading, loaded, error }

final class SavingsState extends Equatable {
  const SavingsState({
    this.status = SavingsStatus.initial,
    this.items = const [],
    this.error = '',
  });

  final SavingsStatus status;
  final List<Map<String, dynamic>> items;
  final String error;

  SavingsState copyWith({
    SavingsStatus? status,
    List<Map<String, dynamic>>? items,
    String? error,
  }) {
    return SavingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
