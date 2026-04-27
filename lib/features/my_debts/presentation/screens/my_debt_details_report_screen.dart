import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_item_entity.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_state.dart';
import 'package:tahsel/shared/widgets/shimmer/transaction_skeleton.dart';

class MyDebtDetailsReportScreen extends StatefulWidget {
  final MyDebtItemEntity debt;

  const MyDebtDetailsReportScreen({super.key, required this.debt});

  @override
  State<MyDebtDetailsReportScreen> createState() =>
      _MyDebtDetailsReportScreenState();
}

class _MyDebtDetailsReportScreenState extends State<MyDebtDetailsReportScreen> {
  @override
  void initState() {
    super.initState();
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<MyDebtDetailsReportCubit>().loadTransactions(
        uid,
        widget.debt.id ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = sl<FirebaseAuth>().currentUser?.uid ?? '';
    return Scaffold(
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
          await context.read<MyDebtDetailsReportCubit>().loadTransactions(
                uid,
                widget.debt.id ?? '',
                forceRefresh: true,
              );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCard()),
            BlocBuilder<MyDebtDetailsReportCubit, MyDebtDetailsReportState>(
              builder: (context, state) {
                if (state is MyDebtDetailsReportLoading) {
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const TransactionCardSkeleton(),
                        childCount: 5,
                      ),
                    ),
                  );
                } else if (state is MyDebtDetailsReportLoaded) {
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
                  return _buildTransactionList(state.transactions);
                } else if (state is MyDebtDetailsReportError) {
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
                                .read<MyDebtDetailsReportCubit>()
                                .loadTransactions(
                                  uid,
                                  widget.debt.id ?? '',
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
    );
  }

  Widget _buildSummaryCard() {
    final bool isSettled = widget.debt.remainingAmount <= 0;

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
                      widget.debt.personName ?? '',
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
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        widget.debt.details ?? AppStrings.noDescription.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
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
                value: widget.debt.totalAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              _SummaryItem(
                label: AppStrings.paid.tr(),
                value: widget.debt.paidAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              _SummaryItem(
                label: AppStrings.remaining.tr(),
                value: widget.debt.remainingAmount.toSmartAmount(),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<PaymentEntity> transactions) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = transactions[index];
            return _TransactionItem(transaction: transaction);
          },
          childCount: transactions.length,
        ),
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

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isPayment = transaction.type != PaymentType.debtAdded;
    final String dateStr = transaction.createdAt != null
        ? DateFormat(
            'yyyy/MM/dd - hh:mm a',
            AppStrings.currentLang,
          ).format(transaction.createdAt!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
              color: (isPayment ? AppColors.primaryColor : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isPayment
                  ? Icons.account_balance_wallet_outlined
                  : Icons.add_circle_outline,
              color: isPayment ? AppColors.primaryColor : AppColors.error,
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
                  '${isPayment ? "-" : "+"}${transaction.amountPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    color: isPayment ? AppColors.primaryColor : AppColors.error,
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
