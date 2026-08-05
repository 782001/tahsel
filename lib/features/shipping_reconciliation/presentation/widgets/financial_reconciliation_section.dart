import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/order_reconciliation_item.dart';

import 'reconciliation_data_row.dart';
import 'reconciliation_section_card.dart';

class FinancialReconciliationSection extends StatelessWidget {
  final OrderReconciliationItem item;

  const FinancialReconciliationSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ReconciliationSectionCard(
      title: AppStrings.financialReconciliationSection.tr(),
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        children: [
          ReconciliationDataRow(
            label: AppStrings.shippingStatusLabel.tr(),
            value: _getShippingStatusText(item.shippingStatus),
          ),
          ReconciliationDataRow(
            label: AppStrings.collectionStatusLabel.tr(),
            value: _getCollectionStatusText(item.collectionStatus),
          ),
          ReconciliationDataRow(
            label: AppStrings.returnDestinationLabel.tr(),
            value: _getReturnDestinationText(item.returnDestination),
          ),
          Divider(
            height: isDesktop ? 16 : 16.h,
            color: AppColors.sandText.withValues(alpha: 0.2),
          ),
          ReconciliationDataRow(
            label: AppStrings.requiredAmountInternal.tr(),
            value: '${item.requiredAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          ),
          ReconciliationDataRow(
            label: AppStrings.collectedAmountShipping.tr(),
            value: '${item.collectedAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          ),
          ReconciliationDataRow(
            label: AppStrings.remainingDifferenceAmount.tr(),
            value: '${item.remainingAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
            isBold: true,
            valueColor: item.remainingAmount > 0
                ? AppColors.shippingReturned
                : AppColors.shippingDelivered,
          ),
        ],
      ),
    );
  }

  String _getShippingStatusText(ShippingStatusCategory status) {
    switch (status) {
      case ShippingStatusCategory.delivered:
        return AppStrings.deliveredFilter.tr();
      case ShippingStatusCategory.returned:
        return AppStrings.returnedFilter.tr();
      case ShippingStatusCategory.outForDelivery:
        return AppStrings.statusOutForDelivery.tr();
      case ShippingStatusCategory.shipped:
        return AppStrings.statusShipped.tr();
      case ShippingStatusCategory.failedDelivery:
        return AppStrings.statusFailedDelivery.tr();
      case ShippingStatusCategory.notShipped:
        return AppStrings.statusNotShipped.tr();
      case ShippingStatusCategory.unknown:
        return AppStrings.statusUnknown.tr();
    }
  }

  String _getCollectionStatusText(CollectionStatusCategory status) {
    switch (status) {
      case CollectionStatusCategory.fullyCollected:
        return AppStrings.fullyCollectedCount.tr();
      case CollectionStatusCategory.partiallyCollected:
        return AppStrings.partiallyCollectedCount.tr();
      case CollectionStatusCategory.notCollected:
        return AppStrings.notCollectedCount.tr();
      case CollectionStatusCategory.overCollected:
        return AppStrings.fullyCollectedCount.tr();
      case CollectionStatusCategory.amountMismatch:
        return AppStrings.matchStatusConflict.tr();
      case CollectionStatusCategory.unknown:
        return AppStrings.statusUnknown.tr();
    }
  }

  String _getReturnDestinationText(ReturnDestinationCategory destination) {
    switch (destination) {
      case ReturnDestinationCategory.returnedToStore:
        return AppStrings.returnDestInternalStore.tr();
      case ReturnDestinationCategory.returnedToShippingCompany:
        return AppStrings.returnDestShippingWarehouse.tr();
      case ReturnDestinationCategory.destinationUnknown:
        return AppStrings.unspecified.tr();
      case ReturnDestinationCategory.none:
        return AppStrings.returnDestNotReturned.tr();
    }
  }
}
