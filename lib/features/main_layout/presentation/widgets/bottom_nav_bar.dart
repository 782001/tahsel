import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/main_layout/presentation/widgets/nav_icon.dart';

class BottomNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;

  const BottomNavBar({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            color: AppColors.scafoldBackGround.withOpacity(0.8),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NavIcon(
                      icon: Icons.home_rounded,
                      label: AppStrings.home.tr(),
                      index: 0,
                      cubit: cubit,
                    ),
                    NavIcon(
                      icon: Icons.account_balance_wallet_rounded,
                      label: AppStrings.allExpenses.tr(),
                      index: 1,
                      cubit: cubit,
                    ),
                    NavIcon(
                      icon: Icons.people_alt_rounded,
                      label: AppStrings.customerDebts.tr(),
                      index: 2,
                      cubit: cubit,
                    ),
                    NavIcon(
                      icon: Icons.bar_chart_rounded,
                      label: AppStrings.reports.tr(),
                      index: 3,
                      cubit: cubit,
                    ),
                    NavIcon(
                      icon: Icons.settings_rounded,
                      label: AppStrings.settings.tr(),
                      index: 4,
                      cubit: cubit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
