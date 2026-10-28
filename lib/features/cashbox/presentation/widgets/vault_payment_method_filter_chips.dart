import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class VaultPaymentMethodFilterChips extends StatelessWidget {
  final String selectedMethod; // 'all', 'cash', 'card'
  final ValueChanged<String> onMethodSelected;

  const VaultPaymentMethodFilterChips({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final items = [
      (
        id: 'all',
        label: AppStrings.vaultFilterAll.tr(),
        icon: Icons.tune_rounded,
        activeColor: AppColors.primaryColor,
      ),
      (
        id: 'cash',
        label: AppStrings.vaultFilterCash.tr(),
        icon: Icons.payments_outlined,
        activeColor: const Color(0xFF10B981), // Emerald Green
      ),
      (
        id: 'card',
        label: AppStrings.vaultFilterCard.tr(),
        icon: Icons.credit_card_rounded,
        activeColor: const Color(0xFF6366F1), // Indigo / Modern Card Color
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isDesktop ? 4 : 3.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = selectedMethod.toLowerCase() == item.id.toLowerCase();
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onMethodSelected(item.id),
                borderRadius: BorderRadius.circular(10.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 10 : 8.h,
                    horizontal: isDesktop ? 8 : 4.w,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? item.activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item.activeColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: isDesktop ? 18 : 16.sp,
                        color: isSelected
                            ? Colors.white
                            : AppColors.subTitleColor,
                      ),
                      SizedBox(width: isDesktop ? 6 : 5.w),
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textColor,
                            fontSize: isDesktop ? 13 : 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

