import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_operation.dart';
import 'package:tahsel/features/customer/presentation/utils/customer_operation_display_helper.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class CustomerOperationTile extends StatelessWidget {
  final CustomerOperation operation;

  const CustomerOperationTile({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final currency = AppStrings.currencyEgp.tr();

    final isQuotation =
        operation.type == CustomerOperationType.quotation ||
        operation.isQuotation;
    final isSettlement = operation.isSettlement;
    final isPayment = operation.type == CustomerOperationType.payment;
    final prefix = isQuotation ? "" : (isPayment ? "-" : "+");
    final title = operation.localizedTitle;

    final invoiceCode = isSettlement ? null : operation.resolvedInvoiceId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context),
        child: Container(
          margin: isDesktop
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blackLight.withAlpha(25),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    if (invoiceCode != null && invoiceCode.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _buildCopyBadge(context, invoiceCode),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      intl.DateFormat(
                        'yyyy/MM/dd hh:mm a',
                      ).format(operation.date),
                      style: TextStyles.customStyle(
                        color: AppColors.blackLight.withAlpha(150),
                        fontSize: 10.5,
                      ),
                    ),
                    // if (operation.details != null &&
                    //     operation.details!.trim().isNotEmpty) ...[
                    //   const SizedBox(height: 2),
                    //   Text(
                    //     operation.details!,
                    //     maxLines: 1,
                    //     overflow: TextOverflow.ellipsis,
                    //     style: TextStyles.customStyle(
                    //       color: AppColors.blackLight.withAlpha(190),
                    //       fontSize: 11,
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$prefix${operation.amount.abs().toSmartAmount()} $currency',
                    style: TextStyles.customStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (operation.runningBalance > 0
                                  ? AppColors.error
                                  : AppColors.success)
                              .withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${AppStrings.runningBalance.tr()}: ${operation.runningBalance.toSmartAmount()} $currency',
                      style: TextStyles.customStyle(
                        color: operation.runningBalance > 0
                            ? AppColors.error
                            : AppColors.success,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyBadge(BuildContext context, String ref) {
    return Tooltip(
      message: AppStrings.copyInvoiceCode.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Clipboard.setData(ClipboardData(text: ref));
            showSuccessToast(
              AppStrings.invoiceCodeCopied.tr().replaceAll('{code}', ref),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primaryColor.withAlpha(40),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    ref,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.customStyle(
                      color: AppColors.primaryColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy_rounded,
                  size: 11,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final color = _getColor();
    final icon = _getIcon();
    final currency = AppStrings.currencyEgp.tr();
    final isQuotation =
        operation.type == CustomerOperationType.quotation ||
        operation.isQuotation;
    final isSettlement = operation.isSettlement;
    final isPayment = operation.type == CustomerOperationType.payment;
    final prefix = isQuotation ? "" : (isPayment ? "-" : "+");
    final title = operation.localizedTitle;
    final invoiceCode = isSettlement ? null : operation.resolvedInvoiceId;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.blackLight.withAlpha(50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.transactionDetails.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyles.customStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.blackLight),
                splashRadius: 20,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildDetailRow(
            AppStrings.amount.tr(),
            '$prefix${operation.amount.abs().toSmartAmount()} $currency',
            valueColor: color,
            isBold: true,
          ),
          _buildDetailRow(
            AppStrings.runningBalance.tr(),
            '${operation.runningBalance.toSmartAmount()} $currency',
            valueColor: operation.runningBalance > 0
                ? AppColors.error
                : AppColors.success,
            isBold: true,
          ),
          _buildDetailRow(
            AppStrings.dateLabel.tr(),
            intl.DateFormat('yyyy/MM/dd  hh:mm a').format(operation.date),
          ),
          if (invoiceCode != null && invoiceCode.isNotEmpty)
            _buildReferenceDetailRow(context, invoiceCode),
          if (operation.details != null && operation.details!.trim().isNotEmpty)
            _buildDetailRow(AppStrings.details.tr(), operation.details!),
          if (operation.notes != null && operation.notes!.trim().isNotEmpty)
            _buildDetailRow(AppStrings.notes.tr(), operation.notes!),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => content,
      );
    }
  }

  Widget _buildReferenceDetailRow(BuildContext context, String ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.invoiceCode.tr(),
            style: TextStyles.customStyle(
              color: AppColors.blackLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Tooltip(
              message: AppStrings.copyInvoiceCode.tr(),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ref));
                  showSuccessToast(
                    AppStrings.invoiceCodeCopied.tr().replaceAll('{code}', ref),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryColor.withAlpha(40),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          ref,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            color: AppColors.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.customStyle(
              color: AppColors.blackLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyles.customStyle(
                color: valueColor ?? AppColors.black,
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (operation.isSettlement) {
      return AppColors.creditAmberEnd;
    }
    switch (operation.type) {
      case CustomerOperationType.purchase:
        return AppColors.primaryColor;
      case CustomerOperationType.debt:
        return AppColors.error;
      case CustomerOperationType.payment:
        return AppColors.success;
      case CustomerOperationType.quotation:
        return AppColors.primaryColor;
    }
  }

  IconData _getIcon() {
    if (operation.type == CustomerOperationType.quotation ||
        operation.isQuotation) {
      return Icons.request_quote_outlined;
    }
    if (operation.isSettlement) {
      return Icons.published_with_changes_rounded;
    }
    switch (operation.type) {
      case CustomerOperationType.purchase:
        return Icons.shopping_bag_outlined;
      case CustomerOperationType.debt:
        return Icons.money_off_csred_outlined;
      case CustomerOperationType.payment:
        return Icons.check_circle_outline_rounded;
      case CustomerOperationType.quotation:
        return Icons.request_quote_outlined;
    }
  }
}
