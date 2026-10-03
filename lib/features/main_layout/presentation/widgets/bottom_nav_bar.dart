import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

/// Screen index mapping (matches MainLayoutCubit.screens):
///   0  → Home
///   1  → Expenses
///   2  → Debts
///   3  → Invoices  (shop only)
///   4  → Reports
///   5  → More (Business Tools & App Settings)
///   6  → Customers
///   7  → Vault (shop only)
///   8  → Inventory (shop only)
///   9  → Employees
///   10 → Shipping Reconciliation (shop only)
///   11 → Team Management (owner only)
///   12 → Custody Management (owner only)
class BottomNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;
  final bool isShop;

  const BottomNavBar({super.key, required this.cubit, this.isShop = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PermissionService.instance.changeNotifier,
      builder: (context, _, __) {
        // 1. Primary core navigation items
        final primaryItems = <_BottomNavItemData>[
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
        ];

        // 2. Candidate items that can be promoted to fill empty slots
        // when an employee has fewer than 5 items in the bottom navigation bar.
        final secondaryCandidates = <_BottomNavItemData>[
          _BottomNavItemData(
            realIndex: 6,
            icon: Icons.groups_rounded,
            label: AppStrings.customers.tr(),
          ),
          if (isShop)
            _BottomNavItemData(
              realIndex: 8,
              icon: Icons.inventory_2_rounded,
              label: AppStrings.inventory.tr(),
            ),
          if (isShop)
            _BottomNavItemData(
              realIndex: 7,
              icon: Icons.savings_rounded,
              label: AppStrings.vaultTitle.tr(),
            ),
          if (isShop)
            _BottomNavItemData(
              realIndex: 10,
              icon: Icons.local_shipping_rounded,
              label: AppStrings.shippingReconciliation.tr(),
            ),
          _BottomNavItemData(
            realIndex: 9,
            icon: Icons.badge_rounded,
            label: AppStrings.employees.tr(),
          ),
          _BottomNavItemData(
            realIndex: 11,
            icon: Icons.admin_panel_settings_rounded,
            label: AppStrings.teamAndPermissions.tr(),
          ),
          _BottomNavItemData(
            realIndex: 12,
            icon: Icons.account_balance_wallet_outlined,
            label: AppStrings.employeeCustodies.tr(),
          ),
        ];

        final moreItem = _BottomNavItemData(
          realIndex: 5,
          icon: Icons.grid_view_rounded,
          label: AppStrings.more.tr(),
        );

        // Filter primary items allowed for current user
        final allowedPrimary = primaryItems
            .where((item) => cubit.isIndexAllowed(item.realIndex))
            .toList();

        // Standard bottom nav holds up to 5 items comfortably.
        // We reserve 1 slot for "More" (المزيد).
        const int targetCapacity = 5;
        final int availableSlots = (targetCapacity - 1) - allowedPrimary.length;

        final List<_BottomNavItemData> promotedSecondary;
        if (availableSlots > 0) {
          promotedSecondary = secondaryCandidates
              .where((item) => cubit.isIndexAllowed(item.realIndex))
              .take(availableSlots)
              .toList();
        } else {
          promotedSecondary = const [];
        }

        final itemsToShow = [
          ...allowedPrimary,
          ...promotedSecondary,
          moreItem,
        ];

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

        // If current screen index is in the bottom bar, highlight it.
        // Otherwise, highlight "More" (index 5) as the fallback container.
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyles.customStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: itemsToShow.map((item) {
            Widget iconWidget = Icon(item.icon);
            if (item.realIndex == 8 && cubit.lowStockCount > 0) {
              iconWidget = Badge(
                label: Text(
                  cubit.lowStockCount > 99 ? '99+' : '${cubit.lowStockCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppColors.redColor,
                child: iconWidget,
              );
            }
            return BottomNavigationBarItem(
              icon: iconWidget,
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
