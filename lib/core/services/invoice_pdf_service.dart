import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_purchase_entity.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:whatsapp_share2/whatsapp_share2.dart';

class InvoicePdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _primaryDark = PdfColor.fromInt(0xFF061A35);
  static const PdfColor _info = PdfColor.fromInt(0xFF0288D1);
  static const PdfColor _success = PdfColor.fromInt(0xFF388E3C);
  static const PdfColor _warning = PdfColor.fromInt(0xFFFBC02D);
  static const PdfColor _error = PdfColor.fromInt(0xFFD32F2F);

  static const PdfColor _purchasePrimary = PdfColor.fromInt(0xFF673AB7);
  static const PdfColor _purchasePrimaryDark = PdfColor.fromInt(0xFF512DA8);
  static const PdfColor _purchaseBgLight = PdfColor.fromInt(0xFFEDE7F6);
  static const PdfColor _purchaseBorder = PdfColor.fromInt(0xFFD1C4E9);
  static const PdfColor _purchaseBorderMedium = PdfColor.fromInt(0xFFB39DDB);

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
    final prefix = invoice.isQuotation ? 'Ard_Seer' : 'Fatoora';
    final filename = '${prefix}_$cleanId.pdf';

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
    final prefix = invoice.isQuotation ? 'Ard_Seer' : 'Fatoora';
    final filename = '${prefix}_$cleanId.pdf';

    final dir = await getTemporaryDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final idShort = invoice.id.length > 8
        ? invoice.id.substring(0, 8)
        : invoice.id;
    final subject = invoice.isQuotation
        ? (isArabic ? 'عرض سعر رقم $idShort' : 'Quotation #$idShort')
        : (isArabic ? 'فاتورة رقم $idShort' : 'Invoice #$idShort');

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
    } else if (!kIsWeb && Platform.isWindows) {
      try {
        await Process.run('cmd', ['/c', 'start', '', shareFile.path]);
      } catch (_) {
        try {
          await Process.run('explorer.exe', ['/select,', shareFile.path]);
        } catch (_) {}
      }
    } else {
      try {
        await Share.shareXFiles(
          [XFile(shareFile.path, mimeType: 'application/pdf')],
          text: subject,
          subject: subject,
        );
      } catch (_) {
        try {
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: filename,
            subject: subject,
          );
        } catch (_) {}
      }
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

  static Future<Uint8List> getInvoicePdfBytes({
    required InvoiceEntity invoice,
    required bool isArabic,
  }) async {
    return await _buildPdf(invoice, isArabic);
  }

  /// Print sales invoice directly or open Tahsel themed print preview
  static Future<void> printInvoice(
    BuildContext context,
    InvoiceEntity invoice, {
    required bool isArabic,
    bool direct = false,
  }) async {
    final cleanId = invoice.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final shortId = invoice.id.length > 8
        ? invoice.id.substring(0, 8).toUpperCase()
        : invoice.id.toUpperCase();
    final filename = 'Fatoora_$cleanId.pdf';
    final title = isArabic
        ? 'طباعة فاتورة #$shortId'
        : 'Print Invoice #$shortId';

    if (direct) {
      final bytes = await getInvoicePdfBytes(
        invoice: invoice,
        isArabic: isArabic,
      );
      await TahselPrintService.directPrint(bytes: bytes, jobName: title);
    } else {
      await TahselPrintService.openPrintPreview(
        context: context,
        title: title,
        buildPdf: (format) => _buildPdf(invoice, isArabic),
        pdfFileName: filename,
      );
    }
  }

  static Future<Uint8List> _buildPdf(
    InvoiceEntity invoice,
    bool isArabic,
  ) async {
    final pdf = pw.Document();

    // Load cached fonts, logo and active seller profile
    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();
    final sellerProfile = await BusinessProfileService.instance.getProfile();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          buildBackground: (context) => _buildBackground(),
          margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        ),
        header: (context) =>
            _buildHeader(invoice, logoImage, isArabic, sellerProfile),
        footer: (context) => _buildFooter(
          isArabic,
          context.pageNumber,
          context.pagesCount,
          sellerProfile,
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildBusinessAndCustomerInfo(invoice, sellerProfile, isArabic),
          pw.SizedBox(height: 10),
          _buildItemsTable(invoice, isArabic),
          pw.SizedBox(height: 10),
          _buildBottomSection(invoice, isArabic),
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
    UserProfileModel? sellerProfile,
  ) {
    final dateStr = DateFormat(
      isArabic ? "dd MMMM yyyy - hh:mm a" : "MMM dd, yyyy - hh:mm a",
      isArabic ? "ar" : "en",
    ).format(invoice.createdAt);

    final titleText = invoice.isQuotation
        ? (isArabic ? "عرض سعر" : "QUOTATION")
        : (isArabic ? "فاتورة مبيعات" : "SALES INVOICE");

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Left/Start: Invoice Title & ID & Date
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  titleText,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      '# ${invoice.id.substring(0, 8).toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Right/End: Project Logo & Project Name
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (sellerProfile != null &&
                    sellerProfile.projectName.isNotEmpty) ...[
                  pw.Column(
                    crossAxisAlignment: isArabic
                        ? pw.CrossAxisAlignment.start
                        : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        sellerProfile.projectName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryDark,
                        ),
                      ),
                      if (sellerProfile.phoneNumber.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          sellerProfile.phoneNumber,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(width: 10),
                ],
                if (logoImage != null)
                  pw.Container(
                    height: 50,
                    constraints: const pw.BoxConstraints(maxWidth: 100),
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    alignment: pw.Alignment.center,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _primary, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _buildBusinessAndCustomerInfo(
    InvoiceEntity invoice,
    UserProfileModel? sellerProfile,
    bool isArabic,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Seller Details Card
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic
                      ? "بيانات المنشأة (البائع):"
                      : "Seller / Business Details:",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryDark,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  sellerProfile != null && sellerProfile.projectName.isNotEmpty
                      ? sellerProfile.projectName
                      : (isArabic ? "النشاط التجاري" : "Business Name"),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                if (sellerProfile != null &&
                    sellerProfile.fullName.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'المسؤول:' : 'Contact:'} ${sellerProfile.fullName}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (sellerProfile != null &&
                    sellerProfile.phoneNumber.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'الهاتف:' : 'Phone:'} ${sellerProfile.phoneNumber}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (sellerProfile != null && sellerProfile.crn.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'س.ت:' : 'CRN:'} ${sellerProfile.crn}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (sellerProfile != null && sellerProfile.vat.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'الرقم الضريبي:' : 'VAT:'} ${sellerProfile.vat}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (sellerProfile != null &&
                    sellerProfile.address.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'العنوان:' : 'Address:'} ${sellerProfile.address}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        // Customer Details Card
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isArabic ? "بيانات العميل:" : "Customer Details:",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryDark,
                      ),
                    ),
                    _buildStatusBadge(invoice.status, isArabic),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  invoice.customerName.cleanForPdf(
                    isArabic ? "عميل" : "Customer",
                  ),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                if (invoice.customerPhone != null &&
                    invoice.customerPhone!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'الهاتف:' : 'Phone:'} ${invoice.customerPhone!}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (invoice.ledgerNumber != null &&
                    invoice.ledgerNumber!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'رقم الدفتر:' : 'Ledger #:'} ${invoice.ledgerNumber}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
      case InvoiceStatus.quotation:
        text = isArabic ? "عرض سعر" : "Quotation";
        color = _primary;
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(InvoiceEntity invoice, bool isArabic) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7), // #
        1: const pw.FlexColumnWidth(3.6), // Description
        2: const pw.FlexColumnWidth(1.3), // Unit
        3: const pw.FlexColumnWidth(1.1), // Quantity
        4: const pw.FlexColumnWidth(1.5), // Unit Price
        5: const pw.FlexColumnWidth(1.3), // Discount
        6: const pw.FlexColumnWidth(1.7), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            _buildTableHeader("#"),
            _buildTableHeader(
              isArabic ? "الصنف" : "Item",
              align: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
            _buildTableHeader(isArabic ? "الوحدة" : "Unit"),
            _buildTableHeader(isArabic ? "الكمية" : "Qty"),
            _buildTableHeader(isArabic ? "السعر" : "Price"),
            _buildTableHeader(isArabic ? "الخصم" : "Discount"),
            _buildTableHeader(isArabic ? "الإجمالي" : "Total"),
          ],
        ),
        // Items
        for (int i = 0; i < invoice.items.length; i++) ...[
          () {
            final item = invoice.items[i];
            final rowColor = i.isEven ? PdfColors.white : PdfColors.grey50;
            final unitText = item.unit != null && item.unit!.trim().isNotEmpty
                ? item.unit!.trim()
                : (isArabic ? "قطعة" : "Pcs");
            final discountText = item.discountAmount > 0
                ? item.discountAmount.toSmartAmount()
                : "-";

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: rowColor),
              children: [
                _buildTableCell("${i + 1}", align: pw.TextAlign.center),
                _buildTableCell(
                  item.description.cleanForPdf(),
                  align: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  isBold: true,
                ),
                _buildTableCell(unitText, align: pw.TextAlign.center),
                _buildTableCell(
                  item.quantity.toSmartAmount(),
                  align: pw.TextAlign.center,
                  isBold: true,
                ),
                _buildTableCell(
                  item.unitPrice.toSmartAmount(),
                  align: pw.TextAlign.center,
                ),
                _buildTableCell(
                  discountText,
                  align: pw.TextAlign.center,
                  color: item.discountAmount > 0 ? _error : PdfColors.grey600,
                ),
                _buildTableCell(
                  item.total.toSmartAmount(),
                  align: pw.TextAlign.center,
                  isBold: true,
                  color: _primaryDark,
                ),
              ],
            );
          }(),
        ],
      ],
    );
  }

  static pw.Widget _buildTableHeader(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color ?? PdfColors.black,
          fontSize: 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildBottomSection(InvoiceEntity invoice, bool isArabic) {
    final currency = AppStrings.currencyEgp.tr();
    final totalQty = invoice.items.fold<double>(0.0, (s, i) => s + i.quantity);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Item & Quantity Statistics + Notes
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Stats badges box
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isArabic ? "عدد الأصناف:" : "Items Count:",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "${invoice.items.length}",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      width: 1,
                      height: 24,
                      color: PdfColors.grey300,
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isArabic ? "إجمالي الكمية:" : "Total Qty:",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          totalQty.toSmartAmount(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (invoice.notes != null &&
                  invoice.notes!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isArabic ? "ملاحظات:" : "Notes:",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          fontSize: 9,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        invoice.notes!.cleanForPdf(),
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Right side: Financial Summary Card
        pw.Container(
          width: 240,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                isArabic ? "الإجمالي قبل الخصم:" : "Subtotal:",
                "${invoice.rawSubtotalAmount.toSmartAmount()} $currency",
                fontSize: 9.5,
              ),
              if (invoice.totalDiscountAmount > 0) ...[
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? "الخصم الإجمالي:" : "Total Discount:",
                  "-${invoice.totalDiscountAmount.toSmartAmount()} $currency",
                  fontSize: 9.5,
                  color: _error,
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey300, thickness: 0.8),
              pw.SizedBox(height: 4),
              if (invoice.isQuotation) ...[
                _buildSummaryRow(
                  isArabic ? "إجمالي عرض السعر:" : "Quotation Total:",
                  "${invoice.totalAmount.toSmartAmount()} $currency",
                  isBold: true,
                  fontSize: 11,
                  color: _primary,
                ),
              ] else ...[
                _buildSummaryRow(
                  isArabic ? "الصافي الإجمالي:" : "Net Total:",
                  "${invoice.totalAmount.toSmartAmount()} $currency",
                  isBold: true,
                  fontSize: 11,
                  color: _primaryDark,
                ),
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? "المدفوع:" : "Paid:",
                  "${invoice.totalPaid.toSmartAmount()} $currency",
                  fontSize: 9.5,
                  color: _success,
                ),
                pw.SizedBox(height: 4),
                pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? "المتبقي:" : "Remaining:",
                  "${invoice.remainingAmount.toSmartAmount()} $currency",
                  isBold: true,
                  fontSize: 11,
                  color: invoice.remainingAmount <= 0.01 ? _success : _error,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isBold ? fontSize + 1 : fontSize,
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
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? "ملاحظات:" : "Notes:",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            notes.cleanForPdf(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    bool isArabic,
    int page,
    int pages, [
    UserProfileModel? profile,
  ]) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
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
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  /// Save Purchase PDF to device storage
  static Future<File?> savePurchasePdfToStorage({
    required InventoryPurchaseEntity purchase,
    required bool isArabic,
  }) async {
    final pdfBytes = await _buildPurchasePdf(purchase, isArabic);
    final cleanId = purchase.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'Purchase_Fatoora_$cleanId.pdf';

    final storageDir = await _getPublicStorageDirectory();
    final savedFile = File('${storageDir.path}/$filename');
    await savedFile.writeAsBytes(pdfBytes);
    return savedFile;
  }

  /// Generate & Share Purchase PDF
  static Future<File> sharePurchaseInvoicePdf(
    InventoryPurchaseEntity purchase, {
    required bool isArabic,
  }) async {
    final pdfBytes = await _buildPurchasePdf(purchase, isArabic);
    final cleanId = purchase.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'Purchase_Fatoora_$cleanId.pdf';

    final dir = await getTemporaryDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final idShort = purchase.id.replaceAll('pur_', '');
    final subject = isArabic
        ? 'فاتورة شراء رقم #$idShort'
        : 'Purchase Invoice #$idShort';

    if (!kIsWeb && Platform.isWindows) {
      try {
        await Process.run('cmd', ['/c', 'start', '', shareFile.path]);
      } catch (_) {
        try {
          await Process.run('explorer.exe', ['/select,', shareFile.path]);
        } catch (_) {}
      }
    } else {
      try {
        await Share.shareXFiles(
          [XFile(shareFile.path, mimeType: 'application/pdf')],
          text: subject,
          subject: subject,
        );
      } catch (_) {
        try {
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: filename,
            subject: subject,
          );
        } catch (_) {}
      }
    }

    return shareFile;
  }

  static Future<Uint8List> getPurchasePdfBytes({
    required InventoryPurchaseEntity purchase,
    required bool isArabic,
  }) async {
    return await _buildPurchasePdf(purchase, isArabic);
  }

  /// Print purchase invoice directly or open Tahsel themed print preview
  static Future<void> printPurchaseInvoice(
    BuildContext context,
    InventoryPurchaseEntity purchase, {
    required bool isArabic,
    bool direct = false,
  }) async {
    final cleanId = purchase.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final shortId = purchase.id.replaceAll('pur_', '');
    final filename = 'Purchase_Fatoora_$cleanId.pdf';
    final title = isArabic
        ? 'طباعة فاتورة شراء #$shortId'
        : 'Print Purchase Invoice #$shortId';

    if (direct) {
      final bytes = await getPurchasePdfBytes(
        purchase: purchase,
        isArabic: isArabic,
      );
      await TahselPrintService.directPrint(bytes: bytes, jobName: title);
    } else {
      await TahselPrintService.openPrintPreview(
        context: context,
        title: title,
        buildPdf: (format) => _buildPurchasePdf(purchase, isArabic),
        pdfFileName: filename,
      );
    }
  }

  static Future<Uint8List> _buildPurchasePdf(
    InventoryPurchaseEntity purchase,
    bool isArabic,
  ) async {
    final pdf = pw.Document();

    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();
    final buyerProfile = await BusinessProfileService.instance.getProfile();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          buildBackground: (context) => pw.Container(color: PdfColors.white),
          margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        ),
        header: (context) =>
            _buildPurchaseHeader(purchase, logoImage, isArabic, buyerProfile),
        footer: (context) => _buildFooter(
          isArabic,
          context.pageNumber,
          context.pagesCount,
          buyerProfile,
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildPurchaseBuyerAndSupplierInfo(purchase, buyerProfile, isArabic),
          pw.SizedBox(height: 10),
          _buildPurchaseItemsTable(purchase, isArabic),
          pw.SizedBox(height: 10),
          _buildPurchaseBottomSection(purchase, isArabic),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPurchaseHeader(
    InventoryPurchaseEntity purchase,
    pw.MemoryImage? logoImage,
    bool isArabic, [
    UserProfileModel? buyerProfile,
  ]) {
    final dateStr = DateFormat(
      isArabic ? "dd MMMM yyyy - hh:mm a" : "MMM dd, yyyy - hh:mm a",
      isArabic ? "ar" : "en",
    ).format(purchase.createdAt);

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? "فاتورة شراء مخزون" : "PURCHASE INVOICE",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _purchasePrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      '# ${purchase.id.replaceAll("pur_", "").toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _purchasePrimaryDark,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (buyerProfile != null &&
                    buyerProfile.projectName.isNotEmpty) ...[
                  pw.Column(
                    crossAxisAlignment: isArabic
                        ? pw.CrossAxisAlignment.start
                        : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        buyerProfile.projectName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _purchasePrimaryDark,
                        ),
                      ),
                      if (buyerProfile.phoneNumber.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          buyerProfile.phoneNumber,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(width: 10),
                ],
                if (logoImage != null)
                  pw.Container(
                    height: 50,
                    constraints: const pw.BoxConstraints(maxWidth: 100),
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    alignment: pw.Alignment.center,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _purchasePrimary, thickness: 1.2),
      ],
    );
  }

  static pw.Widget _buildPurchaseBuyerAndSupplierInfo(
    InventoryPurchaseEntity purchase,
    UserProfileModel? buyerProfile,
    bool isArabic,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Buyer Info (The Business)
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: _purchaseBgLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _purchaseBorder, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic
                      ? "بيانات المشتري (المنشأة):"
                      : "Buyer (Business Details):",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _purchasePrimaryDark,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  buyerProfile != null && buyerProfile.projectName.isNotEmpty
                      ? buyerProfile.projectName
                      : (isArabic ? "النشاط التجاري" : "Business Name"),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _purchasePrimary,
                  ),
                ),
                if (buyerProfile != null &&
                    buyerProfile.fullName.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'المسؤول:' : 'Contact:'} ${buyerProfile.fullName}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (buyerProfile != null &&
                    buyerProfile.phoneNumber.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'الهاتف:' : 'Phone:'} ${buyerProfile.phoneNumber}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (buyerProfile != null && buyerProfile.crn.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'س.ت:' : 'CRN:'} ${buyerProfile.crn}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (buyerProfile != null && buyerProfile.vat.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'الرقم الضريبي:' : 'VAT:'} ${buyerProfile.vat}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
                if (buyerProfile != null &&
                    buyerProfile.address.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "${isArabic ? 'العنوان:' : 'Address:'} ${buyerProfile.address}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        // Supplier Info
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: _purchaseBgLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _purchaseBorder, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isArabic ? "بيانات المورد:" : "Supplier Details:",
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _purchasePrimaryDark,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildPurchasePaymentBadge(
                      purchase.paymentMethod,
                      isArabic,
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  purchase.supplierName.cleanForPdf(
                    isArabic ? "مورد عام" : "General Supplier",
                  ),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPurchasePaymentBadge(
    String paymentMethod,
    bool isArabic,
  ) {
    String text;
    PdfColor color;
    switch (paymentMethod) {
      case 'cash':
        text = isArabic ? "مسدد نقداً" : "Paid Cash";
        color = _success;
        break;
      case 'card':
        text = isArabic ? "مسدد بالبطاقة" : "Paid Card";
        color = _info;
        break;
      case 'debt':
        text = isArabic ? "شراء آجل" : "Credit (Debt)";
        color = _warning;
        break;
      default:
        text = paymentMethod;
        color = _purchasePrimary;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.12),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  static pw.Widget _buildPurchaseItemsTable(
    InventoryPurchaseEntity purchase,
    bool isArabic,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7), // #
        1: const pw.FlexColumnWidth(4.2), // Product Name
        2: const pw.FlexColumnWidth(1.4), // Unit
        3: const pw.FlexColumnWidth(1.2), // Quantity
        4: const pw.FlexColumnWidth(1.7), // Purchase Price
        5: const pw.FlexColumnWidth(1.9), // Total Price
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _purchasePrimary),
          children: [
            _buildTableHeader("#"),
            _buildTableHeader(
              isArabic ? "المنتج / الصنف" : "Product",
              align: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
            _buildTableHeader(isArabic ? "الوحدة" : "Unit"),
            _buildTableHeader(isArabic ? "الكمية" : "Qty"),
            _buildTableHeader(isArabic ? "سعر الشراء" : "Unit Price"),
            _buildTableHeader(isArabic ? "الإجمالي" : "Total"),
          ],
        ),
        // Items
        for (int i = 0; i < purchase.items.length; i++) ...[
          () {
            final item = purchase.items[i];
            final rowColor = i.isEven ? PdfColors.white : PdfColors.grey50;
            final unitText = item.unit != null && item.unit!.trim().isNotEmpty
                ? item.unit!.trim()
                : (isArabic ? "قطعة" : "Pcs");

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: rowColor),
              children: [
                _buildTableCell("${i + 1}", align: pw.TextAlign.center),
                _buildTableCell(
                  item.productName.cleanForPdf(),
                  align: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  isBold: true,
                ),
                _buildTableCell(unitText, align: pw.TextAlign.center),
                _buildTableCell(
                  item.quantity.toSmartAmount(),
                  align: pw.TextAlign.center,
                  isBold: true,
                ),
                _buildTableCell(
                  item.purchasePrice.toSmartAmount(),
                  align: pw.TextAlign.center,
                ),
                _buildTableCell(
                  item.totalPrice.toSmartAmount(),
                  align: pw.TextAlign.center,
                  isBold: true,
                  color: _purchasePrimaryDark,
                ),
              ],
            );
          }(),
        ],
      ],
    );
  }

  static pw.Widget _buildPurchaseBottomSection(
    InventoryPurchaseEntity purchase,
    bool isArabic,
  ) {
    final currency = AppStrings.currencyEgp.tr();
    final totalQty = purchase.items.fold<double>(0.0, (s, i) => s + i.quantity);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Items stats + Notes
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Stats badges box
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isArabic ? "عدد الأصناف:" : "Items Count:",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "${purchase.items.length}",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _purchasePrimary,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      width: 1,
                      height: 24,
                      color: PdfColors.grey300,
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isArabic ? "إجمالي الكمية:" : "Total Qty:",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          totalQty.toSmartAmount(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _purchasePrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (purchase.notes != null &&
                  purchase.notes!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isArabic ? "ملاحظات:" : "Notes:",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                          fontSize: 9,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        purchase.notes!.cleanForPdf(),
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Right side: Financial Summary Card
        pw.Container(
          width: 240,
          decoration: pw.BoxDecoration(
            color: _purchaseBgLight,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _purchaseBorderMedium, width: 1),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                isArabic ? "إجمالي الفاتورة:" : "Total Amount:",
                "${purchase.totalAmount.toSmartAmount()} $currency",
                isBold: true,
                fontSize: 11,
                color: _purchasePrimaryDark,
              ),
              if (purchase.paymentMethod == 'debt') ...[
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? "المدفوع:" : "Paid:",
                  "${purchase.paidAmount.toSmartAmount()} $currency",
                  fontSize: 9.5,
                  color: _success,
                ),
                pw.SizedBox(height: 4),
                pw.Divider(color: _purchaseBorder, thickness: 0.8),
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? "المتبقي للمورد:" : "Remaining Debt:",
                  "${purchase.remainingDebt.toSmartAmount()} $currency",
                  isBold: true,
                  fontSize: 11,
                  color: purchase.remainingDebt <= 0.01 ? _success : _error,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
