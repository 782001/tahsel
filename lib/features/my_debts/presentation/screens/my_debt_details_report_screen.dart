import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/widgets/notification_dialog.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_state.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/build_my_debt_details_summary_card.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/build_my_debt_details_summary_skeleton.dart';
import 'package:tahsel/features/my_debts/presentation/widgets/build_my_debt_details_transaction_list.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
import 'package:tahsel/shared/widgets/shimmer/transaction_skeleton.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class MyDebtDetailsReportScreen extends StatefulWidget {
  final String debtId;

  const MyDebtDetailsReportScreen({super.key, required this.debtId});

  @override
  State<MyDebtDetailsReportScreen> createState() =>
      _MyDebtDetailsReportScreenState();
}

class _MyDebtDetailsReportScreenState extends State<MyDebtDetailsReportScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<MyDebtDetailsReportCubit>().loadTransactions(
        uid,
        widget.debtId,
      );
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final uid = AppStrings.userToken;
      if (uid.isNotEmpty) {
        context.read<MyDebtDetailsReportCubit>().loadMoreTransactions(
          uid,
          widget.debtId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AppStrings.userToken;
    return BlocListener<MyDebtDetailsReportCubit, MyDebtDetailsReportState>(
      listener: (context, state) {
        if (state is MyDebtDetailsUpdateSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: state.note,
            operationType: 'edit',
          );
        } else if (state is MyDebtDetailsDeleteSuccess) {
          NotificationDialog.show(
            context: context,
            customerName: state.customerName,
            amountPaid: state.amountPaid,
            remainingBalance: state.remainingBalance,
            note: AppStrings.deleteSuccess.tr(),
            operationType: 'delete',
          );
        } else if (state is MyDebtDetailsReportNotFound) {
          Navigator.pop(context);
        } else if (state is MyDebtDetailsReportError) {
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
            final isDesktop = ResponsiveLayout.isDesktop(context);
            if (connectivityState is ConnectivityDisconnected) {
              return NoInternetView(
                onRetry: () =>
                    context.read<ConnectivityCubit>().checkConnectivity(),
              );
            }
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                await context.read<MyDebtDetailsReportCubit>().loadTransactions(
                  uid,
                  widget.debtId,
                  forceRefresh: true,
                );
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  BlocBuilder<
                    MyDebtDetailsReportCubit,
                    MyDebtDetailsReportState
                  >(
                    builder: (context, state) {
                      if (state is MyDebtDetailsReportLoaded) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800 : double.infinity,
                              ),
                              child: BuildMyDebtDetailsSummaryCard(
                                totalAmount: state.totalAmount,
                                amountPaid: state.paidAmount,
                                remainingDebt: state.remainingAmount,
                                debt: state.debt,
                              ),
                            ),
                          ),
                        );
                      } else if (state is MyDebtDetailsUpdateSuccess) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800 : double.infinity,
                              ),
                              child: BuildMyDebtDetailsSummaryCard(
                                totalAmount: state.totalAmount,
                                amountPaid: state.paidAmount,
                                remainingDebt: state.remainingAmount,
                                debt: state.debt,
                              ),
                            ),
                          ),
                        );
                      } else if (state is MyDebtDetailsDeleteSuccess) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800 : double.infinity,
                              ),
                              child: BuildMyDebtDetailsSummaryCard(
                                totalAmount: state.totalAmount,
                                amountPaid: state.paidAmount,
                                remainingDebt: state.remainingAmount,
                                debt: state.debt,
                              ),
                            ),
                          ),
                        );
                      }
                      // Loading or initial
                      return SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 800 : double.infinity,
                            ),
                            child: const BuildMyDebtDetailsSummarySkeleton(),
                          ),
                        ),
                      );
                    },
                  ),
                  BlocBuilder<
                    MyDebtDetailsReportCubit,
                    MyDebtDetailsReportState
                  >(
                    builder: (context, state) {
                      if (state is MyDebtDetailsReportLoading) {
                        final double screenWidth = MediaQuery.of(
                          context,
                        ).size.width;
                        final double horizontalPadding =
                            isDesktop && screenWidth > 800
                            ? (screenWidth - 800) / 2
                            : 16.w;
                        if (isDesktop) {
                          return SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 140,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 12,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    const TransactionCardSkeleton(),
                                childCount: 6,
                              ),
                            ),
                          );
                        }
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
                      } else if (state is MyDebtDetailsReportLoaded) {
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
                        return BuildMyDebtDetailsTransactionList(
                          widget: widget,
                          transactions: state.transactions,
                          debt: state.debt,
                          isPaginationLoading: state.isPaginationLoading,
                        );
                      } else if (state is MyDebtDetailsUpdateSuccess) {
                        return BuildMyDebtDetailsTransactionList(
                          widget: widget,
                          transactions: state.transactions,
                          debt: state.debt,
                          isPaginationLoading: state.isPaginationLoading,
                        );
                      } else if (state is MyDebtDetailsDeleteSuccess) {
                        return BuildMyDebtDetailsTransactionList(
                          widget: widget,
                          transactions: state.transactions,
                          debt: state.debt,
                          isPaginationLoading: state.isPaginationLoading,
                        );
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
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<MyDebtDetailsReportCubit>()
                                      .loadTransactions(
                                        uid,
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
}
