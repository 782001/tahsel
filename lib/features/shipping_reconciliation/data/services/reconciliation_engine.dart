import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/column_concept.dart';
import '../../domain/entities/column_mapping_entity.dart';
import '../../domain/entities/order_reconciliation_item.dart';
import '../../domain/entities/reconciliation_dashboard.dart';
import '../../domain/repositories/shipping_reconciliation_repository.dart';
import 'text_normalization_service.dart';

class ReconciliationInputParams {
  final RawFileData internalFile;
  final FileColumnMappingEntity internalMapping;
  final RawFileData shippingFile;
  final FileColumnMappingEntity shippingMapping;

  ReconciliationInputParams({
    required this.internalFile,
    required this.internalMapping,
    required this.shippingFile,
    required this.shippingMapping,
  });
}

class InternalParsedOrder {
  final int rowIndex;
  final String rawOrderNumber;
  final String normOrderNumber;
  final String rawCustomerName;
  final String normCustomerName;
  final String rawPhone;
  final String normPhone;
  final String rawProduct;
  final double requiredAmount;
  final String governorate;
  final String address;
  final String date;
  final Map<String, String> rawRowMap;

  InternalParsedOrder({
    required this.rowIndex,
    required this.rawOrderNumber,
    required this.normOrderNumber,
    required this.rawCustomerName,
    required this.normCustomerName,
    required this.rawPhone,
    required this.normPhone,
    required this.rawProduct,
    required this.requiredAmount,
    required this.governorate,
    required this.address,
    required this.date,
    required this.rawRowMap,
  });
}

class ShippingParsedOrder {
  final int rowIndex;
  final String rawOrderNumber;
  final String normOrderNumber;
  final String rawCustomerName;
  final String normCustomerName;
  final String rawPhone;
  final String normPhone;
  final String rawProduct;
  final double expectedAmount;
  final double collectedAmount;
  final String rawStatus;
  final String rawCollectionStatus;
  final String rawReturnStatus;
  final Map<String, String> rawRowMap;

  ShippingParsedOrder({
    required this.rowIndex,
    required this.rawOrderNumber,
    required this.normOrderNumber,
    required this.rawCustomerName,
    required this.normCustomerName,
    required this.rawPhone,
    required this.normPhone,
    required this.rawProduct,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.rawStatus,
    required this.rawCollectionStatus,
    required this.rawReturnStatus,
    required this.rawRowMap,
  });
}

class ReconciliationEngine {
  ReconciliationEngine._();

  /// Runs the reconciliation process inside an Isolate via compute()
  static Future<ReconciliationResultData> reconcileInIsolate(
    ReconciliationInputParams params,
  ) async {
    return await compute(_processReconciliation, params);
  }

