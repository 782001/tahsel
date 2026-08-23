import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/my_debt_details_summary_item.dart';

class BuildMyDebtDetailsSummaryCard extends StatelessWidget {
  const BuildMyDebtDetailsSummaryCard({
    super.key,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingDebt,
    this.debt,
    this.debtId,
  });

  final double totalAmount;
  final double amountPaid;
  final double remainingDebt;
  final MyDebtItemEntity? debt;
  final String? debtId;

  @override
  Widget build(BuildContext context) {
    final bool isSettled = remainingDebt <= 0;
    final bool hasCredit = remainingDebt < 0 || (amountPaid > totalAmount);
    final double supplierCredit = hasCredit
        ? (amountPaid > totalAmount
              ? (amountPaid - totalAmount)
              : remainingDebt.abs())
        : 0.0;

    // Three visual states:
    //   hasCredit → amber/gold  (supplier credit / money owed back to business)
    //   isSettled → green/primary (fully paid, nothing owed)
    //   default   → red (still has outstanding debt to pay supplier)
    final Color cardColor = hasCredit
        ? AppColors.creditAmberEnd
        : isSettled
        ? AppColors.primaryColor
        : AppColors.error;

    final List<Color> gradientColors = hasCredit
        ? [AppColors.creditAmberStart, AppColors.creditAmberEnd]
        : isSettled
        ? [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ]
        : [AppColors.error.withValues(alpha: 0.9), AppColors.error];

    final String statusBadgeLabel = hasCredit
        ? AppStrings.supplierCredit.tr()
        : isSettled
        ? AppStrings.fullSettlement.tr()
        : AppStrings.debtStatusOverdue.tr();

    final double displayRemaining = remainingDebt < 0 ? 0.0 : remainingDebt;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Container(
      margin: EdgeInsets.all(isDesktop ? 16 : 16.r),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 24.r),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt?.personName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 8.w,
                        vertical: isDesktop ? 2 : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        debt?.details ?? AppStrings.noDescription.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 12.w,
                    vertical: isDesktop ? 6 : 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    statusBadgeLabel,
                    style: TextStyles.customStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Supplier Credit banner & Refund Settlement Button ──────────
          if (hasCredit) ...[
            SizedBox(height: isDesktop ? 4 : 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 12 : 12.w,
                vertical: isDesktop ? 10 : 10.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 18.r,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8.w),
                  Expanded(
                    child: Text(
                      '${AppStrings.supplierCredit.tr()}: ${supplierCredit.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _confirmSettleSupplierCredit(context, supplierCredit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.supplierCreditColor,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 14.w,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.supplierCreditColor,
                ),
                label: Text(
                  AppStrings.settleSupplierCredit.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.supplierCreditColor,
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyDebtDetailsSummaryItem(
                label: AppStrings.totalDueLabel.tr(),
                value: totalAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              MyDebtDetailsSummaryItem(
                label: AppStrings.paid.tr(),
                value: amountPaid.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              MyDebtDetailsSummaryItem(
                label: hasCredit
                    ? AppStrings.supplierCredit.tr()
                    : AppStrings.remaining.tr(),
                value: (hasCredit ? supplierCredit : displayRemaining)
                    .toSmartAmount(),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmSettleSupplierCredit(
    BuildContext context,
    double creditAmount,
  ) async {
    final formattedAmount =
        '${creditAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          AppStrings.supplierCredit.tr(),
          style: TextStyles.customStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.supplierCreditColor,
          ),
        ),
        content: Text(
          AppStrings.settleSupplierCreditConfirmMsg.tr(
            namedArgs: {'amount': formattedAmount},
          ),
          style: TextStyles.customStyle(
            fontSize: 14,
            color: AppColors.blackReal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(color: AppColors.blackLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.supplierCreditColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.confirm.tr(),
              style: TextStyles.customStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final cubit = context.read<MyDebtDetailsReportCubit>();
      final uid = (debt?.uid != null && debt!.uid.isNotEmpty)
          ? debt!.uid
          : AppStrings.userToken;
      final targetDebtId = (debtId != null && debtId!.isNotEmpty)
          ? debtId!
          : (debt?.id ?? '');
      final personName = debt?.personName ?? '';

      if (uid.isNotEmpty && targetDebtId.isNotEmpty) {
        await cubit.settleSupplierCredit(
          uid: uid,
          debtId: targetDebtId,
          personName: personName,
          creditAmount: creditAmount,
        );
      }
    }
  }
}
