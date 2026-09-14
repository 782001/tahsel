import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
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
///   5 → More (Business Tools & App Settings)
class BottomNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;
  final bool isShop;

  const BottomNavBar({super.key, required this.cubit, this.isShop = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PermissionService.instance.changeNotifier,
      builder: (context, _, __) {
        final allItems = <_BottomNavItemData>[
          _BottomNavItemData(
            realIndex: 0,
            icon: Icons.home_rounded,
            label: AppStrings.home.tr(),
          ),
          _BottomNavItemData(
            realIndex: 1,
            icon: Icons.account_balance_wallet_rounded,
            label: AppStrings.allExpenses.tr(),
          ),
          _BottomNavItemData(
            realIndex: 2,
            icon: Icons.people_alt_rounded,
            label: AppStrings.totalDebts.tr(),
          ),
          if (isShop)
            _BottomNavItemData(
              realIndex: 3,
              icon: Icons.receipt_long_rounded,
              label: AppStrings.invoices.tr(),
            ),
          _BottomNavItemData(
            realIndex: 4,
            icon: Icons.bar_chart_rounded,
            label: AppStrings.reports.tr(),
          ),
          _BottomNavItemData(
            realIndex: 5,
            icon: Icons.grid_view_rounded,
            label: AppStrings.more.tr(),
          ),
        ];

        // Filter items based on RBAC permissions
        final allowedItems = allItems
            .where((item) => cubit.isIndexAllowed(item.realIndex))
            .toList();

        final itemsToShow = allowedItems;

        // BottomNavigationBar requires at least 2 items. If fewer, hide it.
        if (itemsToShow.length < 2) {
          return const SizedBox.shrink();
        }

        // Map visible index in bottom nav bar to real screen index
        final visibleToReal = <int, int>{};
        for (var i = 0; i < itemsToShow.length; i++) {
          visibleToReal[i] = itemsToShow[i].realIndex;
        }
        final realToVisible = {
          for (final e in visibleToReal.entries) e.value: e.key,
        };

        // If current screen index is not in the bottom bar (e.g. Reports index 4,
        // or a sub-tool opened from More), keep "More" (index 5) highlighted if available.
        final currentVisible =
            realToVisible[cubit.currentIndex] ?? realToVisible[5] ?? 0;

        return BottomNavigationBar(
          currentIndex: currentVisible,
          onTap: (index) {
            final targetRealIndex = visibleToReal[index];
            if (targetRealIndex != null) {
              cubit.changeBottomNav(targetRealIndex);
            }
          },
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
          items: itemsToShow.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        );
      },
    );
  }
}

class _BottomNavItemData {
  final int realIndex;
  final IconData icon;
  final String label;

  const _BottomNavItemData({
    required this.realIndex,
    required this.icon,
    required this.label,
  });
}
