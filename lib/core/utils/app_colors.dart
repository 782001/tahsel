import 'package:flutter/material.dart';
import 'package:tahsel/core/services/injection_container.dart';
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
        // Use PlatformDispatcher to get system brightness if context is not ready
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
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

  static Color get subTitleColor => isDark ? Colors.white70 : Colors.black54;

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

  static Color get dividerColor => isDark ? Colors.white10 : Colors.black12;

  // --- Static Constants & Common Colors ---
  static const Color redColor = Color(0xFFF21616);
  static const Color orange100 = Color(0xFFEE9300);
  static const Color blue100 = Color(0xFF1E56A0);

  static Color get whiteColor =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get black =>
      isDark ? const Color(0xFFE1E1E1) : const Color(0xFF212121);
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color grey = Colors.grey;
  static Color get blackLight =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF404968);

  static Color get white => isDark ? const Color(0xFF121212) : Colors.white;
  static Color get blackReal => isDark ? Colors.white : Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color shadowColor = Color(0x0F1A1C1C);
  static const BoxShadow shadow = BoxShadow(
    color: shadowColor,
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  static Color whiteOpacity(double opacity) {
    return Colors.white.withValues(alpha: opacity);
  }

  // --- Inventory Feature Colors ---

  /// Teal used for supplier icons and tiles
  static Color get inventorySupplierTeal =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);

  /// Purple used for purchase icons and tiles
  static Color get inventoryPurchasePurple =>
      isDark ? const Color(0xFFCE93D8) : const Color(0xFF6B11B0);

  /// Category brown/orange (same as stitchOrange)
  static Color get inventoryCategoryBrown =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFF834600);

  /// Gold gradient start for VIP badge
  static const Color vipGoldStart = Color(0xFFFFD700);

  /// Gold gradient end for VIP badge
  static const Color vipGoldEnd = Color(0xFFFFA500);

  // --- Stock Movement Colors ---

  /// Green for purchase movement
  static Color get movementPurchase =>
      isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

  /// Red for invoice sale movement
  static Color get movementInvoiceSale =>
      isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);

  /// Blue for invoice return movement
  static Color get movementInvoiceReturn =>
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);

  /// Orange for manual adjustment movement
  static Color get movementManualAdjustment =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);

  /// Purple for purchase return movement
  static Color get movementPurchaseReturn =>
      isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A);

  /// Delete action red
  static Color get deleteRed => isDark ? const Color(0xFFEF5350) : Colors.red;

  /// Low stock badge orange
  static Color get lowStockOrange =>
      isDark ? const Color(0xFFFFB74D) : Colors.orange;

  /// Low stock text deep orange
  static Color get lowStockDeepOrange =>
      isDark ? const Color(0xFFFF8A65) : Colors.deepOrange;

  /// Stock addition button green
  static Color get stockAdditionGreen =>
      isDark ? const Color(0xFF66BB6A) : Colors.green.shade700;

  /// Stock subtraction button red
  static Color get stockSubtractionRed =>
      isDark ? const Color(0xFFEF5350) : Colors.red.shade700;

  // --- Supplier & Customer Credit Theme Colors ---
  static const Color creditAmberStart = Color(0xFFF59E0B);
  static const Color creditAmberEnd = Color(0xFFB45309);
  static Color get supplierCreditColor =>
      isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
}
