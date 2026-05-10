import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:tahsel/features/debt/presentation/widgets/debt_detailes_report_transaction_item.dart';
import 'package:tahsel/features/debt/presentation/widgets/debt_detailes_report_summary_item.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textColor,
              size: 20.r,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, connectivityState) {
            if (connectivityState is ConnectivityDisconnected) {
              return NoInternetView(
                onRetry: () =>
                    context.read<ConnectivityCubit>().checkConnectivity(),
              );
            }
            return RefreshIndicator(
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
                                  fontSize: 14,
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
                                    fontSize: 13,
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
            );
          },
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
                  AppColors.primaryColor.withValues(alpha: 0.8),
                ]
              : [AppColors.error.withValues(alpha: 0.9), AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isSettled ? AppColors.primaryColor : AppColors.error)
                .withValues(alpha: 0.3),
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
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
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
                        padding: EdgeInsets.only(top: 4.h),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.whiteOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isSettled
                      ? AppStrings.fullSettlement.tr()
                      : AppStrings.debtStatusOverdue.tr(),
                  style: TextStyles.customStyle(
                    color: Colors.white,
                    fontSize: 10,
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
              DebtDetailesReportSummaryItem(
                label: AppStrings.totalDueLabel.tr(),
                value: totalAmount.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              DebtDetailesReportSummaryItem(
                label: AppStrings.paid.tr(),
                value: amountPaid.toSmartAmount(),
              ),
              SizedBox(width: 8.w),
              DebtDetailesReportSummaryItem(
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
          return DebtDetailesReportTransactionItem(
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
