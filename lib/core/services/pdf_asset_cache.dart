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
    _patchArabicGlyphMappings(_regularFont!);
    return _regularFont!;
  }

  /// Loads and caches the bold Arabic/English font
  static Future<pw.Font> getBoldFont() async {
    if (_boldFont != null) return _boldFont!;
    final data = await rootBundle.load('assets/fonts/DGAgnadeen-Bold.ttf');
    _boldFont = pw.Font.ttf(data);
    _patchArabicGlyphMappings(_boldFont!);
    return _boldFont!;
  }

  /// Dynamically fixes missing Arabic presentation glyph mappings (like isolated Yeh 0xFEF1)
  /// in the font's in-memory cmap to ensure all Arabic letters render seamlessly.
  static void _patchArabicGlyphMappings(pw.Font font) {
    try {
      final doc = pw.Document();
      final pdfFont = font.getFont(pw.Context(document: doc.document));
      final parser = (pdfFont as dynamic).font;
      final map = (parser as dynamic).charToGlyphIndexMap as Map<int, int>;

      // 1. Arabic Letter Yeh Isolated (0xFEF1) -> map to basic Yeh (0x064A)
      // Fixes the issue where 'ي' at the end of a word / isolated disappears in PDF
      if (map.containsKey(0x064A)) {
        map[0xFEF1] = map[0x064A]!;
      } else if (map.containsKey(0xFEEF)) {
        map[0xFEF1] = map[0xFEEF]!;
      }

      // 2. Arabic Letter Alef Maksura Isolated (0xFEEF) -> map if missing
      if (!map.containsKey(0xFEEF) && map.containsKey(0x064A)) {
        map[0xFEEF] = map[0x064A]!;
      }

      // 3. Arabic Letter Teh Marbuta Isolated (0xFE93) -> map to 0x0629 if missing
      if (!map.containsKey(0xFE93) && map.containsKey(0x0629)) {
        map[0xFE93] = map[0x0629]!;
      }

      // 4. Map Persian/Urdu Yeh variants (0x06CC, 0xFBFC-0xFBFF) to Arabic Yeh
      if (map.containsKey(0x064A)) {
        final yehGlyph = map[0x064A]!;
        map[0x06CC] = yehGlyph;
        map[0xFBFC] = yehGlyph;
        map[0xFBFD] = map[0xFEF2] ?? yehGlyph;
        map[0xFBFE] = map[0xFEF3] ?? yehGlyph;
        map[0xFBFF] = map[0xFEF4] ?? yehGlyph;
      }

      // 5. Map Persian/Urdu Keheh variants (0x06A9, 0xFB8E-0xFB91) to Arabic Kaf
      if (map.containsKey(0x0643)) {
        final kafGlyph = map[0x0643]!;
        map[0x06A9] = kafGlyph;
        map[0xFB8E] = kafGlyph;
        map[0xFB8F] = map[0xFEDA] ?? kafGlyph;
        map[0xFB90] = map[0xFEDB] ?? kafGlyph;
        map[0xFB91] = map[0xFEDC] ?? kafGlyph;
      }
    } catch (_) {
      // Gracefully continue if font internals differ
    }
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

