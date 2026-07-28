import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_purchase_entity.dart';

class PurchaseCardItem extends StatefulWidget {
  final InventoryPurchaseEntity purchase;
  final VoidCallback onSharePdf;
  final VoidCallback onDownloadPdf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PurchaseCardItem({
    super.key,
    required this.purchase,
    required this.onSharePdf,
    required this.onDownloadPdf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PurchaseCardItem> createState() => _PurchaseCardItemState();
}

class _PurchaseCardItemState extends State<PurchaseCardItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final dateStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
    ).format(widget.purchase.createdAt);

    final itemsToDisplay = (_isExpanded || widget.purchase.items.length <= 2)
        ? widget.purchase.items
        : widget.purchase.items.take(2).toList();

    final hasMoreItems = widget.purchase.items.length > 2;

    final method = widget.purchase.paymentMethod;
    final Color methodColor = method == 'debt'
        ? AppColors.warning
        : (method == 'card' ? AppColors.primaryColor : AppColors.success);
    final String methodText = method == 'debt'
        ? AppStrings.paymentDebt.tr()
        : (method == 'card'
              ? AppStrings.paymentCard.tr()
              : AppStrings.paymentCash.tr());
    final IconData methodIcon = method == 'debt'
        ? Icons.assignment_outlined
        : (method == 'card'
              ? Icons.credit_card_rounded
              : Icons.payments_rounded);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.inventoryPurchasePurple.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.inventoryPurchasePurple.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Text(
                  '#${widget.purchase.id.replaceAll('pur_', '')}',
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inventoryPurchasePurple,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(methodIcon, color: methodColor, size: 12),
                    SizedBox(width: 4.w),
                    Text(
                      methodText,
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: methodColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.inventoryPurchasePurple
                          .withValues(alpha: 0.12),
                      radius: isDesktop ? 18 : 18.r,
                      child: Icon(
                        Icons.receipt_rounded,
                        color: AppColors.inventoryPurchasePurple,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 8 : 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isDesktop ? 6 : 6.h),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${AppStrings.supplier.tr()}: ${widget.purchase.supplierName}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.customStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blackReal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 4 : 4.h),
                          Text(
                            dateStr,
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: AppColors.sandText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              Row(
                children: [
                  Text(
                    '${widget.purchase.totalAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                    style: TextStyles.customStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.blackLight,
                      size: 20,
                    ),
                    onSelected: (val) {
                      if (val == 'share') {
                        widget.onSharePdf();
                      } else if (val == 'download') {
                        widget.onDownloadPdf();
                      } else if (val == 'edit') {
                        widget.onEdit();
                      } else if (val == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (!Platform.isWindows)
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.inventoryPurchasePurple,
                                size: 18,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                AppStrings.invoiceSharePdf.tr(),
                                style: TextStyles.customStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              AppStrings.savePdfToDevice.tr(),
                              style: TextStyles.customStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              AppStrings.edit.tr(),
                              style: TextStyles.customStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              AppStrings.confirmDelete.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 10 : 10.h),
          Divider(color: AppColors.disabledColor.withValues(alpha: 0.1)),
          Column(
            children: [
              ...itemsToDisplay.map((item) => _buildItemRow(item, isDesktop)),
              if (hasMoreItems) ...[
                SizedBox(height: isDesktop ? 6 : 6.h),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 10 : 10.w,
                      vertical: isDesktop ? 6 : 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inventoryPurchasePurple.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded
                              ? AppStrings.showLess.tr()
                              : '${AppStrings.showMore.tr()} (+${widget.purchase.items.length - 2})',
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inventoryPurchasePurple,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.inventoryPurchasePurple,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(InventoryPurchaseItemEntity item, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 10.w,
        vertical: isDesktop ? 6 : 6.h,
      ),
      margin: EdgeInsets.symmetric(vertical: isDesktop ? 3 : 3.h),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 6 : 6.w,
            height: isDesktop ? 6 : 6.h,
            decoration: BoxDecoration(
              color: AppColors.inventoryPurchasePurple,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isDesktop ? 8 : 8.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackReal,
                ),
              ),
              SizedBox(height: isDesktop ? 1 : 1.h),
              Row(
                children: [
                  Text(
                    '${item.quantity.toSmartAmount()} ${AppStrings.unit.tr()} × ${item.purchasePrice.toSmartAmount()}',
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.sandText,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 8 : 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 6 : 6.w,
                      vertical: isDesktop ? 2 : 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '${item.subtotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
