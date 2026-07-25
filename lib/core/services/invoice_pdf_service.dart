import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:whatsapp_share2/whatsapp_share2.dart';

import '../utils/assets.dart';

class InvoicePdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _primaryDark = PdfColor.fromInt(0xFF061A35);
  static const PdfColor _info = PdfColor.fromInt(0xFF0288D1);
  static const PdfColor _success = PdfColor.fromInt(0xFF388E3C);
  static const PdfColor _warning = PdfColor.fromInt(0xFFFBC02D);
  static const PdfColor _error = PdfColor.fromInt(0xFFD32F2F);

  /// Get the public visible directory on Android, iOS, and Windows
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

    final tahselDir = Directory('${targetDir.path}/Tahsel_Invoices');
    if (!await tahselDir.exists()) {
      await tahselDir.create(recursive: true);
    }
    return tahselDir;
  }

  /// Save PDF to device storage (opens Windows Folder Picker on Windows)
  static Future<File?> saveInvoicePdfToStorage({
    required InvoiceEntity invoice,
    required bool isArabic,
  }) async {
    final pdfBytes = await _buildPdf(invoice, isArabic);
    final cleanId = invoice.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'Fatoora_$cleanId.pdf';

    final storageDir = await _getPublicStorageDirectory();
    final savedFile = File('${storageDir.path}/$filename');
    await savedFile.writeAsBytes(pdfBytes);
    return savedFile;
  }

  static Future<File> generateAndShareInvoice(
    InvoiceEntity invoice, {
    required bool isArabic,
    String? phoneNumber,
  }) async {
    final pdfBytes = await _buildPdf(invoice, isArabic);
    final cleanId = invoice.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'Fatoora_$cleanId.pdf';

    final dir = await getTemporaryDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final idShort = invoice.id.length > 8
        ? invoice.id.substring(0, 8)
        : invoice.id;
    final subject = isArabic ? 'فاتورة رقم $idShort' : 'Invoice #$idShort';

    if (!kIsWeb &&
        Platform.isAndroid &&
        phoneNumber != null &&
        phoneNumber.isNotEmpty) {
      String formattedPhone = phoneNumber.toWhatsAppFormat();

      await WhatsappShare.shareFile(
        phone: formattedPhone,
        filePath: [shareFile.path],
        text: subject,
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(shareFile.path, mimeType: 'application/pdf')],
          text: subject,
          subject: subject,
        ),
      );
    }

    return shareFile;
  }

  static Future<File> generateInvoicePdf({
    required InvoiceEntity invoice,
    required bool isArabic,
  }) async {
    final pdfBytes = await _buildPdf(invoice, isArabic);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.id}.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<Uint8List> _buildPdf(
    InvoiceEntity invoice,
    bool isArabic,
  ) async {
    final pdf = pw.Document();

    // Load fonts
    final regularFontData = await rootBundle.load(
      'assets/fonts/DGAgnadeen-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/DGAgnadeen-Bold.ttf',
    );
    final ttfRegular = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load(Assets.imagesAppLogo);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          buildBackground: (context) => _buildBackground(),
          margin: const pw.EdgeInsets.all(32),
        ),
        header: (context) => _buildHeader(invoice, logoImage, isArabic),
        footer: (context) =>
            _buildFooter(isArabic, context.pageNumber, context.pagesCount),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildCustomerInfo(invoice, isArabic),
          pw.SizedBox(height: 30),
          _buildItemsTable(invoice, isArabic),
          pw.SizedBox(height: 30),
          _buildSummary(invoice, isArabic),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildNotes(invoice.notes!, isArabic),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildBackground() {
    return pw.Container(
      decoration: const pw.BoxDecoration(color: PdfColors.white),
    );
  }

  static pw.Widget _buildHeader(
    InvoiceEntity invoice,
    pw.MemoryImage? logoImage,
    bool isArabic,
  ) {
    final dateStr = DateFormat(
      isArabic ? "dd MMMM yyyy - hh:mm a" : "MMM dd, yyyy - hh:mm a",
      isArabic ? "ar" : "en",
    ).format(invoice.createdAt);

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? "فاتورة" : "INVOICE",
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '# ${invoice.id.substring(0, 8).toUpperCase()}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  dateStr,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            if (logoImage != null)
              pw.Container(
                height: 80,
                width: 80,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: _primary,
                  image: pw.DecorationImage(
                    image: logoImage,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: _primary, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(InvoiceEntity invoice, bool isArabic) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isArabic ? "بيانات العميل:" : "Customer Details:",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryDark,
                ),
              ),
              pw.SizedBox(height: 8),
              if (invoice.customerName != null)
                pw.Text(
                  invoice.customerName!,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                )
              else
                pw.Text(
                  isArabic ? "عميل نقدي" : "Cash Customer",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (invoice.customerPhone != null &&
                  invoice.customerPhone!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.customerPhone!,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
              if (invoice.ledgerNumber != null &&
                  invoice.ledgerNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  "${isArabic ? 'رقم الدفتر:' : 'Ledger #:'} ${invoice.ledgerNumber}",
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildStatusBadge(invoice.status, isArabic),
      ],
    );
  }

  static pw.Widget _buildStatusBadge(InvoiceStatus status, bool isArabic) {
    String text;
    PdfColor color;
    switch (status) {
      case InvoiceStatus.paid:
        text = isArabic ? "مدفوعة" : "Paid";
        color = _success;
        break;
      case InvoiceStatus.partial:
        text = isArabic ? "مدفوعة جزئياً" : "Partial";
        color = _warning;
        break;
      case InvoiceStatus.voided:
        text = isArabic ? "ملغاة" : "Voided";
        color = _error;
        break;
      case InvoiceStatus.pending:
        text = isArabic ? "معلقة" : "Pending";
        color = _info;
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(InvoiceEntity invoice, bool isArabic) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            _buildTableHeader(isArabic ? "الوصف" : "Description"),
            _buildTableHeader(isArabic ? "السعر" : "Price"),
            _buildTableHeader(isArabic ? "الكمية" : "Qty"),
            _buildTableHeader(isArabic ? "الإجمالي" : "Total"),
          ],
        ),
        // Items
        for (final item in invoice.items)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: [
              _buildTableCell(item.description, align: pw.TextAlign.left),
              _buildTableCell(
                item.unitPrice.toSmartAmount(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                item.quantity.toSmartAmount(),
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                item.total.toSmartAmount(),
                align: pw.TextAlign.center,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: PdfColors.black, fontSize: 13),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildSummary(InvoiceEntity invoice, bool isArabic) {
    final currency = isArabic ? "ج.م" : "EGP";

    return pw.Container(
      alignment: isArabic ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        padding: const pw.EdgeInsets.all(16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              isArabic ? "الإجمالي:" : "Subtotal:",
              "${invoice.totalAmount.toSmartAmount()} $currency",
              isBold: false,
            ),
            pw.SizedBox(height: 8),
            _buildSummaryRow(
              isArabic ? "المدفوع:" : "Paid:",
              "${invoice.totalPaid.toSmartAmount()} $currency",
              isBold: false,
              color: _success,
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            _buildSummaryRow(
              isArabic ? "المتبقي:" : "Remaining:",
              "${invoice.remainingAmount.toSmartAmount()} $currency",
              isBold: true,
              color: invoice.remainingAmount <= 0.01 ? _success : _error,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(String notes, bool isArabic) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(
          0x0C0288D1,
        ), // _info.withOpacity(0.05) approximated
        border: pw.Border(left: pw.BorderSide(color: _info, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? "ملاحظات:" : "Notes:",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: _info,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(bool isArabic, int page, int pages) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              isArabic
                  ? "تم إنشاء هذه الفاتورة بواسطة تطبيق تحصيل"
                  : "Generated by Tahsel App",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
            pw.Text(
              "$page / $pages",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }
}
