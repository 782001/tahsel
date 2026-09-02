import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/order_reconciliation_item.dart';
import '../../domain/entities/reconciliation_dashboard.dart';

class ShippingReconciliationExcelService {
  ShippingReconciliationExcelService._();

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Get public visible directory for saving reports offline
  static Future<Directory> _getPublicStorageDirectory() async {
    Directory? targetDir;

    if (!kIsWeb) {
      if (Platform.isWindows) {
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            targetDir = downloadDir;
          }
        } catch (_) {}
        targetDir ??= await getDownloadsDirectory();
        targetDir ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    }

    targetDir ??= await getApplicationDocumentsDirectory();

    final tahselDir = Directory('${targetDir.path}/Tahsel_Reports');
    if (!await tahselDir.exists()) {
      await tahselDir.create(recursive: true);
    }
    return tahselDir;
  }

  /// Automatically adjusts column widths based precisely on maximum character length in each column
  static void _autoFitColumnWidths(Sheet sheet, {required int totalCols}) {
    for (int col = 0; col < totalCols; col++) {
      double maxLen = 4.0;

      for (int row = 0; row < sheet.maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        if (cell.value != null) {
          final strVal = cell.value.toString().trim();
          if (strVal.isEmpty) continue;

          double len = 0;
          for (final rune in strVal.runes) {
            if (rune >= 0x0600 && rune <= 0x06FF) {
              len += 1.1; // Arabic character width factor
            } else {
              len += 0.95; // Number / English character width factor
            }
          }
          if (len > maxLen) {
            maxLen = len;
          }
        }
      }

      // Add tight padding (+3.0) and clamp cleanly between 6.0 and 55.0
      final finalWidth = (maxLen + 3.0).clamp(6.0, 55.0);
      sheet.setColumnWidth(col, finalWidth);
    }
  }

  // --- STYLING HELPERS FOR STATUSES AND AMOUNTS ---

  /// Color style for Amount Comparisons (Collected vs Required)
  static CellStyle _getAmountCellStyle({required double requiredAmt, required double collectedAmt}) {
    if ((collectedAmt - requiredAmt).abs() < 0.01) {
      // Collected == Required (Exact match) -> Soft Green
      return CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'),
        fontColorHex: ExcelColor.fromHexString('#15803D'),
      );
    } else if (collectedAmt < requiredAmt) {
      // Collected < Required (Undercollected / Shortage) -> Soft Red Alert
      return CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'),
        fontColorHex: ExcelColor.fromHexString('#B91C1C'),
      );
    } else {
      // Collected > Required (Overcollected) -> Soft Blue
      return CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
        fontColorHex: ExcelColor.fromHexString('#1E40AF'),
      );
    }
  }

  /// Color style for Match Status
  static CellStyle _getMatchStatusCellStyle(OrderMatchStatus status) {
    switch (status) {
      case OrderMatchStatus.matched:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'), // Green
          fontColorHex: ExcelColor.fromHexString('#1B5E20'),
        );
      case OrderMatchStatus.missingFromShipping:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'), // Red
          fontColorHex: ExcelColor.fromHexString('#B71C1C'),
        );
      case OrderMatchStatus.shippingReportOnly:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'), // Purple
          fontColorHex: ExcelColor.fromHexString('#4A148C'),
        );
      case OrderMatchStatus.conflict:
      case OrderMatchStatus.duplicate:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'), // Orange
          fontColorHex: ExcelColor.fromHexString('#E65100'),
        );
    }
  }

  /// Color style for Match Confidence Level
  static CellStyle _getConfidenceCellStyle(MatchConfidence confidence) {
    switch (confidence) {
      case MatchConfidence.high:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'), // Soft Green
          fontColorHex: ExcelColor.fromHexString('#15803D'),
        );
      case MatchConfidence.medium:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'), // Soft Yellow
          fontColorHex: ExcelColor.fromHexString('#B45309'),
        );
      case MatchConfidence.low:
      case MatchConfidence.none:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'), // Soft Red
          fontColorHex: ExcelColor.fromHexString('#B91C1C'),
        );
    }
  }

  /// Color style for Shipping Status Category
  static CellStyle _getShippingStatusCellStyle(ShippingStatusCategory status) {
    switch (status) {
      case ShippingStatusCategory.delivered:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'),
          fontColorHex: ExcelColor.fromHexString('#15803D'),
        );
      case ShippingStatusCategory.returned:
      case ShippingStatusCategory.failedDelivery:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'),
          fontColorHex: ExcelColor.fromHexString('#B91C1C'),
        );
      case ShippingStatusCategory.outForDelivery:
      case ShippingStatusCategory.shipped:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
          fontColorHex: ExcelColor.fromHexString('#1E40AF'),
        );
      case ShippingStatusCategory.notShipped:
      case ShippingStatusCategory.unknown:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
          fontColorHex: ExcelColor.fromHexString('#4B5563'),
        );
    }
  }

  /// Color style for Collection Status Category
  static CellStyle _getCollectionStatusCellStyle(CollectionStatusCategory status) {
    switch (status) {
      case CollectionStatusCategory.fullyCollected:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'), // Soft Green
          fontColorHex: ExcelColor.fromHexString('#15803D'),
        );
      case CollectionStatusCategory.partiallyCollected:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'), // Soft Yellow
          fontColorHex: ExcelColor.fromHexString('#B45309'),
        );
      case CollectionStatusCategory.notCollected:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'), // Soft Red
          fontColorHex: ExcelColor.fromHexString('#B91C1C'),
        );
      case CollectionStatusCategory.overCollected:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'), // Soft Blue
          fontColorHex: ExcelColor.fromHexString('#1E40AF'),
        );
      case CollectionStatusCategory.amountMismatch:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3E8FF'), // Soft Purple
          fontColorHex: ExcelColor.fromHexString('#6B21A8'),
        );
      case CollectionStatusCategory.unknown:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
          fontColorHex: ExcelColor.fromHexString('#4B5563'),
        );
    }
  }

  /// Color style for Return Destination Category
  static CellStyle _getReturnDestCellStyle(ReturnDestinationCategory dest) {
    switch (dest) {
      case ReturnDestinationCategory.returnedToStore:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E0F2FE'), // Soft Sky Blue / Teal
          fontColorHex: ExcelColor.fromHexString('#0369A1'),
        );
      case ReturnDestinationCategory.returnedToShippingCompany:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFEDD5'), // Soft Orange / Amber
          fontColorHex: ExcelColor.fromHexString('#C2410C'),
        );
      case ReturnDestinationCategory.destinationUnknown:
      case ReturnDestinationCategory.none:
        return CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'), // Soft Gray
          fontColorHex: ExcelColor.fromHexString('#4B5563'),
        );
    }
  }

  static String _getMatchStatusLabel(OrderMatchStatus status) {
    switch (status) {
      case OrderMatchStatus.matched:
        return AppStrings.matchStatusMatched.tr();
      case OrderMatchStatus.missingFromShipping:
        return AppStrings.matchStatusMissingFromShipping.tr();
      case OrderMatchStatus.shippingReportOnly:
        return AppStrings.matchStatusShippingReportOnly.tr();
      case OrderMatchStatus.conflict:
        return AppStrings.matchStatusConflict.tr();
      case OrderMatchStatus.duplicate:
        return AppStrings.matchStatusDuplicate.tr();
    }
  }

  static String _getConfidenceLabel(MatchConfidence confidence) {
    switch (confidence) {
      case MatchConfidence.high:
        return AppStrings.confidenceHigh.tr();
      case MatchConfidence.medium:
        return AppStrings.confidenceMedium.tr();
      case MatchConfidence.low:
        return AppStrings.confidenceLow.tr();
      case MatchConfidence.none:
        return AppStrings.confidenceNone.tr();
    }
  }

  static String _getShippingStatusLabel(ShippingStatusCategory status) {
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

  static String _getCollectionStatusLabel(CollectionStatusCategory status) {
    switch (status) {
      case CollectionStatusCategory.fullyCollected:
        return AppStrings.fullyCollectedCount.tr();
      case CollectionStatusCategory.partiallyCollected:
        return AppStrings.partiallyCollectedCount.tr();
      case CollectionStatusCategory.notCollected:
        return AppStrings.notCollectedCount.tr();
      case CollectionStatusCategory.overCollected:
        return AppStrings.collectionCollected.tr();
      case CollectionStatusCategory.amountMismatch:
        return AppStrings.matchStatusConflict.tr();
      case CollectionStatusCategory.unknown:
        return AppStrings.statusUnknown.tr();
    }
  }

  static String _getReturnDestLabel(ReturnDestinationCategory dest) {
    switch (dest) {
      case ReturnDestinationCategory.returnedToStore:
        return AppStrings.returnDestInternalStore.tr();
      case ReturnDestinationCategory.returnedToShippingCompany:
        return AppStrings.returnDestShippingWarehouse.tr();
      case ReturnDestinationCategory.destinationUnknown:
      case ReturnDestinationCategory.none:
        return AppStrings.returnDestNotReturned.tr();
    }
  }

  /// Exports comprehensive reconciliation report to Excel (.xlsx) offline
  static Future<String?> exportReconciliationReport({
    required ReconciliationDashboard dashboard,
    required List<OrderReconciliationItem> items,
  }) async {
    try {
      final excel = Excel.createExcel();
      final primaryHex = _colorToHex(AppColors.primaryColor); // #1E56A0 Tahsel Primary Blue

      // ==========================================
      // SHEET 1: Executive Financial Summary & Stats
      // ==========================================
      final summarySheetName = AppStrings.sheetFinancialSummary.tr();
      excel.rename('Sheet1', summarySheetName);
      final sheet1 = excel[summarySheetName];
      sheet1.isRTL = true;

      void applyHeaderStyle(int col, int row) {
        final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      void applySectionStyle(int col, int row) {
        final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#D6E4F0'), // Tahsel Card Tint
          fontColorHex: ExcelColor.fromHexString('#1E56A0'),
        );
      }

      // Banner Title
      sheet1.appendRow([TextCellValue(AppStrings.reportTitleExcel.tr()), TextCellValue('')]);
      applyHeaderStyle(0, 0);
      applyHeaderStyle(1, 0);

      sheet1.appendRow([
        TextCellValue(AppStrings.reportDateLabel.tr()),
        TextCellValue(DateTime.now().toIso8601String().split('.').first.replaceAll('T', ' ')),
      ]);
      sheet1.appendRow([TextCellValue(''), TextCellValue('')]); // Spacer

      // Section 1: Financial Summary
      sheet1.appendRow([
        TextCellValue(AppStrings.sectionFinancialSummary.tr()),
        TextCellValue(AppStrings.amountEgpHeader.tr()),
      ]);
      applySectionStyle(0, 3);
      applySectionStyle(1, 3);

      sheet1.appendRow([TextCellValue(AppStrings.totalRequiredAmount.tr()), DoubleCellValue(dashboard.totalRequiredAmount)]);
      sheet1.appendRow([TextCellValue(AppStrings.totalCollectedAmount.tr()), DoubleCellValue(dashboard.totalCollectedAmount)]);
      sheet1.appendRow([TextCellValue(AppStrings.totalRemainingAmount.tr()), DoubleCellValue(dashboard.totalRemainingAmount)]);
      sheet1.appendRow([TextCellValue(''), TextCellValue('')]);

      // Section 2: Metrics
      sheet1.appendRow([
        TextCellValue(AppStrings.sectionMetrics.tr()),
        TextCellValue(AppStrings.ordersCountHeader.tr()),
      ]);
      applySectionStyle(0, 8);
      applySectionStyle(1, 8);

      sheet1.appendRow([TextCellValue(AppStrings.totalShipments.tr()), IntCellValue(dashboard.totalReconciledRecords)]);
      sheet1.appendRow([TextCellValue(AppStrings.matchedCount.tr()), IntCellValue(dashboard.matchedOrdersCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.missingFromShippingCount.tr()), IntCellValue(dashboard.missingFromShippingCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.deliveredCount.tr()), IntCellValue(dashboard.deliveredCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.returnedCount.tr()), IntCellValue(dashboard.returnedCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.fullyCollectedCount.tr()), IntCellValue(dashboard.fullyCollectedCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.partiallyCollectedCount.tr()), IntCellValue(dashboard.partiallyCollectedCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.notCollectedCount.tr()), IntCellValue(dashboard.notCollectedCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.conflictsCount.tr()), IntCellValue(dashboard.dataConflictsCount + dashboard.duplicateOrdersCount)]);
      sheet1.appendRow([TextCellValue(''), TextCellValue('')]);

      // Section 3: Return Destinations
      sheet1.appendRow([
        TextCellValue(AppStrings.sectionReturnsSummary.tr()),
        TextCellValue(AppStrings.shipmentsCountHeader.tr()),
      ]);
      applySectionStyle(0, 19);
      applySectionStyle(1, 19);

      sheet1.appendRow([TextCellValue(AppStrings.returnDestInternalStore.tr()), IntCellValue(dashboard.returnedToStoreCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.returnDestShippingWarehouse.tr()), IntCellValue(dashboard.returnedToShippingCompanyCount)]);
      sheet1.appendRow([TextCellValue(AppStrings.returnDestNotReturned.tr()), IntCellValue(dashboard.returnDestinationUnknownCount)]);

      // Auto-fit column widths for Sheet 1
      _autoFitColumnWidths(sheet1, totalCols: 2);

      // ==========================================
      // SHEET 2: Full Detailed Shipments & Customers
      // ==========================================
      final detailsSheetName = AppStrings.sheetReconciliationDetails.tr();
      final sheet2 = excel[detailsSheetName];
      sheet2.isRTL = true;

      sheet2.appendRow([TextCellValue(AppStrings.sheetDetailsTitleHeader.tr()), TextCellValue('')]);
      final sheet2TitleCell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      sheet2TitleCell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(primaryHex),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      sheet2.appendRow([TextCellValue(''), TextCellValue('')]); // Spacer

      final sheet2Headers = [
        '#',
        AppStrings.colOrderInternal.tr(),
        AppStrings.colOrderShipping.tr(),
        AppStrings.customerName.tr(),
        AppStrings.colPhone.tr(),
        AppStrings.colGovernorate.tr(),
        AppStrings.colAddress.tr(),
        AppStrings.colOrderDate.tr(),
        AppStrings.colProduct.tr(),
        AppStrings.shippingStatusLabel.tr(),
        AppStrings.collectionStatusLabel.tr(),
        '${AppStrings.colRequiredInternal.tr()} (${AppStrings.currencyEgp.tr()})',
        '${AppStrings.colCollectedShipping.tr()} (${AppStrings.currencyEgp.tr()})',
        '${AppStrings.colNetDifference.tr()} (${AppStrings.currencyEgp.tr()})',
        AppStrings.colMatchStatus.tr(),
        AppStrings.colConfidence.tr(),
        AppStrings.colReturnDest.tr(),
        AppStrings.colRawStatus.tr(),
        AppStrings.colDiscrepancyNotes.tr(),
      ];

      sheet2.appendRow(sheet2Headers.map((h) => TextCellValue(h)).toList());

      // Format Sheet 2 Header Row
      for (var col = 0; col < sheet2Headers.length; col++) {
        final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final notes = item.discrepancyNotes.isNotEmpty
            ? item.discrepancyNotes.join(' | ')
            : AppStrings.noDiscrepancyNotes.tr();

        final row = [
          IntCellValue(i + 1),
          TextCellValue(item.internalOrderNumber ?? '---'),
          TextCellValue(item.shippingOrderNumber ?? '---'),
          TextCellValue(item.displayCustomerName),
          TextCellValue(item.displayPhone),
          TextCellValue(item.internalGovernorate ?? '---'),
          TextCellValue(item.internalAddress ?? '---'),
          TextCellValue(item.internalDate ?? '---'),
          TextCellValue(item.displayProduct),
          TextCellValue(_getShippingStatusLabel(item.shippingStatus)),
          TextCellValue(_getCollectionStatusLabel(item.collectionStatus)),
          DoubleCellValue(item.requiredAmount),
          DoubleCellValue(item.collectedAmount),
          DoubleCellValue(item.remainingAmount),
          TextCellValue(_getMatchStatusLabel(item.matchStatus)),
          TextCellValue(_getConfidenceLabel(item.confidenceLevel)),
          TextCellValue(_getReturnDestLabel(item.returnDestination)),
          TextCellValue(item.shippingStatusRaw.isNotEmpty ? item.shippingStatusRaw : '---'),
          TextCellValue(notes),
        ];
        sheet2.appendRow(row);

        // Row background tint for even rows
        final rowIndex = i + 3; // Data starts at row index 3
        final isEvenRow = i % 2 == 0;
        final defaultRowBgHex = isEvenRow ? '#F8FAFC' : '#FFFFFF';

        // Apply distinct color styling to every specific field:
        for (int c = 0; c < sheet2Headers.length; c++) {
          final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
          
          if (c == 9) {
            // Shipping Status (حالة الشحن)
            cell.cellStyle = _getShippingStatusCellStyle(item.shippingStatus);
          } else if (c == 10) {
            // Collection Status (حالة التحصيل)
            cell.cellStyle = _getCollectionStatusCellStyle(item.collectionStatus);
          } else if (c == 12 || c == 13) {
            // Collected Amount & Remaining Difference (المبلغ المحصل والفرق الصافي)
            cell.cellStyle = _getAmountCellStyle(requiredAmt: item.requiredAmount, collectedAmt: item.collectedAmount);
          } else if (c == 14) {
            // Match Status (حالة المطابقة)
            cell.cellStyle = _getMatchStatusCellStyle(item.matchStatus);
          } else if (c == 15) {
            // Match Confidence (دقة المطابقة)
            cell.cellStyle = _getConfidenceCellStyle(item.confidenceLevel);
          } else if (c == 16) {
            // Return Destination (جهة المرتجع)
            cell.cellStyle = _getReturnDestCellStyle(item.returnDestination);
          } else if (c == 17) {
            // Raw Shipping Status Text (نص حالة الشحن الخام)
            cell.cellStyle = _getShippingStatusCellStyle(item.shippingStatus);
          } else {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString(defaultRowBgHex),
            );
          }
        }
      }

      // Dynamic Auto-Fit Column Widths for Sheet 2
      _autoFitColumnWidths(sheet2, totalCols: sheet2Headers.length);

      // ==========================================
      // SHEET 3: Side-by-Side Data Comparison
      // ==========================================
      final comparisonSheetName = AppStrings.sheetComparisonName.tr();
      final sheet3 = excel[comparisonSheetName];
      sheet3.isRTL = true;

      sheet3.appendRow([TextCellValue(AppStrings.sheetComparisonBannerTitle.tr()), TextCellValue('')]);
      final sheet3TitleCell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      sheet3TitleCell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(primaryHex),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      sheet3.appendRow([TextCellValue(''), TextCellValue('')]); // Spacer

      final sheet3Headers = [
        '#',
        AppStrings.orderMatchDetails.tr(),
        AppStrings.colCustomerInternal.tr(),
        AppStrings.colCustomerShipping.tr(),
        AppStrings.colPhoneInternal.tr(),
        AppStrings.colPhoneShipping.tr(),
        AppStrings.colProductInternal.tr(),
        AppStrings.colProductShipping.tr(),
        AppStrings.colRequiredInternal.tr(),
        AppStrings.colCollectedShipping.tr(),
        AppStrings.shippingStatusLabel.tr(),
        AppStrings.colMatchStatus.tr(),
      ];

      sheet3.appendRow(sheet3Headers.map((h) => TextCellValue(h)).toList());

      for (var col = 0; col < sheet3Headers.length; col++) {
        final cell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final row = [
          IntCellValue(i + 1),
          TextCellValue(item.displayOrderNumber),
          TextCellValue(item.internalCustomerName ?? '---'),
          TextCellValue(item.shippingCustomerName ?? '---'),
          TextCellValue(item.internalPhone ?? '---'),
          TextCellValue(item.shippingPhone ?? '---'),
          TextCellValue(item.internalProduct ?? '---'),
          TextCellValue(item.shippingProduct ?? '---'),
          DoubleCellValue(item.internalRequiredAmount ?? item.requiredAmount),
          DoubleCellValue(item.shippingCollectedAmount ?? item.collectedAmount),
          TextCellValue(item.shippingStatusRaw.isNotEmpty ? item.shippingStatusRaw : _getShippingStatusLabel(item.shippingStatus)),
          TextCellValue(_getMatchStatusLabel(item.matchStatus)),
        ];
        sheet3.appendRow(row);

        final rowIndex = i + 3;
        final isEvenRow = i % 2 == 0;
        final defaultRowBgHex = isEvenRow ? '#F8FAFC' : '#FFFFFF';

        for (int c = 0; c < sheet3Headers.length; c++) {
          final cell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
          if (c == 9) {
            cell.cellStyle = _getAmountCellStyle(requiredAmt: item.requiredAmount, collectedAmt: item.collectedAmount);
          } else if (c == 10) {
            cell.cellStyle = _getShippingStatusCellStyle(item.shippingStatus);
          } else if (c == 11) {
            cell.cellStyle = _getMatchStatusCellStyle(item.matchStatus);
          } else {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString(defaultRowBgHex),
            );
          }
        }
      }

      // Dynamic Auto-Fit Column Widths for Sheet 3
      _autoFitColumnWidths(sheet3, totalCols: sheet3Headers.length);

      final bytes = excel.save();
      if (bytes == null) return null;

      final dir = await _getPublicStorageDirectory();
      final fileName = 'تقرير_تسوية_الشحن_التفصيلي_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: AppStrings.exportExcelSuccess.tr(),
        );
      } catch (_) {
        // OS level share modal handled gracefully
      }

      return file.path;
    } catch (e) {
      return null;
    }
  }
}
