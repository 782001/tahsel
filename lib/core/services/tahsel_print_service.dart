import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tahsel/shared/widgets/tahsel_print_preview_screen.dart';

class TahselPrintService {
  /// Directly send bytes to system/hardware printer without preview
  static Future<bool> directPrint({
    required Uint8List bytes,
    required String jobName,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => bytes,
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
