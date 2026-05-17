import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';

class SideNavBar extends StatelessWidget {
  final MainLayoutCubit cubit;

  const SideNavBar({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 500),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: BorderDirectional(
          end: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      Assets.imagesAppLogo,
                      width: 40.w,
                      height: 40.w,
                    ),
                  ),
                ),

                // const SizedBox(width: 16),
                // Expanded(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         AppStrings.appName.tr(),
                //         style: TextStyles.customStyle(
                //           fontSize: 24,
                //           fontWeight: FontWeight.bold,
                //           color: AppColors.primaryColor,
                //         ),
                //       ),
                //       Text(
                //         "TAHSEL",
                //         style: TextStyles.customStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.w500,
                //           color: AppColors.subTitleColor,
                //           letterSpacing: 2.0,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(thickness: 1),
          ),
          const SizedBox(height: 24),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader(context, AppStrings.mainMenu.tr()),
                _NavTile(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: AppStrings.home.tr(),
                  isSelected: cubit.currentIndex == 0,
                  onTap: () => cubit.changeBottomNav(0),
                ),
                _NavTile(
                  index: 1,
                  icon: Icons.account_balance_wallet_rounded,
                  label: AppStrings.allExpenses.tr(),
                  isSelected: cubit.currentIndex == 1,
                  onTap: () => cubit.changeBottomNav(1),
                ),
                _NavTile(
                  index: 2,
                  icon: Icons.people_alt_rounded,
                  label: AppStrings.totalDebts.tr(),
                  isSelected: cubit.currentIndex == 2,
                  onTap: () => cubit.changeBottomNav(2),
                ),
                _NavTile(
                  index: 3,
                  icon: Icons.bar_chart_rounded,
                  label: AppStrings.reports.tr(),
                  isSelected: cubit.currentIndex == 3,
                  onTap: () => cubit.changeBottomNav(3),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, AppStrings.other.tr()),
                _NavTile(
                  index: 4,
                  icon: Icons.settings_rounded,
                  label: AppStrings.settings.tr(),
                  isSelected: cubit.currentIndex == 4,
                  onTap: () => cubit.changeBottomNav(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        bottom: 8,
        top: 12,
      ),
      child: Text(
        title,
        style: TextStyles.customStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.disabledColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: 0.1)
                  : (_isHovered
                        ? activeColor.withValues(alpha: 0.05)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSelected ? activeColor : AppColors.blackLight,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? activeColor
                          : AppColors.blackLight,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
