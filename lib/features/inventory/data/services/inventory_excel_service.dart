import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../domain/entities/inventory_product_entity.dart';

class InventoryExcelService {
  /// Get the public visible directory on Android, iOS, and Windows (Download / Documents / Tahsel_Reports)
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

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static Future<String?> exportProducts(
    List<InventoryProductEntity> products,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = AppStrings.inventoryProducts.tr();
      excel.rename('Sheet1', sheetName);

      final sheet = excel[sheetName];
      sheet.isRTL = true;

      // Header Row using AppStrings translations
      final headers = [
        '#',
        AppStrings.skuKey.tr(),
        AppStrings.barcode.tr(),
        AppStrings.productName.tr(),
        AppStrings.categoryKey.tr(),
        AppStrings.supplierKey.tr(),
        '${AppStrings.purchasePriceKey.tr()} (${AppStrings.currencyEgp.tr()})',
        '${AppStrings.sellingPriceKey.tr()} (${AppStrings.currencyEgp.tr()})',
        AppStrings.currentQuantityKey.tr(),
        AppStrings.unitKey.tr(),
        '${AppStrings.totalAmount.tr()} (${AppStrings.currencyEgp.tr()})',
        AppStrings.statusKey.tr(),
        AppStrings.notes.tr(),
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Format Header Cells using AppColors.primaryColor & Set Column Widths (20+)
      final primaryHex = _colorToHex(AppColors.primaryColor);
      for (var col = 0; col < headers.length; col++) {
        final double width = col == 0 ? 8.0 : (col == 3 ? 25.0 : 20.0);
        sheet.setColumnWidth(col, width);

        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString(primaryHex),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Populate Data Rows
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        final totalValue = p.purchasePrice * p.currentQuantity;
        final status = p.currentQuantity <= 0
            ? AppStrings.outOfStockKey.tr()
            : p.currentQuantity <= p.minQuantity
                ? AppStrings.lowStockAlertKey.tr()
                : AppStrings.stableStockKey.tr();

        final categoryName = p.categoryName.isNotEmpty
            ? p.categoryName
            : AppStrings.noCategoryKey.tr();
        final supplierName = p.supplierName.isNotEmpty
            ? p.supplierName
            : AppStrings.noSupplierKey.tr();

        final rowValues = [
          IntCellValue(i + 1),
          TextCellValue(p.sku),
          TextCellValue(p.barcode ?? ''),
          TextCellValue(p.name),
          TextCellValue(categoryName),
          TextCellValue(supplierName),
          DoubleCellValue(p.purchasePrice),
          DoubleCellValue(p.sellingPrice),
          DoubleCellValue(p.currentQuantity),
          TextCellValue(p.unit),
          DoubleCellValue(totalValue),
          TextCellValue(status),
          TextCellValue(p.notes ?? ''),
        ];

        sheet.appendRow(rowValues);
      }

      final bytes = excel.save();
      if (bytes == null) return null;

      final dir = await _getPublicStorageDirectory();
      final fileName =
          '${AppStrings.inventoryProducts.tr()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: AppStrings.exportSuccess.tr(),
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }
}
