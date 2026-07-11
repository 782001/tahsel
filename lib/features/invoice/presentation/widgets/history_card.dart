import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_history_entity.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_history_timeline.dart';
import 'package:tahsel/features/invoice/presentation/widgets/metadata_row.dart';
import 'package:tahsel/features/invoice/presentation/widgets/value_change_row.dart';

class HistoryCard extends StatelessWidget {
  final InvoiceHistoryEntity entry;
  const HistoryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(entry.changeType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),

          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.title,
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(entry.timestamp),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.disabledColor,
                      ),
                    ),
                  ],
                ),

                // Field label (e.g. product name)
                if (entry.fieldLabel?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.fieldLabel!,
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],

                // Old → New values
                if (entry.oldValue != null || entry.newValue != null) ...[
                  const SizedBox(height: 6),
                  ValueChangeRow(
                    changeType: entry.changeType,
                    oldValue: entry.oldValue,
                    newValue: entry.newValue,
                  ),
                ],

                // Metadata rows (quantity, price, subtotal for added/removed items)
                if (entry.metadata.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  MetadataRow(metadata: entry.metadata),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  CardConfig _getConfig(InvoiceHistoryChangeType type) {
    switch (type) {
      case InvoiceHistoryChangeType.itemAdded:
        return CardConfig(
          icon: Icons.add_circle_outline_rounded,
          color: AppColors.success,
          title: AppStrings.historyItemAdded.tr(),
        );
      case InvoiceHistoryChangeType.itemRemoved:
        return CardConfig(
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.error,
          title: AppStrings.historyItemRemoved.tr(),
        );
      case InvoiceHistoryChangeType.quantityUpdated:
        return CardConfig(
          icon: Icons.format_list_numbered_rounded,
          color: AppColors.warning,
          title: AppStrings.historyQtyUpdated.tr(),
        );
      case InvoiceHistoryChangeType.priceUpdated:
        return CardConfig(
          icon: Icons.price_change_outlined,
          color: AppColors.info,
          title: AppStrings.historyPriceUpdated.tr(),
        );
      case InvoiceHistoryChangeType.customerUpdated:
        return CardConfig(
          icon: Icons.person_outline_rounded,
          color: AppColors.primaryColor,
          title: AppStrings.historyCustomerUpdated.tr(),
        );
      case InvoiceHistoryChangeType.notesUpdated:
        return CardConfig(
          icon: Icons.notes_rounded,
          color: AppColors.blackLight,
          title: AppStrings.historyNotesUpdated.tr(),
        );
      case InvoiceHistoryChangeType.discountUpdated:
        return CardConfig(
          icon: Icons.discount_outlined,
          color: AppColors.warning,
          title: AppStrings.historyDiscountUpdated.tr(),
        );
      case InvoiceHistoryChangeType.totalUpdated:
        return CardConfig(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primaryColor,
          title: AppStrings.historyTotalUpdated.tr(),
        );
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
