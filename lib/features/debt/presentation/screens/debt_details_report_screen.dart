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
import 'package:tahsel/features/debt/presentation/widgets/build_debt_details_summary_card.dart';
import 'package:tahsel/features/debt/presentation/widgets/debt_details_report_transaction_item.dart';
import 'package:tahsel/features/debt/presentation/widgets/debt_details_report_summary_item.dart';
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
  bool _hasChanged = false;
  DebtEntity? _updatedDebt;

  @override

  void initState() {
    super.initState();
    context.read<DebtDetailsCubit>().loadTransactions(AppStrings.userToken, widget.debtId);
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
          _hasChanged = true;
          _updatedDebt = state.debt;
        } else if (state is DebtDetailsDeleteSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: AppStrings.deleteSuccess.tr(),
            operationType: 'delete',
          );
          _hasChanged = true;
          _updatedDebt = state.debt;
        } else if (state is DebtDetailsNotFound) {
          Navigator.pop(context, true);
        } else if (state is DebtDetailsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && result == null) {
            // This handles the system back button. 
            // We can't actually change the result here in older Flutter versions 
            // but in recent ones we might. 
            // However, Navigator.pop(context, value) is called from our back button.
            // If result is already set, we don't need to do anything.
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
            onPressed: () => Navigator.pop(context, _updatedDebt ?? _hasChanged),

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
                  AppStrings.userToken,
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
                          child: BuildDebtDetailsSummaryCard(totalAmount: state.totalAmount, amountPaid: state.totalPaid, remainingDebt: state.remainingDebt, debt: state.debt),
                        );
                      } else if (state is DebtDetailsUpdateSuccess) {
                        return SliverToBoxAdapter(
                          child: BuildDebtDetailsSummaryCard(totalAmount: state.totalAmount, amountPaid: state.totalPaid, remainingDebt: state.remainingDebt, debt: state.debt),
                        );
                      } else if (state is DebtDetailsDeleteSuccess) {
                        return SliverToBoxAdapter(
                          child: BuildDebtDetailsSummaryCard(totalAmount: state.totalAmount, amountPaid: state.totalPaid, remainingDebt: state.remainingDebt, debt: state.debt),
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
                                        AppStrings.userToken,
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
    ));
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
          return DebtDetailsReportTransactionItem(
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
