import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

class BottomNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;

  const BottomNavBar({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: cubit.currentIndex,
      onTap: (index) => cubit.changeBottomNav(index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.blackLight,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12.sp,
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
          label: AppStrings.customerDebts.tr(),
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
