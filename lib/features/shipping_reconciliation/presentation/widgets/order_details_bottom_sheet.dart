import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/order_reconciliation_item.dart';

import 'comparison_column_widget.dart';
import 'discrepancy_warnings_card.dart';
import 'financial_reconciliation_section.dart';
import 'order_details_header.dart';

class OrderDetailsBottomSheet extends StatelessWidget {
  final OrderReconciliationItem item;

  const OrderDetailsBottomSheet({super.key, required this.item});

  static void show(BuildContext context, OrderReconciliationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderDetailsBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final sheetContent = Container(
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: isDesktop
            ? BorderRadius.circular(20.r)
            : BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderDetailsHeader(item: item),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discrepancy Warnings
                  DiscrepancyWarningsCard(
                    discrepancyNotes: item.discrepancyNotes,
                  ),
                  if (item.discrepancyNotes.isNotEmpty)
                    SizedBox(height: isDesktop ? 16 : 16.h),

                  // Financial Reconciliation Card
                  FinancialReconciliationSection(item: item),

                  SizedBox(height: isDesktop ? 16 : 16.h),

                  // Side-by-Side Comparison Title
                  Text(
                    AppStrings.comparisonSectionTitle.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 14 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackReal,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 10 : 10.h),

                  // Side-by-Side Comparison Columns
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Internal Data Column
                      Expanded(
                        child: ComparisonColumnWidget(
                          title: AppStrings.internalDbTitle.tr(),
                          color: AppColors.primaryColor,
                          dataMap: {
                            AppStrings.conceptOrderNumber.tr():
                                item.internalOrderNumber ?? '---',
                            AppStrings.customerLabel.tr():
                                item.internalCustomerName ?? '---',
                            AppStrings.phoneLabel.tr():
                                item.internalPhone ?? '---',
                            AppStrings.conceptProduct.tr():
                                item.internalProduct ?? '---',
                            AppStrings.conceptRequiredAmount
                                .tr(): item.internalRequiredAmount != null
                                ? '${item.internalRequiredAmount!.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                                : '---',
                            AppStrings.conceptGovernorate.tr():
                                item.internalGovernorate ?? '---',
                            AppStrings.conceptAddress.tr():
                                item.internalAddress ?? '---',
                            AppStrings.conceptDate.tr():
                                item.internalDate ?? '---',
                          },
                        ),
                      ),
                      SizedBox(width: isDesktop ? 10 : 10.w),

                      // Shipping Data Column
                      Expanded(
                        child: ComparisonColumnWidget(
                          title: AppStrings.shippingReportTitle.tr(),
                          color: AppColors.shippingDelivered,
                          dataMap: {
                            AppStrings.conceptOrderNumber.tr():
                                item.shippingOrderNumber ?? '---',
                            AppStrings.customerLabel.tr():
                                item.shippingCustomerName ?? '---',
                            AppStrings.phoneLabel.tr():
                                item.shippingPhone ?? '---',
                            AppStrings.conceptProduct.tr():
                                item.shippingProduct ?? '---',
                            AppStrings.conceptExpectedAmount
                                .tr(): item.shippingExpectedAmount != null
                                ? '${item.shippingExpectedAmount!.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                                : '---',
                            AppStrings.conceptCollectedAmount
                                .tr(): item.shippingCollectedAmount != null
                                ? '${item.shippingCollectedAmount!.toSmartAmount()} ${AppStrings.currencyEgp.tr()}'
                                : '---',
                            AppStrings.shippingStatusRawText.tr():
                                item.shippingStatusText ?? '---',
                            AppStrings.shippingReturnNotes.tr():
                                item.shippingReturnStatusText ?? '---',
                          },
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
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 850,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 24.w,
              vertical: isDesktop ? 24 : 24.h,
            ),
            child: sheetContent,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: sheetContent,
    );
  }
}
