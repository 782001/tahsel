import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_state.dart';
import 'package:tahsel/routes/app_routes.dart';

/// A card showing a single debt transaction row (one item/day).
class DebtItemCard extends StatelessWidget {
  final DebtItem item;
  final int index;
  final Function(dynamic)? onRefresh;
  final Function(DebtItem) onPayPartial;
  final Function(DebtItem) onPayFull;

  const DebtItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onPayPartial,
    required this.onPayFull,
    this.onRefresh,
  });

  Future<void> _rescheduleDueDate(BuildContext context) async {
    if (item.remainingDebt <= 0) return;
    final uid = AppStrings.userToken;
    if (uid.isEmpty) return;

    final initialDate = item.dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? ColorScheme.dark(primary: AppColors.primaryColor)
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    onPrimary: AppColors.white,
                    onSurface: AppColors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final debtId = item.entity.id;
      if (debtId != null && debtId.isNotEmpty) {
        await context.read<DebtCubit>().updateDebtDueDate(
          uid: uid,
          debtId: debtId,
          dueDate: picked,
        );
        onRefresh?.call(null);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1200),
              content: Text(AppStrings.dueDateUpdatedSuccess.tr()),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCredit =
        item.remainingDebt < 0 || item.amountPaid > item.totalAmount;
    final bool isSettled = item.remainingDebt <= 0;
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    return InkWell(
      key: ValueKey(item.entity.id),
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.debtDetails,
          arguments: item.entity.id,
        );

        if (onRefresh != null) {
          onRefresh!(result);
        }
      },

      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        // margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.debtCardSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: hasCredit
                ? AppColors.creditAmberEnd.withValues(alpha: 0.3)
                : (isSettled
                      ? AppColors.primaryColor.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.15)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Row 1: index badge + item desc + date ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction number badge
                    Container(
                      width: isDesktop ? 28 : 28.h,
                      height: isDesktop ? 28 : 28.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$index',
                        style: TextStyles.customStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: isDesktop ? 11 : 11.r,
                                color: AppColors.disabledColor,
                              ),
                              SizedBox(width: isDesktop ? 8 : 4.w),
                              Text(
                                item.date,
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: isDesktop ? 13 : 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (!isSettled || item.dueDate != null) ...[
                            SizedBox(height: 4.h),
                            InkWell(
                              onTap: isSettled
                                  ? null
                                  : () => _rescheduleDueDate(context),
                              borderRadius: BorderRadius.circular(6.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_available_rounded,
                                      size: isDesktop ? 15 : 15.r,
                                      color: isSettled
                                          ? AppColors.disabledColor
                                          : (item.remainingDebt > 0 &&
                                                  item.dueDate != null &&
                                                  DateTime.now().isAfter(
                                                    DateTime(
                                                      item.dueDate!.year,
                                                      item.dueDate!.month,
                                                      item.dueDate!.day,
                                                      23,
                                                      59,
                                                      59,
                                                    ),
                                                  ))
                                              ? AppColors.error
                                              : (item.dueDate != null
                                                  ? AppColors.primaryColor
                                                  : AppColors.disabledColor),
                                    ),
                                    SizedBox(width: isDesktop ? 6 : 4.w),
                                    Flexible(
                                      child: Text(
                                        item.formattedDueDate != null
                                            ? '${AppStrings.paymentDueDate.tr()}: ${item.formattedDueDate!}'
                                            : AppStrings.setPaymentDueDate.tr(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.customStyle(
                                          color: isSettled
                                              ? AppColors.disabledColor
                                              : (item.remainingDebt > 0 &&
                                                      item.dueDate != null &&
                                                      DateTime.now().isAfter(
                                                        DateTime(
                                                          item.dueDate!.year,
                                                          item.dueDate!.month,
                                                          item.dueDate!.day,
                                                          23,
                                                          59,
                                                          59,
                                                        ),
                                                      ))
                                                  ? AppColors.error
                                                  : (AppColors.primaryColor),
                                          fontSize: isDesktop ? 12 : 11,
                                          fontWeight: item.dueDate != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (!isSettled) ...[
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.edit_calendar_rounded,
                                        size: isDesktop ? 22 : 22.r,
                                        color: AppColors.disabledColor.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Settled / pending / credit pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: hasCredit
                            ? AppColors.creditAmberEnd.withValues(alpha: 0.1)
                            : (isSettled
                                  ? AppColors.primaryColor.withValues(
                                      alpha: 0.1,
                                    )
                                  : AppColors.error.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        hasCredit
                            ? AppStrings.customerCredit.tr()
                            : (isSettled
                                  ? AppStrings.fullPaymentLabel.tr()
                                  : AppStrings.debtStatusOverdue.tr()),
                        style: TextStyles.customStyle(
                          color: hasCredit
                              ? AppColors.creditAmberEnd
                              : (isSettled
                                    ? AppColors.primaryColor
                                    : AppColors.error),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                // --- Row 2: Financials ---
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.stitchSurfaceLow,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      _FinancialCell(
                        label: AppStrings.totalDueLabel.tr(),
                        amount: item.totalAmount,
                        color: AppColors.blackLight,
                      ),
                      _Divider(),
                      _FinancialCell(
                        label: AppStrings.amountPaid.tr(),
                        amount: item.amountPaid,
                        color: AppColors.primaryColor,
                      ),
                      _Divider(),
                      _FinancialCell(
                        label: hasCredit
                            ? AppStrings.customerCredit.tr()
                            : AppStrings.remainingDebt.tr(),
                        amount: hasCredit
                            ? (item.amountPaid > item.totalAmount
                                  ? (item.amountPaid - item.totalAmount)
                                  : item.remainingDebt.abs())
                            : item.remainingDebt,
                        color: hasCredit
                            ? AppColors.creditAmberEnd
                            : (item.remainingDebt > 0
                                  ? AppColors.error
                                  : AppColors.primaryColor),
                      ),
                    ],
                  ),
                ),
                if (!isSettled) ...[
                  SizedBox(height: 16.h),
                  BlocBuilder<DebtCubit, DebtState>(
                    builder: (context, state) {
                      final isLoading = state is DebtLoading;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => onPayPartial(item),
                              icon: isLoading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor,
                                      ),
                                    )
                                  : Icon(Icons.payments_outlined, size: 16.r),
                              label: Text(AppStrings.partialPayLabel.tr()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                side: BorderSide(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                textStyle: TextStyles.customStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => onPayFull(item),
                              icon: isLoading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check_circle_outline,
                                      size: 16.r,
                                    ),
                              label: Text(AppStrings.fullPaymentLabel.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.whiteColor,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                textStyle: TextStyles.customStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _FinancialCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _FinancialCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyles.customStyle(
              color: AppColors.disabledColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount > 0.0
                  ? '${amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                  : '0.0 ${AppStrings.currencyEgp.tr()}',
              style: TextStyles.customStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.disabledColor.withValues(alpha: 0.2),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}
