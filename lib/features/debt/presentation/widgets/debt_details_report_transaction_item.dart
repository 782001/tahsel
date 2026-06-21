import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

class DebtDetailsReportTransactionItem extends StatelessWidget {
  final PaymentEntity transaction;
  final String debtId;
  final String customerName;

  const DebtDetailsReportTransactionItem({
    super.key,
    required this.transaction,
    required this.debtId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebtDetailsCubit>();
    final state = cubit.state;
    final bool isDebtAdded = transaction.type == PaymentType.debtAdded;

    bool canEdit = false;
    bool canDelete = false;

    List<PaymentEntity>? transactions;
    if (state is DebtDetailsLoaded) {
      transactions = state.transactions;
    } else if (state is DebtDetailsUpdateSuccess) {
      transactions = state.transactions;
    } else if (state is DebtDetailsDeleteSuccess) {
      transactions = state.transactions;
    }

    if (transactions != null) {
      final index = transactions.indexOf(transaction);
      // Rule 1: Only latest 2 items
      final bool isLatest2 = index >= 0 && index < 2;

      if (isLatest2) {
        canEdit = true;
        canDelete = true;

        // Rule 2: For 'Add Debt' items, check for newer payments
        if (transaction.type == PaymentType.debtAdded) {
          final hasNewerPayments = transactions.any(
            (t) =>
                (t.type == PaymentType.partial ||
                    t.type == PaymentType.full ||
                    t.type == PaymentType.settlement) &&
                t.createdAt!.isAfter(transaction.createdAt!),
          );
          if (hasNewerPayments) {
            canDelete = false;
          }
        }
      }
    }

    final String dateStr = transaction.createdAt != null
        ? DateFormat(
            'yyyy/MM/dd - hh:mm a',
            AppStrings.currentLang,
          ).format(transaction.createdAt!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Slidable(
        key: ValueKey(transaction.id),
        startActionPane: canEdit
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) => _showEditDialog(context),
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: AppStrings.edit.tr(),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ],
              )
            : null,
        endActionPane: canDelete
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) => _showDeleteDialog(context),
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: AppStrings.delete.tr(),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ],
              )
            : null,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.debtCardSurface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color:
                      (isDebtAdded ? AppColors.error : AppColors.primaryColor)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isDebtAdded
                      ? Icons.add_circle_outline
                      : Icons.account_balance_wallet_outlined,
                  color: isDebtAdded ? AppColors.error : AppColors.primaryColor,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionTitle(),
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (transaction.activityName != null &&
                        transaction.activityName!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        transaction.activityName!,
                        style: TextStyles.customStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Flexible(
                      child: Text(
                        dateStr,
                        style: TextStyles.customStyle(
                          color: AppColors.disabledColor,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${isDebtAdded ? "+" : "-"}${transaction.amountPaid.abs().toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                      style: TextStyles.customStyle(
                        color: isDebtAdded
                            ? AppColors.error
                            : AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${AppStrings.remaining.tr()}: ${transaction.remainingAmount.toSmartAmount()}',
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final cubit = context.read<DebtDetailsCubit>();
    final TextEditingController amountController = TextEditingController(
      text: transaction.amountPaid.toString(),
    );
    final TextEditingController noteController = TextEditingController(
      text: transaction.activityName ?? '',
    );

    double minAmount = 0;
    double? maxAmount;
    if (cubit.state is DebtDetailsLoaded) {
      final loadedState = cubit.state as DebtDetailsLoaded;
      if (transaction.type == PaymentType.debtAdded) {
        minAmount = loadedState.totalPaid;
      } else {
        // Business Rule: No negative adjustments (newValue >= current)
        minAmount = transaction.amountPaid;
        maxAmount = loadedState.remainingDebt + transaction.amountPaid;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),

              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                backgroundColor: AppColors.scafoldBackGround,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.editPayment.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          AppStrings.amountPaid.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12.r),
                            border: errorText != null
                                ? Border.all(color: AppColors.error, width: 1)
                                : null,
                          ),
                          child: TextField(
                            cursorColor: AppColors.primaryColor,
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (errorText != null) {
                                setState(() => errorText = null);
                              }
                            },
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyles.customStyle(
                                color: AppColors.disabledColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              prefixIcon: Text(
                                AppStrings.currencyEgp.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                        ),
                        if (errorText != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            errorText!,
                            style: TextStyles.customStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        SizedBox(height: 16.h),
                        if (minAmount > 0 &&
                            transaction.type == PaymentType.debtAdded)
                          Text(
                            "${AppStrings.minValueHint.tr()} ${minAmount.toSmartAmount()}",
                            style: TextStyles.customStyle(
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        SizedBox(height: 16.h),
                        Text(
                          AppStrings.notes.tr(),
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TextField(
                            controller: noteController,
                            maxLines: 2,
                            cursorColor: AppColors.primaryColor,
                            style: TextStyles.customStyle(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: AppStrings.notes.tr(),
                              hintStyle: TextStyles.customStyle(
                                color: AppColors.disabledColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: () {
                              final double? newAmount = double.tryParse(
                                amountController.text,
                              );
                              if (newAmount == null || newAmount <= 0) {
                                setState(
                                  () =>
                                      errorText = AppStrings.invalidValue.tr(),
                                );
                                return;
                              }

                              final newAmountRounded = double.parse(
                                newAmount.toStringAsFixed(2),
                              );
                              final minAmountRounded = double.parse(
                                minAmount.toStringAsFixed(2),
                              );

                              if ((newAmountRounded < minAmountRounded) &&
                                  transaction.type == PaymentType.debtAdded) {
                                setState(
                                  () =>
                                      errorText = AppStrings.minValueError.tr(),
                                );
                                return;
                              }

                              if (maxAmount != null &&
                                  transaction.type != PaymentType.debtAdded) {
                                final maxAmountRounded = double.parse(
                                  maxAmount.toStringAsFixed(2),
                                );
                                if (newAmountRounded > maxAmountRounded) {
                                  setState(
                                    () => errorText = AppStrings
                                        .paymentExceedsRemaining
                                        .tr(),
                                  );
                                  return;
                                }
                              }
                              if (context.read<ConnectivityCubit>().state
                                  is ConnectivityDisconnected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppStrings.noInternetConnection.tr(),
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              cubit.updatePayment(
                                uid:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '',
                                debtId: debtId,
                                paymentId: transaction.id ?? '',
                                newAmount: newAmount,
                                customerName: customerName,
                                note: noteController.text,
                              );
                              if (Navigator.canPop(dialogContext)) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              AppStrings.confirm.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.disabledColor,
                            ),
                            child: Text(
                              AppStrings.cancel.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.disabledColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final connectivityCubit = context.read<ConnectivityCubit>();

    final cubit = context.read<DebtDetailsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

          child: AlertDialog(
            title: Text(AppStrings.delete.tr()),
            content: Text(AppStrings.deleteTransactionConfirmation.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  AppStrings.cancel.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.disabledColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (connectivityCubit.state is ConnectivityDisconnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.noInternetConnection.tr()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  cubit.deletePayment(
                    uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                    debtId: debtId,
                    paymentId: transaction.id ?? '',
                    customerName: customerName,
                    amountBeingDeleted: transaction.amountPaid,
                  );
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text(
                  AppStrings.delete.tr(),
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTransactionTitle() {
    switch (transaction.type) {
      case PaymentType.partial:
        return AppStrings.partialPayment.tr();
      case PaymentType.full:
        return AppStrings.fullPayment.tr();
      case PaymentType.settlement:
        return AppStrings.settlement.tr();
      case PaymentType.debtAdded:
        return AppStrings.debtAdded.tr();
      default:
        return AppStrings.paymentReceived.tr();
    }
  }
}
