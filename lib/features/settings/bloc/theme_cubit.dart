import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/ledger_theme.dart';

/// Theme mode cubit — dark/light toggle.
class ThemeCubit extends Cubit<bool> {
  ThemeCubit() : super(true);

  static const _key = 'theme_dark';
  bool _loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true;
    // Don't overwrite if user already toggled before load completed.
    if (!_loaded) {
      _loaded = true;
      LedgerTheme.setDark(isDark);
      emit(isDark);
    }
  }

  Future<void> toggle() async {
    _loaded = true; // Prevent load() from overwriting.
    final next = !state;
    LedgerTheme.setDark(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, next);
    emit(next);
  }
}
