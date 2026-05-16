import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/features/debt/domain/entities/monthly_collected_amount.dart';
import 'package:tahsel/features/debt/domain/entities/payment_entity.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class MonthlyCollectedTransactionsScreen extends StatelessWidget {
  final MonthlyCollectedAmount monthlyData;

  const MonthlyCollectedTransactionsScreen({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final monthName = _getMonthName(monthlyData.month, context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        title: Text(
          "$monthName ${monthlyData.year}",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 0,
            vertical: 8.h,
          ),
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildSummaryHeader(isDesktop),
                ),
              ),
              if (isDesktop)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: monthlyData.payments.length,
                  itemBuilder: (context, index) {
                    final payment = monthlyData.payments[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 30)),
                      child: _buildTransactionCard(context, payment, isDesktop),
                    );
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: monthlyData.payments.length,
                  itemBuilder: (context, index) {
                    final payment = monthlyData.payments[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 30)),
                      child: _buildTransactionCard(context, payment, isDesktop),
                    );
                  },
                ),
            ],
          ),
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
        color: AppColors.primaryColor,
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
            "${monthlyData.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
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

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12.h),
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
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
                        fontSize: isDesktop ? 15 : 15,
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
                          fontSize: isDesktop ? 13 : 13,
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
                          fontSize: isDesktop ? 16 : 16,
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
              const Icon(Icons.access_time, size: 14, color: AppColors.grey),
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
