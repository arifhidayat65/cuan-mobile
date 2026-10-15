import 'package:flutter_bloc/flutter_bloc.dart';

/// Split bill calculator state.
class SplitBillState {
  const SplitBillState({
    this.total = 0,
    this.people = 2,
    this.taxPercent = 0,
    this.tipPercent = 0,
  });

  final double total;
  final int people;
  final double taxPercent;
  final double tipPercent;

  double get tax => total * taxPercent / 100;
  double get tip => total * tipPercent / 100;
  double get grandTotal => total + tax + tip;
  double get perPerson => people > 0 ? grandTotal / people : 0;

  SplitBillState copyWith({
    double? total,
    int? people,
    double? taxPercent,
    double? tipPercent,
  }) {
    return SplitBillState(
      total: total ?? this.total,
      people: people ?? this.people,
      taxPercent: taxPercent ?? this.taxPercent,
      tipPercent: tipPercent ?? this.tipPercent,
    );
  }
}

/// Split bill calculator — replaces StatefulWidget setState. BLoC only.
class SplitBillCubit extends Cubit<SplitBillState> {
  SplitBillCubit() : super(const SplitBillState());

  void setTotal(String text) =>
      emit(state.copyWith(total: double.tryParse(text) ?? 0));

  void setPeople(String text) =>
      emit(state.copyWith(people: int.tryParse(text) ?? 0));

  void setTax(double v) => emit(state.copyWith(taxPercent: v));

  void setTip(double v) => emit(state.copyWith(tipPercent: v));
}