  static ReconciliationResultData _processReconciliation(
    ReconciliationInputParams params,
  ) {
    // 1. Extract mapped column indices for Internal File
    final intOrderIdx = params.internalMapping.getIndex(ColumnConcept.orderNumber);
    final intCustIdx = params.internalMapping.getIndex(ColumnConcept.customerName);
    final intPhoneIdx = params.internalMapping.getIndex(ColumnConcept.phone);
    final intProdIdx = params.internalMapping.getIndex(ColumnConcept.product);
    final intAmtIdx = params.internalMapping.getIndex(ColumnConcept.requiredAmount);
    final intGovIdx = params.internalMapping.getIndex(ColumnConcept.governorate);
    final intAddrIdx = params.internalMapping.getIndex(ColumnConcept.address);
    final intDateIdx = params.internalMapping.getIndex(ColumnConcept.date);

    // 2. Parse internal rows into normalized structures
    final List<InternalParsedOrder> internalOrders = [];
    final Map<String, List<InternalParsedOrder>> internalByOrderNum = {};
    final Map<String, List<InternalParsedOrder>> internalByPhone = {};
    final Map<String, List<InternalParsedOrder>> internalByCustName = {};

    for (int i = 0; i < params.internalFile.rows.length; i++) {
      final row = params.internalFile.rows[i];
      
      final rawOrderNo = (intOrderIdx != null && intOrderIdx < row.length) ? row[intOrderIdx]?.toString().trim() ?? '' : '';
      final rawCust = (intCustIdx != null && intCustIdx < row.length) ? row[intCustIdx]?.toString().trim() ?? '' : '';
      final rawPhone = (intPhoneIdx != null && intPhoneIdx < row.length) ? row[intPhoneIdx]?.toString().trim() ?? '' : '';
      final rawProd = (intProdIdx != null && intProdIdx < row.length) ? row[intProdIdx]?.toString().trim() ?? '' : '';
      final reqAmt = (intAmtIdx != null && intAmtIdx < row.length) ? TextNormalizationService.parseAmount(row[intAmtIdx]) : 0.0;
      final gov = (intGovIdx != null && intGovIdx < row.length) ? row[intGovIdx]?.toString().trim() ?? '' : '';
      final addr = (intAddrIdx != null && intAddrIdx < row.length) ? row[intAddrIdx]?.toString().trim() ?? '' : '';
      final dt = (intDateIdx != null && intDateIdx < row.length) ? row[intDateIdx]?.toString().trim() ?? '' : '';

      final rawRowMap = <String, String>{};
      for (int c = 0; c < params.internalFile.headers.length && c < row.length; c++) {
        final h = params.internalFile.headers[c];
        if (h.isNotEmpty) rawRowMap[h] = row[c]?.toString() ?? '';
      }

      final normOrderNo = TextNormalizationService.normalizeForMatching(rawOrderNo);
      final normCust = TextNormalizationService.normalizeForMatching(rawCust);
      final normPhone = TextNormalizationService.normalizePhone(rawPhone);

      final item = InternalParsedOrder(
        rowIndex: i,
        rawOrderNumber: rawOrderNo,
        normOrderNumber: normOrderNo,
        rawCustomerName: rawCust,
        normCustomerName: normCust,
        rawPhone: rawPhone,
        normPhone: normPhone,
        rawProduct: rawProd,
        requiredAmount: reqAmt,
        governorate: gov,
        address: addr,
        date: dt,
        rawRowMap: rawRowMap,
      );

      internalOrders.add(item);

      if (normOrderNo.isNotEmpty) {
        internalByOrderNum.putIfAbsent(normOrderNo, () => []).add(item);
      }
      if (normPhone.isNotEmpty) {
        internalByPhone.putIfAbsent(normPhone, () => []).add(item);
      }
      if (normCust.isNotEmpty && normCust.length >= 3) {
        internalByCustName.putIfAbsent(normCust, () => []).add(item);
      }
    }

    // 3. Extract mapped column indices for Shipping File
    final shpOrderIdx = params.shippingMapping.getIndex(ColumnConcept.orderNumber);
    final shpCustIdx = params.shippingMapping.getIndex(ColumnConcept.customerName);
    final shpPhoneIdx = params.shippingMapping.getIndex(ColumnConcept.phone);
    final shpProdIdx = params.shippingMapping.getIndex(ColumnConcept.product);
    final shpExpAmtIdx = params.shippingMapping.getIndex(ColumnConcept.expectedAmount);
    final shpColAmtIdx = params.shippingMapping.getIndex(ColumnConcept.collectedAmount);
    final shpStatusIdx = params.shippingMapping.getIndex(ColumnConcept.shippingStatus);
    final shpColStatusIdx = params.shippingMapping.getIndex(ColumnConcept.collectionStatus);
    final shpRetStatusIdx = params.shippingMapping.getIndex(ColumnConcept.returnStatus);

    final List<ShippingParsedOrder> shippingOrders = [];
    final Map<String, List<ShippingParsedOrder>> shippingByOrderNum = {};

    for (int i = 0; i < params.shippingFile.rows.length; i++) {
      final row = params.shippingFile.rows[i];

      final rawOrderNo = (shpOrderIdx != null && shpOrderIdx < row.length) ? row[shpOrderIdx]?.toString().trim() ?? '' : '';
      final rawCust = (shpCustIdx != null && shpCustIdx < row.length) ? row[shpCustIdx]?.toString().trim() ?? '' : '';
      final rawPhone = (shpPhoneIdx != null && shpPhoneIdx < row.length) ? row[shpPhoneIdx]?.toString().trim() ?? '' : '';
      final rawProd = (shpProdIdx != null && shpProdIdx < row.length) ? row[shpProdIdx]?.toString().trim() ?? '' : '';
      final expAmt = (shpExpAmtIdx != null && shpExpAmtIdx < row.length) ? TextNormalizationService.parseAmount(row[shpExpAmtIdx]) : 0.0;
      final colAmt = (shpColAmtIdx != null && shpColAmtIdx < row.length) ? TextNormalizationService.parseAmount(row[shpColAmtIdx]) : 0.0;
      final rawStatus = (shpStatusIdx != null && shpStatusIdx < row.length) ? row[shpStatusIdx]?.toString().trim() ?? '' : '';
      final rawColStatus = (shpColStatusIdx != null && shpColStatusIdx < row.length) ? row[shpColStatusIdx]?.toString().trim() ?? '' : '';
      final rawRetStatus = (shpRetStatusIdx != null && shpRetStatusIdx < row.length) ? row[shpRetStatusIdx]?.toString().trim() ?? '' : '';

      final rawRowMap = <String, String>{};
      for (int c = 0; c < params.shippingFile.headers.length && c < row.length; c++) {
        final h = params.shippingFile.headers[c];
        if (h.isNotEmpty) rawRowMap[h] = row[c]?.toString() ?? '';
      }

      final normOrderNo = TextNormalizationService.normalizeForMatching(rawOrderNo);
      final normCust = TextNormalizationService.normalizeForMatching(rawCust);
      final normPhone = TextNormalizationService.normalizePhone(rawPhone);

      final item = ShippingParsedOrder(
        rowIndex: i,
        rawOrderNumber: rawOrderNo,
        normOrderNumber: normOrderNo,
        rawCustomerName: rawCust,
        normCustomerName: normCust,
        rawPhone: rawPhone,
        normPhone: normPhone,
        rawProduct: rawProd,
        expectedAmount: expAmt,
        collectedAmount: colAmt,
        rawStatus: rawStatus,
        rawCollectionStatus: rawColStatus,
        rawReturnStatus: rawRetStatus,
        rawRowMap: rawRowMap,
      );

      shippingOrders.add(item);
      if (normOrderNo.isNotEmpty) {
        shippingByOrderNum.putIfAbsent(normOrderNo, () => []).add(item);
      }
    }

    // 4. Perform Index Matching & Reconciliation
    final List<OrderReconciliationItem> resultItems = [];
    final Set<int> matchedInternalRowIndices = {};
    final Set<int> matchedShippingRowIndices = {};

    int matchedCount = 0;
    int missingFromShippingCount = 0;
    int shippingReportOnlyCount = 0;
    int dataConflictsCount = 0;
    int duplicateOrdersCount = 0;

    int deliveredCount = 0;
    int returnedCount = 0;
    int outForDeliveryCount = 0;
    int shippedCount = 0;
    int notShippedCount = 0;

    int fullyCollectedCount = 0;
    int partiallyCollectedCount = 0;
    int notCollectedCount = 0;
    int overCollectedCount = 0;

    int returnedToStoreCount = 0;
    int returnedToShippingCompanyCount = 0;
    int returnDestinationUnknownCount = 0;

    double totalRequiredAmt = 0.0;
    double totalCollectedAmt = 0.0;
    double totalRemainingAmt = 0.0;

    // A. Match Shipping Orders against Internal Orders
    for (final shpOrder in shippingOrders) {
      InternalParsedOrder? matchedInternal;
      OrderMatchStatus matchStatus = OrderMatchStatus.matched;
      MatchConfidence confidence = MatchConfidence.high;
      final List<String> notes = [];

      // Check duplicates in shipping file
      final sameShpOrders = shpOrder.normOrderNumber.isNotEmpty ? shippingByOrderNum[shpOrder.normOrderNumber] : null;
      bool isShippingDuplicate = sameShpOrders != null && sameShpOrders.length > 1;

      if (shpOrder.normOrderNumber.isNotEmpty && internalByOrderNum.containsKey(shpOrder.normOrderNumber)) {
        final candidateInternals = internalByOrderNum[shpOrder.normOrderNumber]!;
        matchedInternal = candidateInternals.first;
        matchedInternalRowIndices.add(matchedInternal.rowIndex);
        matchedShippingRowIndices.add(shpOrder.rowIndex);

        if (candidateInternals.length > 1 || isShippingDuplicate) {
          matchStatus = OrderMatchStatus.duplicate;
          duplicateOrdersCount++;
          notes.add('تم العثور على تكرار في رقم الطلب (${shpOrder.rawOrderNumber}).');
        }

        // Verify Phone match
        if (shpOrder.normPhone.isNotEmpty && matchedInternal.normPhone.isNotEmpty && shpOrder.normPhone != matchedInternal.normPhone) {
          matchStatus = OrderMatchStatus.conflict;
          confidence = MatchConfidence.medium;
          dataConflictsCount++;
          notes.add('اختلاف في رقم الهاتف: الداخلي (${matchedInternal.rawPhone}) vs الشحن (${shpOrder.rawPhone}).');
        }

        // Verify Amount discrepancy
        if (matchedInternal.requiredAmount > 0 && shpOrder.expectedAmount > 0 && (matchedInternal.requiredAmount - shpOrder.expectedAmount).abs() > 0.01) {
          notes.add('اختلاف في المبلغ المطلوبة: الداخلي (${matchedInternal.requiredAmount}) vs تقرير الشحن (${shpOrder.expectedAmount}).');
        }

      } else if (shpOrder.normPhone.isNotEmpty && internalByPhone.containsKey(shpOrder.normPhone)) {
        // Phone match fallback
        final candidateInternals = internalByPhone[shpOrder.normPhone]!;
        matchedInternal = candidateInternals.firstWhere(
          (cand) => !matchedInternalRowIndices.contains(cand.rowIndex),
          orElse: () => candidateInternals.first,
        );
        matchedInternalRowIndices.add(matchedInternal.rowIndex);
        matchedShippingRowIndices.add(shpOrder.rowIndex);

        matchStatus = OrderMatchStatus.matched;
        confidence = MatchConfidence.medium;

        if (shpOrder.normOrderNumber.isNotEmpty && matchedInternal.normOrderNumber.isNotEmpty && shpOrder.normOrderNumber != matchedInternal.normOrderNumber) {
          matchStatus = OrderMatchStatus.conflict;
          confidence = MatchConfidence.low;
          dataConflictsCount++;
          notes.add('تطابق برقم الهاتف ولكن كود الطلب مختلف: (${matchedInternal.rawOrderNumber} vs ${shpOrder.rawOrderNumber}).');
        }
      } else if (shpOrder.normCustomerName.isNotEmpty && shpOrder.normCustomerName.length >= 3 && internalByCustName.containsKey(shpOrder.normCustomerName)) {
        // Customer Name match fallback
        final candidateInternals = internalByCustName[shpOrder.normCustomerName]!;
        matchedInternal = candidateInternals.firstWhere(
          (cand) => !matchedInternalRowIndices.contains(cand.rowIndex),
          orElse: () => candidateInternals.first,
        );
        matchedInternalRowIndices.add(matchedInternal.rowIndex);
        matchedShippingRowIndices.add(shpOrder.rowIndex);

        matchStatus = OrderMatchStatus.conflict;
        confidence = MatchConfidence.low;
        dataConflictsCount++;
        notes.add('تطابق باسم العميل (${matchedInternal.rawCustomerName}) ولكن كود الطلب ورقم الهاتف غير متطابقين.');
      } else {
        // Exists in shipping report only
        matchStatus = OrderMatchStatus.shippingReportOnly;
        confidence = MatchConfidence.none;
        shippingReportOnlyCount++;
        notes.add('الطلب غير موجود في قاعدة البيانات الداخلية.');
      }

      final shippingStatusCategory = TextNormalizationService.classifyShippingStatus(shpOrder.rawStatus);
      final reqAmt = matchedInternal?.requiredAmount ?? (shpOrder.expectedAmount > 0 ? shpOrder.expectedAmount : shpOrder.collectedAmount);
      final colAmt = shpOrder.collectedAmount;
      final remAmt = (reqAmt - colAmt) < 0 ? 0.0 : (reqAmt - colAmt);

      final colStatusCategory = TextNormalizationService.classifyCollectionStatus(
        requiredAmount: reqAmt,
        collectedAmount: colAmt,
        rawCollectionStatusText: shpOrder.rawCollectionStatus,
      );

      final returnDestCategory = TextNormalizationService.classifyReturnDestination(
        shippingStatus: shippingStatusCategory,
        rawStatusText: shpOrder.rawStatus,
        notesText: shpOrder.rawReturnStatus,
      );

      // Aggregate Counters
      if (matchStatus == OrderMatchStatus.matched) matchedCount++;

      switch (shippingStatusCategory) {
        case ShippingStatusCategory.delivered: deliveredCount++; break;
        case ShippingStatusCategory.returned: returnedCount++; break;
        case ShippingStatusCategory.outForDelivery: outForDeliveryCount++; break;
        case ShippingStatusCategory.shipped: shippedCount++; break;
        case ShippingStatusCategory.failedDelivery: shippedCount++; break;
        case ShippingStatusCategory.notShipped: notShippedCount++; break;
        case ShippingStatusCategory.unknown: break;
      }

      switch (colStatusCategory) {
        case CollectionStatusCategory.fullyCollected: fullyCollectedCount++; break;
        case CollectionStatusCategory.partiallyCollected: partiallyCollectedCount++; break;
        case CollectionStatusCategory.notCollected: notCollectedCount++; break;
        case CollectionStatusCategory.overCollected: overCollectedCount++; break;
        case CollectionStatusCategory.amountMismatch: break;
        case CollectionStatusCategory.unknown: break;
      }

      switch (returnDestCategory) {
        case ReturnDestinationCategory.returnedToStore: returnedToStoreCount++; break;
        case ReturnDestinationCategory.returnedToShippingCompany: returnedToShippingCompanyCount++; break;
        case ReturnDestinationCategory.destinationUnknown: returnDestinationUnknownCount++; break;
        case ReturnDestinationCategory.none: break;
      }

      totalRequiredAmt += reqAmt;
      totalCollectedAmt += colAmt;
      totalRemainingAmt += remAmt;

      final reconciledItem = OrderReconciliationItem(
        id: 'rec_shp_${shpOrder.rowIndex}',
        matchStatus: matchStatus,
        confidenceLevel: confidence,
        shippingStatus: shippingStatusCategory,
        shippingStatusRaw: shpOrder.rawStatus,
        collectionStatus: colStatusCategory,
        returnDestination: returnDestCategory,
        returnDestinationRaw: shpOrder.rawReturnStatus,
        internalOrderNumber: matchedInternal?.rawOrderNumber,
        internalCustomerName: matchedInternal?.rawCustomerName,
        internalPhone: matchedInternal?.rawPhone,
        internalProduct: matchedInternal?.rawProduct,
        internalRequiredAmount: matchedInternal?.requiredAmount,
        internalGovernorate: matchedInternal?.governorate,
        internalAddress: matchedInternal?.address,
        internalDate: matchedInternal?.date,
        internalRawRow: matchedInternal?.rawRowMap,
        shippingOrderNumber: shpOrder.rawOrderNumber,
        shippingCustomerName: shpOrder.rawCustomerName,
        shippingPhone: shpOrder.rawPhone,
        shippingProduct: shpOrder.rawProduct,
        shippingExpectedAmount: shpOrder.expectedAmount,
        shippingCollectedAmount: shpOrder.collectedAmount,
        shippingStatusText: shpOrder.rawStatus,
        shippingCollectionStatusText: shpOrder.rawCollectionStatus,
        shippingReturnStatusText: shpOrder.rawReturnStatus,
        shippingRawRow: shpOrder.rawRowMap,
        requiredAmount: reqAmt,
        collectedAmount: colAmt,
        remainingAmount: remAmt,
        discrepancyNotes: notes,
      );

      resultItems.add(reconciledItem);
    }

    // B. Find Internal Orders missing from Shipping Report
    for (final intOrder in internalOrders) {
      if (!matchedInternalRowIndices.contains(intOrder.rowIndex)) {
        missingFromShippingCount++;
        notShippedCount++;
        notCollectedCount++;

        final reqAmt = intOrder.requiredAmount;
        totalRequiredAmt += reqAmt;
        totalRemainingAmt += reqAmt;

        final item = OrderReconciliationItem(
          id: 'rec_int_${intOrder.rowIndex}',
          matchStatus: OrderMatchStatus.missingFromShipping,
          confidenceLevel: MatchConfidence.none,
          shippingStatus: ShippingStatusCategory.notShipped,
          shippingStatusRaw: 'غير مشحون / لم يذكر بالتقرير',
          collectionStatus: CollectionStatusCategory.notCollected,
          returnDestination: ReturnDestinationCategory.none,
          returnDestinationRaw: '',
          internalOrderNumber: intOrder.rawOrderNumber,
          internalCustomerName: intOrder.rawCustomerName,
          internalPhone: intOrder.rawPhone,
          internalProduct: intOrder.rawProduct,
          internalRequiredAmount: intOrder.requiredAmount,
          internalGovernorate: intOrder.governorate,
          internalAddress: intOrder.address,
          internalDate: intOrder.date,
          internalRawRow: intOrder.rawRowMap,
          requiredAmount: reqAmt,
          collectedAmount: 0.0,
          remainingAmount: reqAmt,
          discrepancyNotes: const ['الطلب موجود في الملف الداخلي ولكن لم يرد بتقرير شركة الشحن.'],
        );

        resultItems.add(item);
      }
    }

    final dashboard = ReconciliationDashboard(
      totalInternalOrders: internalOrders.length,
      totalShippingOrders: shippingOrders.length,
      totalReconciledRecords: resultItems.length,
      matchedOrdersCount: matchedCount,
      missingFromShippingCount: missingFromShippingCount,
      shippingReportOnlyCount: shippingReportOnlyCount,
      dataConflictsCount: dataConflictsCount,
      duplicateOrdersCount: duplicateOrdersCount,
      deliveredCount: deliveredCount,
      returnedCount: returnedCount,
      outForDeliveryCount: outForDeliveryCount,
      shippedCount: shippedCount,
      notShippedCount: notShippedCount,
      fullyCollectedCount: fullyCollectedCount,
      partiallyCollectedCount: partiallyCollectedCount,
      notCollectedCount: notCollectedCount,
      overCollectedCount: overCollectedCount,
      returnedToStoreCount: returnedToStoreCount,
      returnedToShippingCompanyCount: returnedToShippingCompanyCount,
      returnDestinationUnknownCount: returnDestinationUnknownCount,
      totalRequiredAmount: totalRequiredAmt,
      totalCollectedAmount: totalCollectedAmt,
      totalRemainingAmount: totalRemainingAmt,
    );

    return ReconciliationResultData(
      dashboard: dashboard,
      items: resultItems,
    );
  }
}
