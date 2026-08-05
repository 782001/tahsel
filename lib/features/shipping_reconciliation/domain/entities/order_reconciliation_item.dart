import 'package:equatable/equatable.dart';

enum OrderMatchStatus {
  matched,
  missingFromShipping, // Exists in internal DB, not in shipping report
  shippingReportOnly,  // Exists in shipping report, not in internal DB
  conflict,            // Matching IDs but key fields conflict (e.g. phone)
  duplicate,           // Multiple rows with same order number
}

enum MatchConfidence {
  high,
  medium,
  low,
  none,
}

enum ShippingStatusCategory {
  delivered,
  returned,
  outForDelivery,
  shipped,
  failedDelivery,
  notShipped,
  unknown,
}

enum CollectionStatusCategory {
  fullyCollected,
  partiallyCollected,
  notCollected,
  overCollected,
  amountMismatch,
  unknown,
}

enum ReturnDestinationCategory {
  returnedToStore,
  returnedToShippingCompany,
  destinationUnknown,
  none,
}

class OrderReconciliationItem extends Equatable {
  final String id;
  final OrderMatchStatus matchStatus;
  final MatchConfidence confidenceLevel;
  final ShippingStatusCategory shippingStatus;
  final String shippingStatusRaw;
  final CollectionStatusCategory collectionStatus;
  final ReturnDestinationCategory returnDestination;
  final String returnDestinationRaw;

  // Internal Data
  final String? internalOrderNumber;
  final String? internalCustomerName;
  final String? internalPhone;
  final String? internalProduct;
  final double? internalRequiredAmount;
  final String? internalGovernorate;
  final String? internalAddress;
  final String? internalDate;
  final Map<String, String>? internalRawRow;

  // Shipping Company Data
  final String? shippingOrderNumber;
  final String? shippingCustomerName;
  final String? shippingPhone;
  final String? shippingProduct;
  final double? shippingExpectedAmount;
  final double? shippingCollectedAmount;
  final String? shippingStatusText;
  final String? shippingCollectionStatusText;
  final String? shippingReturnStatusText;
  final Map<String, String>? shippingRawRow;

  // Financial Summary
  final double requiredAmount;
  final double collectedAmount;
  final double remainingAmount;

  // Discrepancy details
  final List<String> discrepancyNotes;

  const OrderReconciliationItem({
    required this.id,
    required this.matchStatus,
    required this.confidenceLevel,
    required this.shippingStatus,
    required this.shippingStatusRaw,
    required this.collectionStatus,
    required this.returnDestination,
    required this.returnDestinationRaw,
    this.internalOrderNumber,
    this.internalCustomerName,
    this.internalPhone,
    this.internalProduct,
    this.internalRequiredAmount,
    this.internalGovernorate,
    this.internalAddress,
    this.internalDate,
    this.internalRawRow,
    this.shippingOrderNumber,
    this.shippingCustomerName,
    this.shippingPhone,
    this.shippingProduct,
    this.shippingExpectedAmount,
    this.shippingCollectedAmount,
    this.shippingStatusText,
    this.shippingCollectionStatusText,
    this.shippingReturnStatusText,
    this.shippingRawRow,
    required this.requiredAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.discrepancyNotes,
  });

  /// Display order number preference (Internal > Shipping)
  String get displayOrderNumber =>
      internalOrderNumber ?? shippingOrderNumber ?? '#N/A';

  /// Display customer name preference (Internal > Shipping)
  String get displayCustomerName =>
      internalCustomerName ?? shippingCustomerName ?? '---';

  /// Display phone preference (Internal > Shipping)
  String get displayPhone => internalPhone ?? shippingPhone ?? '---';

  /// Display product preference (Internal > Shipping)
  String get displayProduct => internalProduct ?? shippingProduct ?? '---';

  @override
  List<Object?> get props => [
        id,
        matchStatus,
        confidenceLevel,
        shippingStatus,
        shippingStatusRaw,
        collectionStatus,
        returnDestination,
        returnDestinationRaw,
        internalOrderNumber,
        internalCustomerName,
        internalPhone,
        internalProduct,
        internalRequiredAmount,
        internalGovernorate,
        internalAddress,
        internalDate,
        internalRawRow,
        shippingOrderNumber,
        shippingCustomerName,
        shippingPhone,
        shippingProduct,
        shippingExpectedAmount,
        shippingCollectedAmount,
        shippingStatusText,
        shippingCollectionStatusText,
        shippingReturnStatusText,
        shippingRawRow,
        requiredAmount,
        collectedAmount,
        remainingAmount,
        discrepancyNotes,
      ];
}
