import 'package:equatable/equatable.dart';

class ReconciliationDashboard extends Equatable {
  final int totalInternalOrders;
  final int totalShippingOrders;
  final int totalReconciledRecords;

  // Match Counts
  final int matchedOrdersCount;
  final int missingFromShippingCount;
  final int shippingReportOnlyCount;
  final int dataConflictsCount;
  final int duplicateOrdersCount;

  // Shipping Status Counts
  final int deliveredCount;
  final int returnedCount;
  final int outForDeliveryCount;
  final int shippedCount;
  final int notShippedCount;

  // Collection Status Counts
  final int fullyCollectedCount;
  final int partiallyCollectedCount;
  final int notCollectedCount;
  final int overCollectedCount;

  // Return Destination Counts
  final int returnedToStoreCount;
  final int returnedToShippingCompanyCount;
  final int returnDestinationUnknownCount;

  // Financial Summaries
  final double totalRequiredAmount;
  final double totalCollectedAmount;
  final double totalRemainingAmount;

  const ReconciliationDashboard({
    required this.totalInternalOrders,
    required this.totalShippingOrders,
    required this.totalReconciledRecords,
    required this.matchedOrdersCount,
    required this.missingFromShippingCount,
    required this.shippingReportOnlyCount,
    required this.dataConflictsCount,
    required this.duplicateOrdersCount,
    required this.deliveredCount,
    required this.returnedCount,
    required this.outForDeliveryCount,
    required this.shippedCount,
    required this.notShippedCount,
    required this.fullyCollectedCount,
    required this.partiallyCollectedCount,
    required this.notCollectedCount,
    required this.overCollectedCount,
    required this.returnedToStoreCount,
    required this.returnedToShippingCompanyCount,
    required this.returnDestinationUnknownCount,
    required this.totalRequiredAmount,
    required this.totalCollectedAmount,
    required this.totalRemainingAmount,
  });

  const ReconciliationDashboard.empty()
      : totalInternalOrders = 0,
        totalShippingOrders = 0,
        totalReconciledRecords = 0,
        matchedOrdersCount = 0,
        missingFromShippingCount = 0,
        shippingReportOnlyCount = 0,
        dataConflictsCount = 0,
        duplicateOrdersCount = 0,
        deliveredCount = 0,
        returnedCount = 0,
        outForDeliveryCount = 0,
        shippedCount = 0,
        notShippedCount = 0,
        fullyCollectedCount = 0,
        partiallyCollectedCount = 0,
        notCollectedCount = 0,
        overCollectedCount = 0,
        returnedToStoreCount = 0,
        returnedToShippingCompanyCount = 0,
        returnDestinationUnknownCount = 0,
        totalRequiredAmount = 0.0,
        totalCollectedAmount = 0.0,
        totalRemainingAmount = 0.0;

  @override
  List<Object?> get props => [
        totalInternalOrders,
        totalShippingOrders,
        totalReconciledRecords,
        matchedOrdersCount,
        missingFromShippingCount,
        shippingReportOnlyCount,
        dataConflictsCount,
        duplicateOrdersCount,
        deliveredCount,
        returnedCount,
        outForDeliveryCount,
        shippedCount,
        notShippedCount,
        fullyCollectedCount,
        partiallyCollectedCount,
        notCollectedCount,
        overCollectedCount,
        returnedToStoreCount,
        returnedToShippingCompanyCount,
        returnDestinationUnknownCount,
        totalRequiredAmount,
        totalCollectedAmount,
        totalRemainingAmount,
      ];
}
