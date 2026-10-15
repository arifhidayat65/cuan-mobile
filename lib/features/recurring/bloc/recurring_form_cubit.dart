import 'package:flutter_bloc/flutter_bloc.dart';

/// Ephemeral form state for the recurring create sheet.
/// Replaces StatefulWidget setState — BLoC only.
class RecurringFormState {
  const RecurringFormState({this.type = 'expense', this.frequency = 'monthly'});

  final String type;
  final String frequency;

  RecurringFormState copyWith({String? type, String? frequency}) {
    return RecurringFormState(
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
    );
  }
}

class RecurringFormCubit extends Cubit<RecurringFormState> {
  RecurringFormCubit() : super(const RecurringFormState());

  void setType(String type) => emit(state.copyWith(type: type));
  void setFrequency(String frequency) =>
      emit(state.copyWith(frequency: frequency));
}
