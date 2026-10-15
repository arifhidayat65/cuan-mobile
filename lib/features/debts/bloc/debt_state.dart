import 'package:equatable/equatable.dart';

enum DebtStatus { initial, loading, loaded, error }

final class DebtState extends Equatable {
  const DebtState({
    this.status = DebtStatus.initial,
    this.items = const [],
    this.filter = 'hutang',
  });

  final DebtStatus status;
  final List<Map<String, dynamic>> items;
  final String filter;

  DebtState copyWith({
    DebtStatus? status,
    List<Map<String, dynamic>>? items,
    String? filter,
  }) {
    return DebtState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [status, items, filter];
}
