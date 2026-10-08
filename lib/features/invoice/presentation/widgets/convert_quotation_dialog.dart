import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';
import 'package:tahsel/shared/widgets/quick_due_date_selector.dart';

class ConvertQuotationResult {
  final bool confirmed;
  final DateTime? dueDate;

  const ConvertQuotationResult({required this.confirmed, this.dueDate});
}

class ConvertQuotationDialog extends StatefulWidget {
  final InvoiceEntity quotation;

  const ConvertQuotationDialog({super.key, required this.quotation});

  static Future<ConvertQuotationResult?> show(
    BuildContext context,
    InvoiceEntity quotation,
  ) {
    return showDialog<ConvertQuotationResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConvertQuotationDialog(quotation: quotation),
    );
  }

  @override
  State<ConvertQuotationDialog> createState() => _ConvertQuotationDialogState();
}

class _ConvertQuotationDialogState extends State<ConvertQuotationDialog> {
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.quotation.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final double radius = isDesktop ? 20 : 20.r;
    final double paddingVal = isDesktop ? 20 : 20.w;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      backgroundColor: AppColors.surface,
      contentPadding: EdgeInsets.all(paddingVal),
      titlePadding: EdgeInsets.fromLTRB(paddingVal, paddingVal, paddingVal, 0),
      actionsPadding: EdgeInsets.fromLTRB(
        paddingVal,
        0,
        paddingVal,
        paddingVal,
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 10 : 10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.published_with_changes_rounded,
              color: AppColors.primaryColor,
              size: isDesktop ? 24 : 24.sp,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 12.w),
          Expanded(
            child: Text(
              AppStrings.convertQuotationConfirmTitle.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 16 : 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: isDesktop ? 380 : 280,
          maxWidth: isDesktop ? 480 : double.infinity,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 12 : 12.h),

              // Summary Info Card
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 14.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.customerNameLabel.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 12.sp,
                            color: AppColors.subTitleColor,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 8 : 8.w),
                        Flexible(
                          child: Text(
                            widget.quotation.customerName?.isNotEmpty == true
                                ? widget.quotation.customerName!
                                : AppStrings.walkingCustomer.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.quotationTotal.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 12.sp,
                            color: AppColors.subTitleColor,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 8.w,
                            vertical: isDesktop ? 4 : 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 8 : 8.r,
                            ),
                          ),
                          child: Text(
                            '${widget.quotation.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.itemsCount.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 12.sp,
                            color: AppColors.subTitleColor,
                          ),
                        ),
                        Text(
                          '${widget.quotation.items.length} ${AppStrings.invoiceItem.tr()}',
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: isDesktop ? 16 : 16.h),

              // Due Date Selector
              QuickDueDateSelector(
                selectedDate: _dueDate,
                onDateChanged: (val) {
                  setState(() => _dueDate = val);
                },
                showLabel: true,
              ),

              SizedBox(height: isDesktop ? 16 : 16.h),

              // Notice Banner
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 12.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: isDesktop ? 18 : 18.sp,
                    ),
                    SizedBox(width: isDesktop ? 8 : 8.w),
                    Expanded(
                      child: Text(
                        AppStrings.convertQuotationNotice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 11 : 11.sp,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Center(
          child: Column(
            children: [
              QuickActionButton(
                label: AppStrings.confirmConversion.tr(),
                icon: Icons.check_rounded,
                onPressed: () {
                  Navigator.of(context).pop(
                    ConvertQuotationResult(confirmed: true, dueDate: _dueDate),
                  );
                },
              ),

              SizedBox(height: isDesktop ? 10 : 10.h),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const ConvertQuotationResult(confirmed: false)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 16.w,
                    vertical: isDesktop ? 12 : 12.h,
                  ),
                ),
                child: Text(
                  AppStrings.cancel.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13 : 13.sp,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
