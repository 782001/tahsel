import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';

import '../../domain/entities/vault_summary_entity.dart';
import '../../domain/entities/vault_transaction_entity.dart';

class VaultPdfExporter {
  static const PdfColor _emeraldPrimary = PdfColor.fromInt(0xFF0D9488);
  static const PdfColor _emeraldDark = PdfColor.fromInt(0xFF115E59);
  static const PdfColor _emeraldLight = PdfColor.fromInt(0xFFCCFBF1);
  static const PdfColor _inflowGreen = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _outflowRed = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _neutralDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _neutralMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _neutralLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

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

    final tahselDir = Directory('${targetDir.path}/Tahsel_Reports');
    if (!await tahselDir.exists()) {
      await tahselDir.create(recursive: true);
    }
    return tahselDir;
  }

  /// Returns the PDF bytes for vault statement
  static Future<Uint8List> getVaultPdfBytes({
    required VaultSummaryEntity summary,
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
    String? filterName,
  }) async {
    return await _buildPdf(
      summary: summary,
      transactions: transactions,
      isArabic: isArabic,
      filterName: filterName,
    );
  }

  /// Print vault statement report directly or open Tahsel themed print preview
  static Future<void> printVaultStatement(
    BuildContext context, {
    required VaultSummaryEntity summary,
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
    String? filterName,
    bool direct = false,
  }) async {
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Vault_Statement_$nowStr.pdf';
    final title = isArabic
        ? 'طباعة تقرير كشف حساب الخزنة'
        : 'Print Vault Statement Report';

    if (direct) {
      final bytes = await getVaultPdfBytes(
        summary: summary,
        transactions: transactions,
        isArabic: isArabic,
        filterName: filterName,
      );
      await TahselPrintService.directPrint(
        bytes: bytes,
        jobName: title,
      );
    } else {
      await TahselPrintService.openPrintPreview(
        context: context,
        title: title,
        buildPdf: (format) => _buildPdf(
          summary: summary,
          transactions: transactions,
          isArabic: isArabic,
          filterName: filterName,
        ),
        pdfFileName: filename,
      );
    }
  }

  /// Generates the PDF and presents the system share/save/print sheet
  static Future<File> exportAndShare({
    required VaultSummaryEntity summary,
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
    String? filterName,
  }) async {
    final pdfBytes = await _buildPdf(
      summary: summary,
      transactions: transactions,
      isArabic: isArabic,
      filterName: filterName,
    );

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Vault_Statement_$nowStr.pdf';

    final dir = await _getPublicStorageDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final subject = isArabic
        ? 'تقرير كشف حساب الخزنة النقدية'
        : 'Cash Vault Statement Report';

    if (!kIsWeb && Platform.isWindows) {
      try {
        await Process.run('cmd', ['/c', 'start', '', shareFile.path]);
      } catch (_) {
        await Process.run('explorer.exe', ['/select,', shareFile.path]);
      }
    } else {
      try {
        await Share.shareXFiles(
          [XFile(shareFile.path, mimeType: 'application/pdf')],
          text: subject,
          subject: subject,
        );
      } catch (_) {
        // Ignored on platforms without share handler
      }
    }

    return shareFile;
  }

  static Future<Uint8List> _buildPdf({
    required VaultSummaryEntity summary,
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
    String? filterName,
  }) async {
    final pdf = pw.Document();

    // Load cached fonts and logo
    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          margin: const pw.EdgeInsets.all(28),
        ),
        header: (context) => _buildHeader(
          context: context,
          logoImage: logoImage,
          isArabic: isArabic,
          filterName: filterName,
        ),
        footer: (context) => _buildFooter(context: context, isArabic: isArabic),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildSummaryCards(
            summary: summary,
            transactions: transactions,
            isArabic: isArabic,
          ),
          pw.SizedBox(height: 18),
          _buildTransactionsTable(
            transactions: transactions,
            isArabic: isArabic,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required pw.Context context,
    pw.MemoryImage? logoImage,
    required bool isArabic,
    String? filterName,
  }) {
    final nowStr = DateFormat(
      'yyyy-MM-dd - hh:mm a',
      'en',
    ).format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 42,
                  height: 42,
                  margin: pw.EdgeInsets.only(
                    left: isArabic ? 10 : 0,
                    right: isArabic ? 0 : 10,
                  ),
                  child: pw.Image(logoImage),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic
                        ? 'كشف حساب الخزنة النقدية'
                        : 'Cash Vault Statement',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _emeraldDark,
                    ),
                  ),
                  if (filterName != null && filterName.isNotEmpty)
                    pw.Text(
                      isArabic ? 'تصفية: $filterName' : 'Filter: $filterName',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: _emeraldPrimary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                isArabic ? 'تاريخ التقرير:' : 'Report Date:',
                style: const pw.TextStyle(fontSize: 10, color: _neutralMuted),
              ),
              pw.Text(
                nowStr,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _neutralDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards({
    required VaultSummaryEntity summary,
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
  }) {
    final currency = AppStrings.currencyEgp.tr();

    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'الرصيد الحالي' : 'Current Balance',
            value: '${summary.currentBalance.toSmartAmount()} $currency',
            bgColor: _emeraldLight,
            textColor: _emeraldDark,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'إجمالي الوارد' : 'Total Inflow',
            value: '+${summary.totalIn.toSmartAmount()} $currency',
            bgColor: const PdfColor.fromInt(0xFFDCFCE7),
            textColor: _inflowGreen,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'إجمالي الصادر' : 'Total Outflow',
            value: '-${summary.totalOut.toSmartAmount()} $currency',
            bgColor: const PdfColor.fromInt(0xFFFEE2E2),
            textColor: _outflowRed,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'عدد الحركات' : 'Transactions',
            value: '${transactions.length}',
            bgColor: _neutralLight,
            textColor: _neutralDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetricTile({
    required String title,
    required String value,
    required PdfColor bgColor,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionsTable({
    required List<VaultTransactionEntity> transactions,
    required bool isArabic,
  }) {
    if (transactions.isEmpty) {
      return pw.Center(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Text(
            isArabic ? 'لا توجد حركات مسجلة' : 'No transactions recorded',
            style: const pw.TextStyle(fontSize: 14, color: _neutralMuted),
          ),
        ),
      );
    }

    final headers = isArabic
        ? [
            'م',
            'التاريخ والوقت',
            'المصدر',
            'البيان',
            'الوارد (+)',
            'الصادر (-)',
          ]
        : [
            '#',
            'Date & Time',
            'Source',
            'Description',
            'Inflow (+)',
            'Outflow (-)',
          ];

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(26),
        1: const pw.FixedColumnWidth(95),
        2: const pw.FixedColumnWidth(75),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(70),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _emeraldLight),
          children: headers.map((h) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _emeraldDark,
                ),
              ),
            );
          }).toList(),
        ),

        // Data Rows
        ...transactions.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final tx = entry.value;
          final isIn = tx.direction == VaultTransactionDirection.inFlow;
          final dateStr = DateFormat(
            'yyyy-MM-dd HH:mm',
            'en',
          ).format(tx.createdAt);
          final sourceLabel = _getSourceName(tx.source, tx.type, isArabic);
          final amountFormatted = tx.amount.toSmartAmount();

          final rowColor = index % 2 == 0 ? _neutralLight : PdfColors.white;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 2,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '$index',
                  style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  dateStr,
                  style: const pw.TextStyle(fontSize: 8, color: _neutralDark),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  sourceLabel,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _emeraldDark,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                alignment: isArabic
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  tx.description.cleanForPdf(),
                  style: const pw.TextStyle(fontSize: 9, color: _neutralDark),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  isIn ? '+$amountFormatted' : '-',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: isIn ? _inflowGreen : _neutralMuted,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  !isIn ? '-$amountFormatted' : '-',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: !isIn ? _outflowRed : _neutralMuted,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static String _getSourceName(
    VaultTransactionSource source,
    String type,
    bool isArabic,
  ) {
    switch (source) {
      case VaultTransactionSource.customerDebt:
        return isArabic ? 'مبيعات / عميل' : 'Customer / Sales';
      case VaultTransactionSource.myDebt:
        return isArabic ? 'سداد مورد' : 'Supplier Payment';
      case VaultTransactionSource.inventory:
        return isArabic ? 'مشتريات مخزون' : 'Inventory Purchase';
      case VaultTransactionSource.employee:
        if (type == 'salary_payment') {
          return isArabic ? 'راتب موظف' : 'Salary';
        }
        if (type == 'employee_advance') {
          return isArabic ? 'سلفة موظف' : 'Advance';
        }
        return isArabic ? 'موظفين' : 'Employee';
      case VaultTransactionSource.expense:
        return isArabic ? 'مصروفات' : 'Expense';
      case VaultTransactionSource.manualDeposit:
        return isArabic ? 'إيداع يدوي' : 'Manual Deposit';
      case VaultTransactionSource.manualWithdrawal:
        return isArabic ? 'سحب يدوي' : 'Manual Withdraw';
      case VaultTransactionSource.all:
        return isArabic ? 'الكل' : 'All';
    }
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required bool isArabic,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isArabic
                ? 'تطبيق تحصيل - نظام إدارة الخزينة'
                : 'Tahsel App - Cash Vault System',
            style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
          ),
          pw.Text(
            isArabic
                ? 'صفحة ${context.pageNumber} من ${context.pagesCount}'
                : 'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
          ),
        ],
      ),
    );
  }
}
