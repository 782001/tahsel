import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

/// Screen index mapping (matches MainLayoutCubit.screens):
///   0 → Home
///   1 → Expenses
///   2 → Debts
///   3 → Invoices  (shop only)
///   4 → Reports
///   5 → Settings
class BottomNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;
  final bool isShop;

  const BottomNavBar({super.key, required this.cubit, this.isShop = false});

  @override
  Widget build(BuildContext context) {
    // Build a map from visible tap index → real screen index,
    // skipping index 3 (Invoices) when the account is not shop.
    final visibleToReal = <int, int>{};
    var visibleIdx = 0;
    for (var realIdx = 0; realIdx < 6; realIdx++) {
      if (realIdx == 3 && !isShop) continue; // skip Invoices for non-shop
      visibleToReal[visibleIdx] = realIdx;
      visibleIdx++;
    }
    final realToVisible = {
      for (final e in visibleToReal.entries) e.value: e.key,
    };
    final currentVisible = realToVisible[cubit.currentIndex] ?? 0;

    return BottomNavigationBar(
      currentIndex: currentVisible,
      onTap: (index) => cubit.changeBottomNav(visibleToReal[index] ?? index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.blackLight,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyles.customStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyles.customStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: AppStrings.home.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: AppStrings.allExpenses.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_alt_rounded),
          label: AppStrings.totalDebts.tr(),
        ),
        if (isShop)
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: AppStrings.invoices.tr(),
          ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_rounded),
          label: AppStrings.reports.tr(),
        ),

        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_rounded),
          label: AppStrings.settings.tr(),
        ),
      ],
    );
  }
}
