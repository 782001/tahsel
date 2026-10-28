import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/vault_transaction_entity.dart';
import '../cubit/vault_cubit.dart';
import 'edit_manual_transaction_dialog.dart';

class VaultTransactionCard extends StatelessWidget {
  final VaultTransactionEntity transaction;

  const VaultTransactionCard({super.key, required this.transaction});

  void _onSelectedMenu(BuildContext context, String value) {
    if (value == 'edit') {
      showDialog(
        context: context,
        builder: (dialogContext) => EditManualTransactionDialog(
          transaction: transaction,
          onSubmit: (newAmount, newDescription) {
            context.read<VaultCubit>().editManualTransaction(
              transaction: transaction,
              newAmount: newAmount,
              newDescription: newDescription,
            );
          },
        ),
      );
    } else if (value == 'delete') {
      _showDeleteConfirmDialog(context);
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: AppColors.scafoldBackGround,
        title: Text(
          AppStrings.confirmDeleteTransaction.tr(),
          style: TextStyles.customStyle(
            color: AppColors.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppStrings.deleteTransactionWarning.tr(),
          style: TextStyles.customStyle(
            color: AppColors.subTitleColor,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                color: AppColors.disabledColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<VaultCubit>().deleteManualTransaction(transaction);
            },
            child: Text(
              AppStrings.deleteTransaction.tr(),
              style: TextStyles.customStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isIn = transaction.direction == VaultTransactionDirection.inFlow;
    final isManual =
        transaction.source == VaultTransactionSource.manualDeposit ||
        transaction.source == VaultTransactionSource.manualWithdrawal;

    final IconData sourceIcon = _getSourceIcon(transaction.source);
    final Color sourceColor = _getSourceColor(transaction.source, isIn);
    final String sourceLabel = _getSourceLabel(
      transaction.source,
      transaction.type,
    );

    final dateStr = DateFormat(
      'yyyy-MM-dd • hh:mm a',
      'en',
    ).format(transaction.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 10.h),
      padding: EdgeInsets.all(isDesktop ? 12 : 10.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 8.w),
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              sourceIcon,
              color: sourceColor,
              size: isDesktop ? 22 : 20.sp,
            ),
          ),
          SizedBox(width: isDesktop ? 5 : 5.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: isDesktop ? 6 : 6.w,
                  runSpacing: isDesktop ? 4 : 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 6.w,
                        vertical: isDesktop ? 3 : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: sourceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        sourceLabel,
                        style: TextStyles.customStyle(
                          color: sourceColor,
                          fontSize: isDesktop ? 12 : 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildPaymentMethodBadge(isDesktop),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 4.h),
                Text(
                  transaction.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isDesktop ? 6 : 4.h),
                Text(
                  dateStr,
                  maxLines: 1,
                  style: TextStyles.customStyle(
                    color: AppColors.subTitleColor,
                    fontSize: isDesktop ? 11 : 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isIn ? '+' : '-'} ${transaction.amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                style: TextStyles.customStyle(
                  color: isIn ? AppColors.vaultInflow : AppColors.vaultOutflow,
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isManual) ...[
                SizedBox(width: 4.w),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.subTitleColor,
                    size: isDesktop ? 20 : 18.sp,
                  ),
                  onSelected: (value) => _onSelectedMenu(context, value),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.edit.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.deleteTransaction.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBadge(bool isDesktop) {
    final isCard = transaction.paymentMethod.toLowerCase() == 'card';
    final color = isCard ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final label = isCard
        ? AppStrings.vaultFilterCard.tr()
        : AppStrings.vaultFilterCash.tr();
    final icon = isCard ? Icons.credit_card_rounded : Icons.payments_outlined;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 7 : 5.w,
        vertical: isDesktop ? 3 : 2.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 12 : 10.sp, color: color),
          SizedBox(width: isDesktop ? 4 : 3.w),
          Text(
            label,
            style: TextStyles.customStyle(
              color: color,
              fontSize: isDesktop ? 11 : 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSourceIcon(VaultTransactionSource source) {
    switch (source) {
      case VaultTransactionSource.customerDebt:
        return Icons.person_add_alt_1_rounded;
      case VaultTransactionSource.myDebt:
        return Icons.money_off_csred_rounded;
      case VaultTransactionSource.inventory:
        return Icons.inventory_2_rounded;
      case VaultTransactionSource.employee:
        return Icons.badge_rounded;
      case VaultTransactionSource.expense:
        return Icons.receipt_long_rounded;
      case VaultTransactionSource.manualDeposit:
        return Icons.south_west_rounded;
      case VaultTransactionSource.manualWithdrawal:
        return Icons.north_east_rounded;
      case VaultTransactionSource.custody:
        return Icons.account_balance_wallet_outlined;
      case VaultTransactionSource.all:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static Color _getSourceColor(VaultTransactionSource source, bool isIn) {
    if (isIn) return AppColors.vaultInflow;
    switch (source) {
      case VaultTransactionSource.myDebt:
        return AppColors.supplierCreditColor;
      case VaultTransactionSource.inventory:
        return AppColors.inventoryPurchasePurple;
      case VaultTransactionSource.employee:
        return AppColors.primaryColor;
      case VaultTransactionSource.expense:
        return AppColors.vaultOutflow;
      case VaultTransactionSource.custody:
        return AppColors.primaryColor;
      default:
        return AppColors.vaultOutflow;
    }
  }

  static String _getSourceLabel(VaultTransactionSource source, String type) {
    switch (source) {
      case VaultTransactionSource.customerDebt:
        return AppStrings.cashboxSourceCustomerDebt.tr();
      case VaultTransactionSource.myDebt:
        return AppStrings.cashboxSourceSupplierDebt.tr();
      case VaultTransactionSource.inventory:
        return AppStrings.cashboxSourceInventoryPurchase.tr();
      case VaultTransactionSource.employee:
        if (type == 'salary_payment') return AppStrings.salaryPayment.tr();
        if (type == 'employee_advance') return AppStrings.employeeAdvance.tr();
        return AppStrings.cashboxSourceEmployee.tr();
      case VaultTransactionSource.expense:
        return AppStrings.cashboxSourceExpense.tr();
      case VaultTransactionSource.manualDeposit:
        return AppStrings.cashboxSourceManualAdd.tr();
      case VaultTransactionSource.manualWithdrawal:
        return AppStrings.cashboxSourceManualWithdraw.tr();
      case VaultTransactionSource.custody:
        if (type == 'custody_disbursement') {
          return AppStrings.newCustody.tr();
        }
        if (type == 'custody_settlement_refund') {
          return AppStrings.custodySettled.tr();
        }
        if (type == 'custody_settlement_reimbursement') {
          return AppStrings.settleCustody.tr();
        }
        return AppStrings.custodyTitle.tr();
      case VaultTransactionSource.all:
        return AppStrings.filterAll.tr();
    }
  }
}
