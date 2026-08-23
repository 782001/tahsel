import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/vault_transaction_entity.dart';

class VaultSourceFilterChips extends StatelessWidget {
  final VaultTransactionSource selectedSource;
  final ValueChanged<VaultTransactionSource> onSourceSelected;

  const VaultSourceFilterChips({
    super.key,
    required this.selectedSource,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final filters = [
      (source: VaultTransactionSource.all, label: AppStrings.filterAll.tr()),
      (
        source: VaultTransactionSource.customerDebt,
        label: AppStrings.cashboxSourceCustomerDebt.tr(),
      ),
      (
        source: VaultTransactionSource.myDebt,
        label: AppStrings.cashboxSourceSupplierDebt.tr(),
      ),
      (
        source: VaultTransactionSource.inventory,
        label: AppStrings.cashboxSourceInventoryPurchase.tr(),
      ),
      (
        source: VaultTransactionSource.employee,
        label: AppStrings.cashboxSourceEmployee.tr(),
      ),
      (
        source: VaultTransactionSource.expense,
        label: AppStrings.cashboxSourceExpense.tr(),
      ),
      (
        source: VaultTransactionSource.manualDeposit,
        label: AppStrings.cashboxSourceManualAdd.tr(),
      ),
      (
        source: VaultTransactionSource.manualWithdrawal,
        label: AppStrings.cashboxSourceManualWithdraw.tr(),
      ),
    ];

    return SizedBox(
      height: isDesktop ? 44 : 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: isDesktop ? 8 : 8.w),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = selectedSource == item.source;

          return ChoiceChip(
            showCheckmark: false,
            label: Text(
              item.label,
              style: TextStyles.customStyle(
                color: isSelected ? Colors.white : AppColors.textColor,
                fontSize: isDesktop ? 13 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primaryColor,
            backgroundColor: AppColors.surfaceContainerHigh,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            onSelected: (_) => onSourceSelected(item.source),
          );
        },
      ),
    );
  }
}
