import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';
import 'package:tahsel/shared/widgets/shimmer/transaction_skeleton.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../customer_debts/data/models/debt_item_model.dart';
import '../../domain/entities/payment_entity.dart';
import '../cubit/global_payments/global_payments_cubit.dart';
import '../cubit/global_payments/global_payments_state.dart';

class CustomerGlobalPaymentsScreen extends StatefulWidget {
  final CustomerDebtDetail customerDetail;

  const CustomerGlobalPaymentsScreen({super.key, required this.customerDetail});

  @override
  State<CustomerGlobalPaymentsScreen> createState() =>
      _CustomerGlobalPaymentsScreenState();
}

class _CustomerGlobalPaymentsScreenState
    extends State<CustomerGlobalPaymentsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = widget.customerDetail.items.isNotEmpty
        ? widget.customerDetail.items.first.entity.uid
        : "";
    context.read<GlobalPaymentsCubit>().loadCustomerPayments(
      uid: uid,
      customerName: widget.customerDetail.customerName,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final uid = widget.customerDetail.items.isNotEmpty
          ? widget.customerDetail.items.first.entity.uid
          : "";
      if (uid.isNotEmpty) {
        context.read<GlobalPaymentsCubit>().loadMorePayments(
          uid: uid,
          customerName: widget.customerDetail.customerName,
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectivityState) {
          if (connectivityState is ConnectivityDisconnected) {
            return NoInternetView(
              onRetry: () {
                context.read<ConnectivityCubit>().checkConnectivity();
              },
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              final uid = widget.customerDetail.items.isNotEmpty
                  ? widget.customerDetail.items.first.entity.uid
                  : "";
              await context.read<GlobalPaymentsCubit>().loadCustomerPayments(
                uid: uid,
                customerName: widget.customerDetail.customerName,
                forceRefresh: true,
              );
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(),
                _buildSummarySection(),
                _buildTransactionList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return SliverAppBar(
      expandedHeight: isDesktop ? 140 : 180.h,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(isDesktop ? 24 : 24.r),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          children: [
            Positioned(
              right: -20.w,
              top: -20.h,
              child: CircleAvatar(
                radius: isDesktop ? 80 : 80.r,
                backgroundColor: AppColors.whiteOpacity(0.05),
              ),
            ),
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isDesktop ? 20 : 40.h),
                    Text(
                      widget.customerDetail.customerName,
                      style: TextStyles.customStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.customerDetail.ledgerNumber != null)
                      Container(
                        margin: EdgeInsets.only(top: isDesktop ? 8 : 8.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 12 : 12.w,
                          vertical: isDesktop ? 4 : 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.whiteOpacity(0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          "${AppStrings.ledgerNumber.tr()}: ${widget.customerDetail.ledgerNumber}",
                          style: TextStyles.customStyle(
                            color: AppColors.whiteOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppStrings.globalPaymentsReport.tr(),
        style: TextStyles.customStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummarySection() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = isDesktop && screenWidth > 800
        ? (screenWidth - 800) / 2
        : 20.w;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : horizontalPadding,
              vertical: isDesktop ? 16 : 20.h,
            ),
            child: BlocBuilder<GlobalPaymentsCubit, GlobalPaymentsState>(
              builder: (context, state) {
                double totalPaid = widget.customerDetail.totalPaid;

                return Container(
                  padding: EdgeInsets.all(isDesktop ? 20 : 20.r),
                  decoration: BoxDecoration(
                    color: AppColors.debtCardSurface,
                    borderRadius: BorderRadius.circular(isDesktop ? 24 : 24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: AppColors.isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          title: AppStrings.paid.tr(),
                          amount: totalPaid,
                          color: AppColors.success,
                          icon: Icons.check_circle_outline,
                          isDesktop: isDesktop,
                        ),
                      ),
                      Container(
                        height: isDesktop ? 50 : 50.h,
                        width: isDesktop ? 1 : 1.w,
                        color: AppColors.disabledColor.withValues(alpha: 0.1),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          title: AppStrings.remaining.tr(),
                          amount: widget.customerDetail.totalDebt,
                          color: AppColors.error,
                          icon: Icons.account_balance_wallet_outlined,
                          isDesktop: isDesktop,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool isDesktop = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isDesktop ? 24 : 24.r),
        SizedBox(height: isDesktop ? 8 : 8.h),
        Text(
          title,
          style: TextStyles.customStyle(
            color: AppColors.disabledColor,
            fontSize: 12,
          ),
        ),
        SizedBox(height: isDesktop ? 4 : 4.h),
        Text(
          amount.toSmartAmount(),
          style: TextStyles.customStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = isDesktop && screenWidth > 800
        ? (screenWidth - 800) / 2
        : 20.w;

    return BlocBuilder<GlobalPaymentsCubit, GlobalPaymentsState>(
      builder: (context, state) {
        if (state is GlobalPaymentsLoading) {
          if (isDesktop) {
            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const TransactionCardSkeleton(),
                  childCount: 4,
                ),
              ),
            );
          }
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const TransactionCardSkeleton(),
                childCount: 3,
              ),
            ),
          );
        }

        if (state is GlobalPaymentsError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                AppStrings.noData.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        if (state is GlobalPaymentsLoaded) {
          if (state.transactions.isEmpty) {
            return SliverFillRemaining(
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

          if (isDesktop) {
            return SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                40,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == state.transactions.length) {
                    if (state.isPaginationLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 2,
                        ),
                      );
                    }
                    return const SizedBox();
                  }

                  final transaction = state.transactions[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 400 + (index * 30)),
                    child: _buildTransactionCard(transaction),
                  );
                }, childCount: state.transactions.length + 1),
              ),
            );
          }

          return SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == state.transactions.length) {
                  if (state.isPaginationLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 20);
                }

                final transaction = state.transactions[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 400 + (index * 30)),
                  child: _buildTransactionCard(transaction),
                );
              }, childCount: state.transactions.length + 1),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  Widget _buildTransactionCard(PaymentEntity transaction) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final bool isSettlement =
        transaction.type == PaymentType.settlement ||
        transaction.amountPaid < 0;
    final bool isAddition =
        transaction.type == PaymentType.debtAdded && !isSettlement;
    final Color typeColor = isSettlement
        ? AppColors.creditAmberEnd
        : (isAddition ? AppColors.error : AppColors.success);
    final String dateStr = transaction.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
            'ar',
          ).format(transaction.createdAt!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 16.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
      decoration: BoxDecoration(
        color: isSettlement
            ? AppColors.creditAmberEnd.withValues(alpha: 0.05)
            : AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
        border: Border.all(
          color: isSettlement
              ? AppColors.creditAmberEnd.withValues(alpha: 0.3)
              : AppColors.disabledColor.withValues(alpha: 0.05),
          width: isSettlement ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.activityName ??
                        (isSettlement
                            ? AppStrings.settlement.tr()
                            : (isAddition
                                  ? AppStrings.debtAdded.tr()
                                  : AppStrings.paymentReceived.tr())),
                    textAlign: TextAlign.start,
                    style: TextStyles.customStyle(
                      color: isSettlement
                          ? AppColors.creditAmberEnd
                          : AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isSettlement
                        ? "- ${transaction.amountPaid.abs().toSmartAmount()}"
                        : "${isAddition ? '+' : '-'}${transaction.amountPaid.abs().toSmartAmount()}",
                    style: TextStyles.customStyle(
                      color: typeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 4 : 4.h),
                  Text(
                    "${AppStrings.remaining.tr()}: ${transaction.remainingAmount.toSmartAmount()}",
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          const Divider(height: 1, thickness: 0.5),
          SizedBox(height: isDesktop ? 12 : 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: isDesktop ? 14 : 14.r,
                    color: AppColors.disabledColor,
                  ),
                  SizedBox(width: isDesktop ? 6 : 6.w),
                  Text(
                    dateStr,
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (isSettlement)
                Icon(
                  Icons.output_rounded,
                  size: isDesktop ? 16 : 16.r,
                  color: AppColors.creditAmberEnd,
                )
              else if (!isAddition)
                Icon(
                  Icons.verified_outlined,
                  size: isDesktop ? 16 : 16.r,
                  color: AppColors.success.withValues(alpha: 0.5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
