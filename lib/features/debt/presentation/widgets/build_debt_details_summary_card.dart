import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/utils/vault_balance_helper.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_cubit.dart';
import 'package:tahsel/features/debt/presentation/widgets/debt_details_report_summary_item.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class BuildDebtDetailsSummaryCard extends StatelessWidget {
  const BuildDebtDetailsSummaryCard({
    super.key,
    required this.totalAmount,
    required this.amountPaid,
    required this.remainingDebt,
    this.debt,
  });

  final double totalAmount;
  final double amountPaid;
  final double remainingDebt;
  final DebtEntity? debt;

  Future<void> _handleRefundCustomerCredit(BuildContext context) async {
    if (debt == null) return;

    final connectivityState = context.read<ConnectivityCubit>().state;
    if (connectivityState is ConnectivityDisconnected) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }

    final creditAmount = remainingDebt.abs();
    if (creditAmount <= 0) return;

    // Pre-check Vault balance
    if (AppStrings.isVaultEnabled()) {
      final vaultSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(AppStrings.userToken)
          .collection('vault')
          .doc('summary')
          .get();
      if (!context.mounted) return;
      final double currentVaultBalance =
          (vaultSnap.exists && vaultSnap.data() != null)
              ? ((vaultSnap.data()!['currentBalance'] as num?)?.toDouble() ??
                  0.0)
              : 0.0;
      if (currentVaultBalance < creditAmount) {
        VaultBalanceHelper.showInsufficientBalanceDialog(context);
        return;
      }
    }

    if (!context.mounted) return;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double radius = isDesktop ? 20 : 20.r;
    final double titleFontSize = isDesktop ? 16 : 16.sp;
    final double bodyFontSize = isDesktop ? 13 : 13.sp;
    final double smallFontSize = isDesktop ? 12 : 12.sp;
    final double iconSize = isDesktop ? 22 : 22.sp;
    final double paddingVal = isDesktop ? 20 : 20.w;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: EdgeInsets.all(paddingVal),
        titlePadding: EdgeInsets.fromLTRB(
          paddingVal,
          paddingVal,
          paddingVal,
          0,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          paddingVal,
          0,
          paddingVal,
          paddingVal,
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 8 : 8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.error,
                size: iconSize,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : 12.w),
            Expanded(
              child: Text(
                AppStrings.confirmRefundCredit.tr(),
                style: TextStyles.customStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 340 : 280,
            maxWidth: isDesktop ? 440 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   AppStrings.refundConfirmationMessage.tr(
              //     args: [creditAmount.toSmartAmount()],
              //   ),
              //   style: TextStyles.customStyle(
              //     fontSize: bodyFontSize,
              //     color: AppColors.subTitleColor,
              //   ),
              // ),
              SizedBox(height: isDesktop ? 16 : 16.h),

              // Smart Financial Breakdown Card
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.customerNameLabel.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          child: Text(
                            debt?.customerName ??
                                AppStrings.unspecifiedCustomer.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.amountDeductedFromVault.tr(),
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              color: AppColors.subTitleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 8.w,
                            vertical: isDesktop ? 4 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 8.r,
                            ),
                          ),
                          child: Text(
                            '- ${creditAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 16.w,
                  vertical: isDesktop ? 10 : 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isDesktop ? 10 : 10.r),
                ),
              ),
              icon: Icon(
                Icons.output_rounded,
                size: isDesktop ? 18 : 18.sp,
                color: Colors.white,
              ),
              label: Text(
                AppStrings.refundCreditToCustomer.tr(),
                textAlign: TextAlign.center,
                style: TextStyles.customStyle(
                  fontSize: bodyFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                AppStrings.cancel.tr(),
                textAlign: TextAlign.center,
                style: TextStyles.customStyle(
                  fontSize: bodyFontSize,
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    final debtId = debt?.id;
    if (debtId == null) return;

    try {
      final isSuccess =
          await context.read<DebtDetailsCubit>().settleCustomerCredit(
                uid: AppStrings.userToken,
                debtId: debtId,
                creditAmount: creditAmount,
              );
      if (isSuccess && context.mounted) {
        showSuccessToast(AppStrings.refundCreditSuccess.tr());
      }
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains(AppStrings.insufficientBalance) ||
            e.toString().contains('insufficient_balance')) {
          VaultBalanceHelper.showInsufficientBalanceDialog(context);
        } else {
          showfailureToast(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSettled = remainingDebt <= 0;
    final bool hasCredit = remainingDebt < 0;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Three visual states:
    //   hasCredit → amber/gold  (customer has a refund balance)
    //   isSettled → green/primary (fully paid, nothing owed)
    //   default   → red (still has an outstanding debt)
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
        ? AppStrings.customerCredit.tr()
        : isSettled
        ? AppStrings.fullSettlement.tr()
        : AppStrings.debtStatusOverdue.tr();

    return Container(
      margin: EdgeInsets.all(isDesktop ? 16 : 16.r),
      padding: EdgeInsets.all(isDesktop ? 20 : 20.r),
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
                      debt?.customerName ?? '',
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
                        borderRadius: BorderRadius.circular(
                          isDesktop ? 8 : 8.r,
                        ),
                      ),
                      child: Text(
                        debt?.productOrSessionDetails ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (debt?.ledgerNumber != null)
                      Padding(
                        padding: EdgeInsets.only(top: isDesktop ? 4 : 4.h),
                        child: Text(
                          '${AppStrings.ledgerNumber.tr()}: ${debt?.ledgerNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            color: AppColors.whiteOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 12.w,
                  vertical: isDesktop ? 6 : 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity(0.2),
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
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
            ],
          ),

          // ── Customer Credit banner ───────────────────────────────────────────
          if (hasCredit) ...[
            SizedBox(height: isDesktop ? 16 : 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: isDesktop ? 18 : 18.r,
                      ),
                      SizedBox(width: isDesktop ? 8 : 8.w),
                      Expanded(
                        child: Text(
                          '${AppStrings.customerCredit.tr()}:  ${remainingDebt.abs().toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                          style: TextStyles.customStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 10 : 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRefundCustomerCredit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.creditAmberEnd,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 12 : 12.w,
                          vertical: isDesktop ? 8 : 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isDesktop ? 10 : 10.r,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.output_rounded,
                        color: AppColors.creditAmberEnd,
                        size: isDesktop ? 16 : 16.sp,
                      ),
                      label: Text(
                        AppStrings.refundCreditToCustomer.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.creditAmberEnd,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: isDesktop ? 24 : 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DebtDetailsReportSummaryItem(
                label: AppStrings.totalDueLabel.tr(),
                value: totalAmount.toSmartAmount(),
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              DebtDetailsReportSummaryItem(
                label: AppStrings.paid.tr(),
                value: amountPaid.toSmartAmount(),
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              DebtDetailsReportSummaryItem(
                label: AppStrings.remaining.tr(),
                value: remainingDebt.toSmartAmount(),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
