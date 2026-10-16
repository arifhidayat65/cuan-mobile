import 'package:equatable/equatable.dart';

enum AddTransactionStatus { initial, loading, ready, saving, success, failure }

/// State for the manual add-transaction sheet.
final class AddTransactionState extends Equatable {
  const AddTransactionState({
    this.status = AddTransactionStatus.initial,
    this.type = 'expense',
    this.categories = const [],
    this.accounts = const [],
    this.errorMessage,
  });

  final AddTransactionStatus status;
  final String type; // expense | income
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> accounts;
  final String? errorMessage;

  AddTransactionState copyWith({
    AddTransactionStatus? status,
    String? type,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? accounts,
    String? errorMessage,
  }) {
    return AddTransactionState(
      status: status ?? this.status,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      accounts: accounts ?? this.accounts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, type, categories, accounts, errorMessage];
}
