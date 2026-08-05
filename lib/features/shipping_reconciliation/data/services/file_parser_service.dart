import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/repositories/shipping_reconciliation_repository.dart';
import 'column_detector_service.dart';

class FileParserService {
  FileParserService._();

  static RawFileData parseBytes({
    required List<int> bytes,
    required String fileName,
  }) {
    return _parseExcel(bytes, fileName);
  }

  static RawFileData _parseExcel(List<int> bytes, String fileName) {
    final excel = Excel.decodeBytes(Uint8List.fromList(bytes));
    if (excel.tables.isEmpty) {
      throw const FormatException(
        'ملف Excel فارغ لا يحتوي على أوراق (Sheets).',
      );
    }

    // Pick table sheet with maximum rows intelligently
    String? targetSheet;
    int maxRowCount = -1;

    for (final tableKey in excel.tables.keys) {
      final table = excel.tables[tableKey];
      if (table != null && table.maxRows > maxRowCount) {
        maxRowCount = table.maxRows;
        targetSheet = tableKey;
      }
    }

    targetSheet ??= excel.tables.keys.first;
    final sheet = excel.tables[targetSheet]!;

    if (sheet.rows.isEmpty) {
      throw const FormatException('ورقة العمل لا تحتوي على بيانات.');
    }

    // Extract headers by intelligently finding the table header row
    int headerRowIndex = -1;
    for (int i = 0; i < sheet.rows.length && i < 20; i++) {
      final r = sheet.rows[i];
      final nonFieldsCount = r
          .where(
            (cell) =>
                cell != null &&
                cell.value != null &&
                cell.value.toString().trim().isNotEmpty,
          )
          .length;

      if (nonFieldsCount >= 2) {
        bool containsKeyword = false;
        for (final cell in r) {
          if (cell == null || cell.value == null) continue;
          if (ColumnDetectorService.isHeaderKeyword(cell.value.toString())) {
            containsKeyword = true;
            break;
          }
        }

        if (containsKeyword || nonFieldsCount >= 4) {
          headerRowIndex = i;
          break;
        }
      }
    }

    if (headerRowIndex == -1 || headerRowIndex >= sheet.rows.length) {
      headerRowIndex = 0;
    }

    final headerRow = sheet.rows[headerRowIndex];
    final headers = headerRow.map((cell) {
      if (cell == null || cell.value == null) return '';
      return cell.value.toString().trim();
    }).toList();

    final rows = <List<dynamic>>[];
    for (int i = headerRowIndex + 1; i < sheet.rows.length; i++) {
      final rowCells = sheet.rows[i];
      if (rowCells.every(
        (cell) =>
            cell == null ||
            cell.value == null ||
            cell.value.toString().trim().isEmpty,
      )) {
        continue; // Skip empty rows
      }

      final rowValues = rowCells.map((cell) {
        if (cell == null) return null;
        final val = cell.value;
        if (val is TextCellValue) return val.value.toString();
        if (val is IntCellValue) return val.value;
        if (val is DoubleCellValue) return val.value;
        if (val is DateCellValue) {
          return val.asDateTimeLocal().toIso8601String();
        }
        return val?.toString();
      }).toList();

      rows.add(rowValues);
    }

    return RawFileData(fileName: fileName, headers: headers, rows: rows);
  }
}
