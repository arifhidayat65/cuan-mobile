import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/load_error.dart';
import '../../debts/data/debt_repository.dart';

/// Split bill calculator state.
class SplitBillState {
  const SplitBillState({
    this.total = 0,
    this.people = 2,
    this.taxPercent = 0,
    this.tipPercent = 0,
    this.saving = false,
    this.saveError,
  });

  final double total;
  final int people;
  final double taxPercent;
  final double tipPercent;
  final bool saving;
  final String? saveError;

  double get tax => total * taxPercent / 100;
  double get tip => total * tipPercent / 100;
  double get grandTotal => total + tax + tip;
  double get perPerson => people > 0 ? grandTotal / people : 0;

  SplitBillState copyWith({
    double? total,
    int? people,
    double? taxPercent,
    double? tipPercent,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return SplitBillState(
      total: total ?? this.total,
      people: people ?? this.people,
      taxPercent: taxPercent ?? this.taxPercent,
      tipPercent: tipPercent ?? this.tipPercent,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

/// Split bill calculator — replaces StatefulWidget setState. BLoC only.
///
/// Can persist the result as a piutang (receivable) debt via [save],
/// so the split is visible again on the debts page.
class SplitBillCubit extends Cubit<SplitBillState> {
  SplitBillCubit({DebtRepository? debtRepository})
      : _debts = debtRepository ?? DebtRepository(),
        super(const SplitBillState());

  final DebtRepository _debts;

  void setTotal(String text) =>
      emit(state.copyWith(total: double.tryParse(text) ?? 0));

  void setPeople(String text) =>
      emit(state.copyWith(people: int.tryParse(text) ?? 0));

  void setTax(double v) => emit(state.copyWith(taxPercent: v));

  void setTip(double v) => emit(state.copyWith(tipPercent: v));

  /// Amount the others owe me: everyone's share except mine.
  double get receivableAmount =>
      state.people > 1 ? state.perPerson * (state.people - 1) : 0;

  /// Human-readable breakdown stored as the debt description.
  String buildDescription() {
    final parts = <String>['${state.people} orang'];
    if (state.taxPercent > 0) {
      parts.add('Pajak ${state.taxPercent.toStringAsFixed(0)}%');
    }
    if (state.tipPercent > 0) {
      parts.add('Tip ${state.tipPercent.toStringAsFixed(0)}%');
    }
    return 'Split bill (${parts.join(' · ')})';
  }

  /// Save the split as a piutang debt. Returns true on success.
  Future<bool> save({required String label}) async {
    final amount = receivableAmount.round();
    if (amount <= 0) return false;
    final name = label.trim().isEmpty ? 'Patungan' : label.trim();
    emit(state.copyWith(saving: true, clearSaveError: true));
    try {
      await _debts.create(
        type: 'piutang',
        personName: '$name (${state.people} orang)',
        amount: amount.toString(),
        description: buildDescription(),
      );
      emit(state.copyWith(saving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        saveError: classifyLoadError(e).message,
      ));
      return false;
    }
  }
}
