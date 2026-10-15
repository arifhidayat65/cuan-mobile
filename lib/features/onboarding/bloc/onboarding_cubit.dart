import 'package:flutter_bloc/flutter_bloc.dart';

/// Onboarding page index — replaces setState. BLoC only.
class OnboardingCubit extends Cubit<int> {
  OnboardingCubit() : super(0);

  void setPage(int page) => emit(page);
}
