import 'package:flutter/material.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';

class AppColors {
  /// Helper to detect if the current theme is dark
  static bool get isDark {
    try {
      final context = sl<NavigatorService>().context;
      if (context == null) return false;
      return Theme.of(context).brightness == Brightness.dark;
    } catch (_) {
      return false;
    }
  }

  // --- Dynamic Theme-Aware Colors ---

  static Color get primaryColor =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF163172);

  static Color get actionButton =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E56A0);

  static Color get scafoldBackGround =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);

  static Color get textColor =>
      isDark ? const Color(0xFFE1E1E1) : const Color(0xFF163172);

  static Color get textColor2 =>
      isDark ? const Color(0xFFBBDEFB) : const Color(0xFF1E56A0);

  static Color get iconeye =>
      isDark ? const Color(0xFF424242) : const Color(0xFFF6F6F6);

  static Color get cardgoods =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF163172);

  static Color get cardgoods2 =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E56A0);

  static Color get cardgoods3 =>
      isDark ? const Color(0xFF383838) : const Color(0xFFD6E4F0);

  static Color get cardCustomer =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6);

  static Color get veryLightGrey =>
      isDark ? const Color(0xFF303030) : const Color(0xFFF6F6F6);

  static Color get sandText =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF163172);

  static Color get sandText2 =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF1E56A0);

  static Color get disabledColor => isDark ? Colors.white38 : Colors.black38;

  // --- Static Constants ---

  static const Color redColor = Color(0xFFF21616);
  static const Color orange100 = Color(0xFFEE9300);
  static const Color blue100 = Color(0xFF1E56A0);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF212121);
  static const Color green = Colors.green;
  static const Color blackLight = Color(0xFF404968);
}
