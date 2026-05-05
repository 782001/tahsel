import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../domain/entities/monthly_collected_amount.dart';
import '../../domain/entities/payment_entity.dart';

class MonthlyCollectedTransactionsScreen extends StatelessWidget {
  final MonthlyCollectedAmount monthlyData;

  const MonthlyCollectedTransactionsScreen({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: monthlyData.payments.length,
              itemBuilder: (context, index) {
                final payment = monthlyData.payments[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  child: _buildTransactionCard(context, payment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
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
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "${monthlyData.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
            style: TextStyles.customStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, PaymentEntity payment) {
    final dateStr = payment.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
            Localizations.localeOf(context).languageCode,
          ).format(payment.createdAt!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Customer Name & Activity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Text(
                        //   "${AppStrings.customerName.tr()}: ",
                        //   style: TextStyles.customStyle(
                        //     fontSize: 12,
                        //     color: AppColors.grey,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                        Expanded(
                          child: Text(
                            payment.relatedTo ?? AppStrings.unknown.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (payment.activityName != null &&
                        payment.activityName!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Text(
                            "●  ",
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              payment.activityName!,
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+${payment.amountPaid.toSmartAmount()} ${AppStrings.currencyEgp.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _getPaymentTypeLabel(payment.type),
                    style: TextStyles.customStyle(
                      fontSize: 11,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              // Date
              Icon(Icons.access_time, size: 14, color: AppColors.grey),
              SizedBox(width: 6.w),
              Text(
                dateStr,
                style: TextStyles.customStyle(
                  fontSize: 11,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              // Remaining Balance info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  "${AppStrings.remaining.tr()}: ${payment.remainingAmount.toSmartAmount()}",
                  style: TextStyles.customStyle(
                    fontSize: 10,
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
