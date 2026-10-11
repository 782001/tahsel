import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tahsel/core/services/logo/project_logo_service.dart';
import 'package:tahsel/core/utils/assets.dart';

/// In-memory cache for PDF fonts and assets to ensure sub-millisecond generation
class PdfAssetCache {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static Uint8List? _logoBytes;
  static pw.MemoryImage? _logoImage;

  /// Loads and caches the regular Arabic/English font
  static Future<pw.Font> getRegularFont() async {
    if (_regularFont != null) return _regularFont!;
    final data = await rootBundle.load('assets/fonts/DGAgnadeen-Regular.ttf');
    _regularFont = pw.Font.ttf(data);
    return _regularFont!;
  }

  /// Loads and caches the bold Arabic/English font
  static Future<pw.Font> getBoldFont() async {
    if (_boldFont != null) return _boldFont!;
    final data = await rootBundle.load('assets/fonts/DGAgnadeen-Bold.ttf');
    _boldFont = pw.Font.ttf(data);
    return _boldFont!;
  }

  /// Returns standard fallback fonts for PDF styling
  static List<pw.Font> getFallbackFonts() {
    return [pw.Font.helvetica()];
  }

  /// Loads the active project custom logo (if set) or falls back to Tahsel app logo
  static Future<pw.MemoryImage?> getLogoImage() async {
    try {
      final customBytes = await ProjectLogoService.instance.getLogoBytes();
      if (customBytes != null && customBytes.isNotEmpty) {
        return pw.MemoryImage(customBytes);
      }

      if (_logoImage != null) return _logoImage;
      if (_logoBytes == null) {
        final data = await rootBundle.load(Assets.imagesAppLogo);
        _logoBytes = data.buffer.asUint8List();
      }
      if (_logoBytes != null) {
        _logoImage = pw.MemoryImage(_logoBytes!);
      }
    } catch (_) {}
    return _logoImage;
  }

  /// Builds a [pw.Table] that aligns columns correctly according to text direction.
  /// When [isArabic] is true, columns are laid out Right-to-Left (column 0 on the far right).
  /// When [isArabic] is false, columns are laid out Left-to-Right (column 0 on the far left).
  static pw.Table buildDirectionalTable({
    required bool isArabic,
    required List<pw.TableRow> rows,
    Map<int, pw.TableColumnWidth>? columnWidths,
    pw.TableBorder? border,
    pw.TableCellVerticalAlignment defaultVerticalAlignment =
        pw.TableCellVerticalAlignment.top,
    pw.TableColumnWidth defaultColumnWidth = const pw.IntrinsicColumnWidth(),
    pw.TableWidth tableWidth = pw.TableWidth.max,
  }) {
    if (!isArabic) {
      return pw.Table(
        children: rows,
        columnWidths: columnWidths,
        border: border,
        defaultVerticalAlignment: defaultVerticalAlignment,
        defaultColumnWidth: defaultColumnWidth,
        tableWidth: tableWidth,
      );
    }

    // Determine max columns across all rows to properly map column widths
    int maxCols = 0;
    for (final row in rows) {
      if (row.children.length > maxCols) {
        maxCols = row.children.length;
      }
    }
    if (columnWidths != null && columnWidths.isNotEmpty) {
      for (final key in columnWidths.keys) {
        if (key + 1 > maxCols) {
          maxCols = key + 1;
        }
      }
    }

    final reversedRows = rows.map((row) {
      return pw.TableRow(
        children: row.children.reversed.toList(),
        repeat: row.repeat,
        verticalAlignment: row.verticalAlignment,
        decoration: row.decoration,
      );
    }).toList();

    Map<int, pw.TableColumnWidth>? reversedWidths;
    if (columnWidths != null && maxCols > 0) {
      reversedWidths = {};
      for (final entry in columnWidths.entries) {
        final reversedIndex = maxCols - 1 - entry.key;
        if (reversedIndex >= 0) {
          reversedWidths[reversedIndex] = entry.value;
        }
      }
    }

    return pw.Table(
      children: reversedRows,
      columnWidths: reversedWidths,
      border: border,
      defaultVerticalAlignment: defaultVerticalAlignment,
      defaultColumnWidth: defaultColumnWidth,
      tableWidth: tableWidth,
    );
  }
}

