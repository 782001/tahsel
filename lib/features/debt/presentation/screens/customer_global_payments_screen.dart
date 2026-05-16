import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
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
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AppColors.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          children: [
            Positioned(
              right: -20.w,
              top: -20.h,
              child: CircleAvatar(
                radius: 80.r,
                backgroundColor: AppColors.whiteOpacity(0.05),
              ),
            ),
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),
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
                        margin: EdgeInsets.only(top: 8.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: BlocBuilder<GlobalPaymentsCubit, GlobalPaymentsState>(
          builder: (context, state) {
            double totalPaid = state is GlobalPaymentsLoaded
                ? state.totalPaid
                : 0;

            return Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.debtCardSurface,
                borderRadius: BorderRadius.circular(24.r),
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
                    ),
                  ),
                  Container(
                    height: 50.h,
                    width: 1.w,
                    color: AppColors.disabledColor.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      title: AppStrings.remaining.tr(),
                      amount: widget.customerDetail.totalDebt,
                      color: AppColors.error,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.r),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyles.customStyle(
            color: AppColors.disabledColor,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4.h),
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
    return BlocBuilder<GlobalPaymentsCubit, GlobalPaymentsState>(
      builder: (context, state) {
        if (state is GlobalPaymentsLoading) {
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
                state.message,
                style: TextStyles.customStyle(
                  color: AppColors.error,
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
    final bool isAddition = transaction.type == PaymentType.debtAdded;
    final Color typeColor = isAddition ? AppColors.error : AppColors.success;
    final String dateStr = transaction.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
            'ar',
          ).format(transaction.createdAt!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.debtCardSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.disabledColor.withValues(alpha: 0.05),
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
                    isAddition
                        ? AppStrings.debtAdded.tr()
                        : AppStrings.paymentReceived.tr(),
                    textAlign: TextAlign.start,
                    style: TextStyles.customStyle(
                      color: AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // if (transaction.activityName != null &&
                  //     transaction.activityName!.isNotEmpty) ...[
                  //   SizedBox(height: 4.h),
                  //   Text(
                  //     transaction.activityName!,
                  //     style: TextStyles.customStyle(
                  //       color: AppColors.primaryColor,
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ],
                ],
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isAddition ? '+' : '-'}${transaction.amountPaid.toSmartAmount()}",
                    style: TextStyles.customStyle(
                      color: typeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4.h),
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
          SizedBox(height: 12.h),
          const Divider(height: 1, thickness: 0.5),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.r,
                    color: AppColors.disabledColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    dateStr,
                    style: TextStyles.customStyle(
                      color: AppColors.disabledColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (!isAddition)
                Icon(
                  Icons.verified_outlined,
                  size: 16.r,
                  color: AppColors.success.withValues(alpha: 0.5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
