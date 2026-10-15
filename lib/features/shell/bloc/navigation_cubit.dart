import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-navigation tab index. Replaces the old global ValueNotifier.
class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void selectTab(int index) => emit(index);
}
