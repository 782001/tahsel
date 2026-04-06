import 'package:flutter/material.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';

class AppColors {
  static Color get stitchBlue =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF005DB7);
  static Color get stitchOrange =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFF834600);
  static Color get stitchSurfaceLow =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
  static Color get stitchSurfaceHigh =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

  /// Helper to detect if the current theme is dark
  static bool get isDark {
    try {
      final themeMode = sl<ThemeCubit>().state.themeMode;
      if (themeMode == ThemeMode.system) {
        final context = sl<NavigatorService>().context;
        if (context == null) return false;
        return Theme.of(context).brightness == Brightness.dark;
      }
      return themeMode == ThemeMode.dark;
    } catch (_) {
      return false;
    }
  }

  // --- Dynamic Theme-Aware Colors ---

  static Color get primaryColor =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF1E56A0);

  static Color get actionButton =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E56A0);

  static Color get scafoldBackGround =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);

  static Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  static Color get surfaceContainerHigh =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);

  static Color get textColor =>
      isDark ? const Color(0xFFE1E1E1) : const Color(0xFF1E56A0);

  static Color get textColor2 =>
      isDark ? const Color(0xFFBBDEFB) : const Color(0xFF1E56A0);

  static Color get iconeye =>
      isDark ? const Color(0xFF424242) : const Color(0xFFF6F6F6);

  static Color get cardgoods =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFF1E56A0);

  static Color get cardgoods2 =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1E56A0);

  static Color get cardgoods3 =>
      isDark ? const Color(0xFF383838) : const Color(0xFFD6E4F0);

  static Color get cardCustomer =>
      isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F6F6);

  static Color get veryLightGrey =>
      isDark ? const Color(0xFF303030) : const Color(0xFFF6F6F6);

  static Color get sandText =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF1E56A0);

  static Color get sandText2 =>
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF1E56A0);

  static Color get disabledColor => isDark ? Colors.white38 : Colors.black38;

  // --- Status Colors ---
  static Color get success =>
      isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

  static Color get warning =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);

  static Color get error =>
      isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);

  static Color get info =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);

  // --- Customer Debt Card Colors ---
  /// Surface color for the debt card (white in light, dark grey in dark)
  static Color get debtCardSurface =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  /// Background for the slidable 'Partial Payment' action (amber)
  static Color get slidablePartialPayment =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFF59E0B);

  /// Background for the slidable 'Paid in Full' action (primary blue, no green)
  static Color get slidableFullPayment =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1E56A0);

  static Color get errorContainer =>
      isDark ? const Color(0xFF442726) : const Color(0xFFFFEBEE);

  static Color get errorText =>
      isDark ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C);

  // --- Static Constants & Common Colors ---
  static const Color redColor = Color(0xFFF21616);
  static const Color orange100 = Color(0xFFEE9300);
  static const Color blue100 = Color(0xFF1E56A0);

  static Color get whiteColor =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get black =>
      isDark ? const Color(0xFFE1E1E1) : const Color(0xFF212121);
  static const Color green = Colors.green;
  static Color get blackLight =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF404968);

  static Color get white => isDark ? const Color(0xFF121212) : Colors.white;
  static Color get blackReal => isDark ? Colors.white : Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color shadowColor = Color(0x0F1A1C1C);
}
