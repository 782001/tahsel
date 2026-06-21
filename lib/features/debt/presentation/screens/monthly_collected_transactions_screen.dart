import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/debt/domain/entities/monthly_collected_amount.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';
import 'package:tahsel/features/debt/domain/usecases/get_all_user_payments_paginated_usecase.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';

class MonthlyCollectedTransactionsScreen extends StatefulWidget {
  final MonthlyCollectedAmount monthlyData;
  final String uid;

  const MonthlyCollectedTransactionsScreen({
    super.key,
    required this.monthlyData,
    required this.uid,
  });

  @override
  State<MonthlyCollectedTransactionsScreen> createState() =>
      _MonthlyCollectedTransactionsScreenState();
}

class _MonthlyCollectedTransactionsScreenState
    extends State<MonthlyCollectedTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<PaymentEntity> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadInitialPayments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePayments();
    }
  }

  Future<void> _loadInitialPayments() async {
    setState(() {
      _isLoading = true;
      _payments.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    final result = await sl<GetAllUserPaymentsPaginatedUseCase>().call(
      uid: widget.uid,
      limit: 15,
      month: widget.monthlyData.month,
      year: widget.monthlyData.year,
    );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (paginatedResult) {
          setState(() {
            // Only show actual collections (exclude debtAdded type)
            final actualCollections = paginatedResult.items.where(
              (p) => p.type != PaymentType.debtAdded,
            );
            _payments.addAll(actualCollections);
            _lastDocument = paginatedResult.lastDocument;
            _hasMore = paginatedResult.hasMore;
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _loadMorePayments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await sl<GetAllUserPaymentsPaginatedUseCase>().call(
      uid: widget.uid,
      limit: 15,
      lastDocument: _lastDocument,
      month: widget.monthlyData.month,
      year: widget.monthlyData.year,
    );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoadingMore = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (paginatedResult) {
          setState(() {
            // Only show actual collections (exclude debtAdded type)
            final actualCollections = paginatedResult.items.where(
              (p) => p.type != PaymentType.debtAdded,
            );
            _payments.addAll(actualCollections);
            _lastDocument = paginatedResult.lastDocument;
            _hasMore = paginatedResult.hasMore;
            _isLoadingMore = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final monthName = _getMonthName(widget.monthlyData.month, context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        title: Text(
          "$monthName ${widget.monthlyData.year}",
          style: TextStyles.customStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.scafoldBackGround,
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
        onRefresh: _loadInitialPayments,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Month Header
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildSummaryHeader(isDesktop),
                ),
              ),
            ),

            // Transaction List or Grid
            if (_isLoading)
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16.w,
                  vertical: 8.h,
                ),
                sliver: isDesktop
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 160,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const _TransactionCardSkeleton(),
                          childCount: 6,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const _TransactionCardSkeleton(),
                          childCount: 6,
                        ),
                      ),
              )
            else if (_payments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    AppStrings.noTransactions.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16.w,
                  vertical: 8.h,
                ),
                sliver: isDesktop
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 160,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final payment = _payments[index];
                          return FadeInUp(
                            duration: Duration(
                              milliseconds: 150 + (index % 10 * 15),
                            ),
                            child: _buildTransactionCard(
                              context,
                              payment,
                              isDesktop,
                            ),
                          );
                        }, childCount: _payments.length),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final payment = _payments[index];
                          return FadeInUp(
                            duration: Duration(
                              milliseconds: 150 + (index % 10 * 15),
                            ),
                            child: _buildTransactionCard(
                              context,
                              payment,
                              isDesktop,
                            ),
                          );
                        }, childCount: _payments.length),
                      ),
              ),

            // Loading More indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 8 : 16.h,
      ),
      padding: EdgeInsets.all(isDesktop ? 32 : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.totalCollected.tr(),
            style: TextStyles.customStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "${widget.monthlyData.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
            style: TextStyles.customStyle(
              color: Colors.white,
              fontSize: isDesktop ? 32 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    PaymentEntity payment,
    bool isDesktop,
  ) {
    final dateStr = payment.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
            Localizations.localeOf(context).languageCode,
          ).format(payment.createdAt!)
        : '';

    final accentColor = payment.type == PaymentType.full
        ? AppColors.green
        : AppColors.primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reading-direction-aware vertical accent colored strip
              Container(width: 4.r, color: accentColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Customer Name & Activity
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  payment.relatedTo ?? AppStrings.unknown.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (payment.activityName != null &&
                                    payment.activityName!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    payment.activityName!,
                                    style: TextStyles.customStyle(
                                      fontSize: 13,
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Amount
                          Flexible(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  child: Text(
                                    "+${payment.amountPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                                    style: TextStyles.customStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getPaymentTypeLabel(payment.type),
                                  style: TextStyles.customStyle(
                                    fontSize: 10,
                                    color: AppColors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 10 : 12.h),
                      const Divider(height: 1),
                      SizedBox(height: isDesktop ? 10 : 12.h),
                      Row(
                        children: [
                          // Date
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.grey,
                          ),
                          SizedBox(width: isDesktop ? 6 : 6.w),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: TextStyles.customStyle(
                                fontSize: 10,
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Remaining Balance info
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 8 : 8.w,
                              vertical: isDesktop ? 4 : 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              "${AppStrings.remaining.tr()}: ${payment.remainingAmount.toSmartAmount()}",
                              style: TextStyles.customStyle(
                                fontSize: 9,
                                color: AppColors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.full:
        return AppStrings.paidFull.tr();
      case PaymentType.partial:
        return AppStrings.partialPayment.tr();
      case PaymentType.settlement:
        return AppStrings.settlement.tr();
      default:
        return AppStrings.paymentReceived.tr();
    }
  }

  String _getMonthName(int month, BuildContext context) {
    final date = DateTime(2024, month);
    return DateFormat.MMMM(
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }
}

class _TransactionCardSkeleton extends StatelessWidget {
  const _TransactionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return ShimmerLoading(
      child: Container(
        margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12.h),
        padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerPlaceholder(width: 120, height: 16),
                      SizedBox(height: 6),
                      ShimmerPlaceholder(width: 80, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerPlaceholder(width: 70, height: 18),
                      SizedBox(height: 4),
                      ShimmerPlaceholder(width: 50, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 10 : 12.h),
            const Divider(height: 1),
            SizedBox(height: isDesktop ? 10 : 12.h),
            Row(
              children: [
                const ShimmerPlaceholder(
                  width: 14,
                  height: 14,
                  shape: BoxShape.circle,
                ),
                SizedBox(width: isDesktop ? 6 : 6.w),
                const ShimmerPlaceholder(width: 100, height: 10),
                const Spacer(),
                const ShimmerPlaceholder(width: 80, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
