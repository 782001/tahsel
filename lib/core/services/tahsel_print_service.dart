import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tahsel/shared/widgets/tahsel_print_preview_screen.dart';

class TahselPrintService {
  /// Converts a vector PDF into a high-resolution rasterized PDF document.
  /// On mobile devices (Android/iOS), physical printer drivers often fail to parse
  /// embedded subset TTF Arabic glyphs and RTL Bidi ordering, causing disconnected/separated
  /// letters and reversed numbers.
  /// By converting each page into a crisp high-resolution image, the printed output is
  /// 100% pixel-identical to what is rendered on screen.
  static Future<Uint8List> rasterizePdfDocument(
    Uint8List pdfBytes, {
    double dpi = 300,
  }) async {
    try {
      final rasterPdf = pw.Document();
      var pageCount = 0;

      await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
        pageCount++;
        final pngBytes = await page.toPng();
        final pageImage = pw.MemoryImage(pngBytes, dpi: dpi);
        final double widthInPoints = page.width.toDouble() * 72.0 / dpi;
        final double heightInPoints = page.height.toDouble() * 72.0 / dpi;

        rasterPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              widthInPoints,
              heightInPoints,
              marginAll: 0,
            ),
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pageImage, fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      }

      if (pageCount == 0) {
        return pdfBytes;
      }

      return await rasterPdf.save();
    } catch (e) {
      debugPrint('TahselPrintService.rasterizePdfDocument error: $e');
      return pdfBytes;
    }
  }

  /// Directly send bytes to system/hardware printer without preview.
  /// Automatically rasterizes to 300 DPI images on mobile (Android/iOS) to fix
  /// printer driver Arabic shaping and number reversal issues.
  static Future<bool> directPrint({
    required Uint8List bytes,
    required String jobName,
    PdfPageFormat format = PdfPageFormat.a4,
    bool rasterize = true,
  }) async {
    Uint8List printBytes = bytes;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (rasterize && isMobile) {
      try {
        printBytes = await rasterizePdfDocument(bytes, dpi: 300);
      } catch (e) {
        debugPrint('TahselPrintService: Rasterization fallback error: $e');
        printBytes = bytes;
      }
    }

    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => printBytes,
      name: jobName,
      format: format,
    );
  }

  /// Open full-featured Tahsel styled print preview screen
  static Future<void> openPrintPreview({
    required BuildContext context,
    required String title,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    required String pdfFileName,
    List<PdfPreviewAction>? actions,
    bool allowPrinting = true,
    bool allowSharing = true,
  }) async {
    await TahselPrintPreviewScreen.show(
      context: context,
      title: title,
      buildPdf: buildPdf,
      pdfFileName: pdfFileName,
      actions: actions,
      allowPrinting: allowPrinting,
      allowSharing: allowSharing,
    );
  }

  /// Share PDF bytes directly via system sheet
  static Future<bool> sharePdf({
    required Uint8List bytes,
    required String filename,
    String? subject,
    String? text,
  }) async {
    return await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      subject: subject,
      body: text,
    );
  }
}
