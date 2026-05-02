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
import 'package:tahsel/features/customer/presentation/widgets/notification_dialog.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_state.dart';
import 'package:tahsel/shared/widgets/shimmer/transaction_skeleton.dart';

class DebtDetailsReportScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailsReportScreen({super.key, required this.debtId});

  @override
  State<DebtDetailsReportScreen> createState() =>
      _DebtDetailsReportScreenState();
}

class _DebtDetailsReportScreenState extends State<DebtDetailsReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DebtDetailsCubit>().loadTransactions(widget.debtId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtDetailsCubit, DebtDetailsState>(
      listener: (context, state) {
        if (state is DebtDetailsUpdateSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: state.note,
            operationType: 'edit',
          );
        } else if (state is DebtDetailsDeleteSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: AppStrings.deleteSuccess.tr(),
            operationType: 'delete',
          );
        } else if (state is DebtDetailsNotFound) {
          Navigator.pop(context);
        } else if (state is DebtDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          title: Text(
            AppStrings.debtDetails.tr(),
            style: TextStyles.customStyle(
              color: AppColors.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textColor,
              size: 20.r,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            await context.read<DebtDetailsCubit>().loadTransactions(
              widget.debtId,
              forceRefresh: true,
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              BlocBuilder<DebtDetailsCubit, DebtDetailsState>(
                builder: (context, state) {
                  if (state is DebtDetailsLoaded) {
                    return SliverToBoxAdapter(
                      child: _buildSummaryCard(
                        totalAmount: state.totalAmount,
                        amountPaid: state.totalPaid,
                        remainingDebt: state.remainingDebt,
                        debt: state.debt,
                      ),
                    );
                  } else if (state is DebtDetailsUpdateSuccess) {
                    return SliverToBoxAdapter(
                      child: _buildSummaryCard(
                        totalAmount: state.totalAmount,
                        amountPaid: state.totalPaid,
                        remainingDebt: state.remainingDebt,
                        debt: state.debt,
                      ),
                    );
                  } else if (state is DebtDetailsDeleteSuccess) {
                    return SliverToBoxAdapter(
                      child: _buildSummaryCard(
                        totalAmount: state.totalAmount,
                        amountPaid: state.totalPaid,
                        remainingDebt: state.remainingDebt,
                        debt: state.debt,
                      ),
                    );
                  }
                  // Loading or initial
                  return SliverToBoxAdapter(child: _buildSummarySkeleton());
                },
              ),
              BlocBuilder<DebtDetailsCubit, DebtDetailsState>(
                builder: (context, state) {
                  if (state is DebtDetailsLoading) {
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: const TransactionCardSkeleton(),
                          ),
                          childCount: 5,
                        ),
                      ),
                    );
                  } else if (state is DebtDetailsLoaded) {
                    if (state.transactions.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            AppStrings.noTransactions.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildTransactionList(
                      state.transactions,
                      state.debt,
                    );
                  } else if (state is DebtDetailsUpdateSuccess) {
                    return _buildTransactionList(
                      state.transactions,
                      state.debt,
                    );
                  } else if (state is DebtDetailsDeleteSuccess) {
                    return _buildTransactionList(
                      state.transactions,
                      state.debt,
                    );
                  } else if (state is DebtDetailsError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              style: TextStyles.customStyle(
                                color: AppColors.error,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<DebtDetailsCubit>()
                                  .loadTransactions(
                                    widget.debtId,
                                    forceRefresh: true,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(AppStrings.tryAgain.tr()),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalAmount,
    required double amountPaid,
    required double remainingDebt,
    DebtEntity? debt,
  }) {
    final bool isSettled = remainingDebt <= 0;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSettled
              ? [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ]
              : [AppColors.error.withOpacity(0.9), AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isSettled ? AppColors.primaryColor : AppColors.error)
                .withOpacity(0.3),
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
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        debt?.productOrSessionDetails ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (debt?.ledgerNumber != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          '${AppStrings.ledgerNumber.tr()}: ${debt?.ledgerNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isSettled
                      ? AppStrings.fullSettlement.tr()
                      : AppStrings.debtStatusOverdue.tr(),
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: AppStrings.totalDueLabel.tr(),
                value: totalAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              _SummaryItem(
                label: AppStrings.paid.tr(),
                value: amountPaid.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              _SummaryItem(
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

  Widget _buildTransactionList(
    List<PaymentEntity> transactions,
    DebtEntity? debt,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final transaction = transactions[index];
          return _TransactionItem(
            transaction: transaction,
            debtId: widget.debtId,
            customerName: debt?.customerName ?? '',
          );
        }, childCount: transactions.length),
      ),
    );
  }

  Widget _buildSummarySkeleton() {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      height: 180.h,
      decoration: BoxDecoration(
        color: AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(24.r),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.customStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value ${AppStrings.currencyEgp.tr()}',
              style: TextStyles.customStyle(
                color: Colors.white,
                fontSize: isHighlighted ? 16.sp : 14.sp,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final PaymentEntity transaction;
  final String debtId;
  final String customerName;

  const _TransactionItem({
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

    if (state is DebtDetailsLoaded) {
      final index = state.transactions.indexOf(transaction);
      // Rule 1: Only latest 2 items
      final bool isLatest2 = index >= 0 && index < 2;

      if (isLatest2) {
        canEdit = true;
        canDelete = true;

        // Rule 2: For 'Add Debt' items, check for newer payments
        if (transaction.type == PaymentType.debtAdded) {
          final hasNewerPayments = state.transactions.any(
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
                color: Colors.black.withOpacity(0.02),
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
                          .withOpacity(0.1),
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
                        fontSize: 14.sp,
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
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      dateStr,
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 11.sp,
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
                        fontSize: 15.sp,
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
                        fontSize: 10.sp,
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
    if (cubit.state is DebtDetailsLoaded) {
      final loadedState = cubit.state as DebtDetailsLoaded;
      if (transaction.type == PaymentType.debtAdded) {
        minAmount = loadedState.totalPaid;
      } else {
        // Business Rule: No negative adjustments (newValue >= current)
        minAmount = transaction.amountPaid;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
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
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      AppStrings.amountPaid.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12.r),
                        border: errorText != null
                            ? Border.all(color: AppColors.error, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppStrings.currencyEgp.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
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
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (errorText != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        errorText!,
                        style: TextStyles.customStyle(
                          color: AppColors.error,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    if (minAmount > 0)
                      Text(
                        "${AppStrings.minValueHint.tr()} ${minAmount.toSmartAmount()}",
                        style: TextStyles.customStyle(
                          color: AppColors.primaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(height: 16.h),
                    Text(
                      AppStrings.notes.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontSize: 12.sp,
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.notes.tr(),
                          hintStyle: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 16.sp,
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
                              () => errorText = AppStrings.invalidValue.tr(),
                            );
                            return;
                          }

                          final newAmountRounded = double.parse(
                            newAmount.toStringAsFixed(2),
                          );
                          final minAmountRounded = double.parse(
                            minAmount.toStringAsFixed(2),
                          );

                          if (newAmountRounded < minAmountRounded) {
                            setState(
                              () => errorText = AppStrings.minValueError.tr(),
                            );
                            return;
                          }

                          cubit.updatePayment(
                            uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                            debtId: debtId,
                            paymentId: transaction.id ?? '',
                            newAmount: newAmount,
                            customerName: customerName,
                            note: noteController.text,
                          );
                          Navigator.pop(dialogContext);
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
                            fontSize: 18.sp,
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
                            fontSize: 18.sp,
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
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final cubit = context.read<DebtDetailsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.delete.tr()),
        content: Text(AppStrings.deleteTransactionConfirmation.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                color: AppColors.disabledColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.deletePayment(
                uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                debtId: debtId,
                paymentId: transaction.id ?? '',
                customerName: customerName,
                amountBeingDeleted: transaction.amountPaid,
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
