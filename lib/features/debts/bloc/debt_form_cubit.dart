import 'package:flutter_bloc/flutter_bloc.dart';

/// Ephemeral form state for the debt create sheet (type selection).
/// Replaces StatefulBuilder setState — BLoC only.
class DebtFormCubit extends Cubit<String> {
  DebtFormCubit(String initial) : super(initial);

  void setType(String type) => emit(type);
}
