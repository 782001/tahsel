import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';

ThemeCubit theme() => sl<ThemeCubit>();

extension ThemeContext on BuildContext {
  ThemeCubit get theme => read<ThemeCubit>();
}

class ThemeCubit extends Cubit<ThemeState> {
  final CashHelper cashHelper;
  static const String _themeKey = 'isDarkMode';

  ThemeCubit({required this.cashHelper})
    : super(const ThemeInitial(ThemeMode.light)) {
    getSavedTheme();
  }

  void getSavedTheme() {
    final isDarkMode = cashHelper.getBoolData(key: _themeKey) ?? false;
    emit(ThemeInitial(isDarkMode ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> toggleTheme() async {
    final isDarkMode = state.themeMode == ThemeMode.dark;
    final newThemeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;

    await cashHelper.saveData(key: _themeKey, value: !isDarkMode);
    emit(ThemeChanged(newThemeMode));
  }

  void toDarkMode() async {
    await cashHelper.saveData(key: _themeKey, value: true);
    emit(const ThemeChanged(ThemeMode.dark));
  }

  void toLightMode() async {
    await cashHelper.saveData(key: _themeKey, value: false);
    emit(const ThemeChanged(ThemeMode.light));
  }
}
