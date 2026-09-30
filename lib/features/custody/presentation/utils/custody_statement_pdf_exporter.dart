import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/currency_helper.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/features/custody/domain/entities/custody_entity.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';
import 'custody_category_helper.dart';

class CustodyStatementPdfExporter {
  static const PdfColor _navyPrimary = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _blueAccent = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _goldVip = PdfColor.fromInt(0xFFD97706);
  static const PdfColor _greenSuccess = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _redDanger = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _orangeWarning = PdfColor.fromInt(0xFFEA580C);
  static const PdfColor _neutralDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _neutralMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _neutralLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Check whether the current user has report/statement export permission
  static bool hasExportPermission() {
    return PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.reportsExport) ||
        PermissionService.instance.hasPermission(AppPermissions.invoicesPrintShare);
  }

  /// Get public visible storage directory on Android, iOS, Windows
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

  /// Returns the PDF bytes for custody statement
  static Future<Uint8List> getCustodyPdfBytes({
    required CustodyEntity custody,
    required bool isArabic,
  }) async {
    if (!hasExportPermission()) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      throw Exception(AppStrings.noPermissionForAction.tr());
    }

    return await _buildPdf(
      custody: custody,
      isArabic: isArabic,
    );
  }

  /// Print custody statement report directly or open Tahsel themed print preview
  static Future<void> printCustodyStatement(
    BuildContext context, {
    required CustodyEntity custody,
    required bool isArabic,
    bool direct = false,
  }) async {
    if (!hasExportPermission()) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      return;
    }

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Custody_${custody.id}_$nowStr.pdf';
    final title = isArabic
        ? (custody.isSettled ? 'تقرير تسوية عهدة مالية' : 'كشف حساب عهدة مالية')
        : (custody.isSettled ? 'Custody Settlement Report' : 'Custody Statement');

    if (direct) {
      final bytes = await getCustodyPdfBytes(
        custody: custody,
        isArabic: isArabic,
      );
      await TahselPrintService.directPrint(bytes: bytes, jobName: title);
    } else {
      await TahselPrintService.openPrintPreview(
        context: context,
        title: title,
        buildPdf: (format) => _buildPdf(
          custody: custody,
          isArabic: isArabic,
        ),
        pdfFileName: filename,
      );
    }
  }

  /// Generates the PDF and presents the system share/save sheet
  static Future<File> exportAndShare({
    required CustodyEntity custody,
    required bool isArabic,
  }) async {
    if (!hasExportPermission()) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      throw Exception(AppStrings.noPermissionForAction.tr());
    }

    final pdfBytes = await _buildPdf(
      custody: custody,
      isArabic: isArabic,
    );

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Custody_${custody.id}_$nowStr.pdf';

    final dir = await _getPublicStorageDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final subject = isArabic
        ? (custody.isSettled
            ? 'تقرير تسوية عهدة مالية - ${custody.recipientName}'
            : 'كشف حساب عهدة مالية - ${custody.recipientName}')
        : (custody.isSettled
            ? 'Custody Settlement Report - ${custody.recipientName}'
            : 'Custody Statement - ${custody.recipientName}');

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
      } catch (_) {}
    }

    return shareFile;
  }

  static Future<Uint8List> _buildPdf({
    required CustodyEntity custody,
    required bool isArabic,
  }) async {
    final pdf = pw.Document();

    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();
    final profile = await BusinessProfileService.instance.getProfile();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttfRegular,
            bold: ttfBold,
            fontFallback: PdfAssetCache.getFallbackFonts(),
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          margin: const pw.EdgeInsets.all(28),
        ),
        header: (context) => _buildHeader(
          context: context,
          custody: custody,
          logoImage: logoImage,
          isArabic: isArabic,
          profile: profile,
        ),
        footer: (context) => _buildFooter(
          context: context,
          isArabic: isArabic,
          profile: profile,
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildCustodyInfoCards(
            custody: custody,
            isArabic: isArabic,
          ),
          pw.SizedBox(height: 14),
          _buildFinancialSummaryCards(
            custody: custody,
            isArabic: isArabic,
          ),
          if (custody.isSettled) ...[
            pw.SizedBox(height: 14),
            _buildSettlementVarianceCard(
              custody: custody,
              isArabic: isArabic,
            ),
          ],
          if (custody.notes != null && custody.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotesCard(
              notes: custody.notes!.trim(),
              isArabic: isArabic,
            ),
          ],
          pw.SizedBox(height: 16),
          _buildExpensesTable(
            custody: custody,
            isArabic: isArabic,
          ),
          pw.SizedBox(height: 24),
          _buildSignaturesSection(
            custody: custody,
            isArabic: isArabic,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required pw.Context context,
    required CustodyEntity custody,
    pw.MemoryImage? logoImage,
    required bool isArabic,
    UserProfileModel? profile,
  }) {
    final nowStr = DateFormat('yyyy-MM-dd - hh:mm a', 'en').format(DateTime.now());
    final projectName = profile?.projectName.trim() ?? '';
    final hasProject = projectName.isNotEmpty;

    final documentTitle = custody.isSettled
        ? (isArabic ? 'وثيقة تسوية عهدة مالية' : 'Custody Settlement Document')
        : (isArabic ? 'كشف حساب عهدة مالية' : 'Petty Cash Custody Statement');

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
                  width: 48,
                  height: 48,
                  margin: pw.EdgeInsets.only(
                    left: isArabic ? 12 : 0,
                    right: isArabic ? 0 : 12,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    documentTitle,
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: _navyPrimary,
                    ),
                  ),
                  if (hasProject)
                    pw.Text(
                      projectName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _blueAccent,
                      ),
                    ),
                  if (profile?.phoneNumber.trim().isNotEmpty == true)
                    pw.Text(
                      profile!.phoneNumber.trim(),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: _neutralMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: custody.isActive
                      ? const PdfColor.fromInt(0xFFDCFCE7)
                      : const PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(
                    color: custody.isActive ? _greenSuccess : _neutralMuted,
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  custody.isActive
                      ? (isArabic ? 'عهدة نشطة' : 'Active Custody')
                      : (isArabic ? 'تمت التسوية' : 'Settled'),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: custody.isActive ? _greenSuccess : _neutralDark,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${isArabic ? "تاريخ التقرير: " : "Report Date: "}$nowStr',
                style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
              ),
              pw.Text(
                'ID: ${custody.id}',
                style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustodyInfoCards({
    required CustodyEntity custody,
    required bool isArabic,
  }) {
    final typeLabel = custody.recipientType == 'owner'
        ? (isArabic ? 'المالك' : 'Owner')
        : (custody.recipientType == 'employee'
            ? (isArabic ? 'موظف فريق عمل' : 'Team Member')
            : (isArabic ? 'مستلم خارجي' : 'External Person'));

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _neutralLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? 'اسم مستلم العهدة:' : 'Recipient Name:',
                  style: const pw.TextStyle(fontSize: 9.5, color: _neutralMuted),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  custody.recipientName,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _neutralDark,
                  ),
                ),
                pw.Text(
                  typeLabel,
                  style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? 'تاريخ التسليم:' : 'Handover Date:',
                  style: const pw.TextStyle(fontSize: 9.5, color: _neutralMuted),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  DateFormatter.formatDate(custody.createdAt),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _neutralDark,
                  ),
                ),
              ],
            ),
          ),
          if (custody.isSettled) ...[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic ? 'تاريخ التسوية:' : 'Settlement Date:',
                    style: const pw.TextStyle(fontSize: 9.5, color: _neutralMuted),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    custody.settledAt != null
                        ? DateFormatter.formatDate(custody.settledAt!)
                        : '-',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _neutralDark,
                    ),
                  ),
                  if (custody.settledBy != null && custody.settledBy!.isNotEmpty)
                    pw.Text(
                      '${isArabic ? "بواسطة: " : "By: "}${custody.settledBy}',
                      style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFinancialSummaryCards({
    required CustodyEntity custody,
    required bool isArabic,
  }) {
    final bool isDeficit = custody.isDeficit;

    return pw.Row(
      children: [
        // Original Handover Amount
        pw.Expanded(
          child: _buildMetricBox(
            title: isArabic ? 'مبلغ العهدة المسلّم' : 'Initial Handover',
            value: CurrencyHelper.formatCurrency(custody.initialAmount),
            color: _navyPrimary,
            bgTint: const PdfColor.fromInt(0xFFF1F5F9),
          ),
        ),
        pw.SizedBox(width: 8),

        // Total Spent
        pw.Expanded(
          child: _buildMetricBox(
            title: isArabic ? 'إجمالي المنصرف' : 'Total Spent',
            value: CurrencyHelper.formatCurrency(custody.spentAmount),
            color: _orangeWarning,
            bgTint: const PdfColor.fromInt(0xFFFFF7ED),
          ),
        ),
        pw.SizedBox(width: 8),

        // Remaining Balance
        pw.Expanded(
          child: _buildMetricBox(
            title: isDeficit
                ? (isArabic ? 'مستحق للموظف (عجز)' : 'Due to Employee')
                : (isArabic ? 'المتبقي مع المستلم' : 'Remaining Balance'),
            value: CurrencyHelper.formatCurrency(custody.remainingAmount.abs()),
            color: isDeficit ? _redDanger : _greenSuccess,
            bgTint: isDeficit
                ? const PdfColor.fromInt(0xFFFEF2F2)
                : const PdfColor.fromInt(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetricBox({
    required String title,
    required String value,
    required PdfColor color,
    required PdfColor bgTint,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bgTint,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 9,
              color: _neutralMuted,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSettlementVarianceCard({
    required CustodyEntity custody,
    required bool isArabic,
  }) {
    final variance = custody.varianceAmount ?? 0.0;
    final returned = custody.actualSettledAmount ?? 0.0;

    final varianceStatus = variance == 0
        ? (isArabic ? 'متطابق تماماً (تم استرداد كامل المتبقي)' : 'Exact Match (Full balance returned)')
        : variance < 0
            ? '${isArabic ? "عجز تسوية: " : "Deficit: "}${CurrencyHelper.formatCurrency(variance.abs())}'
            : '${isArabic ? "فائض مسترد إضافي: " : "Surplus: "}${CurrencyHelper.formatCurrency(variance)}';

    final varianceColor = variance == 0
        ? _blueAccent
        : variance < 0
            ? _redDanger
            : _greenSuccess;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isArabic ? 'بيانات التسوية النقدية والفارق:' : 'Settlement Cash & Variance:',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _neutralDark,
                ),
              ),
              pw.Text(
                varianceStatus,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: varianceColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(
                '${isArabic ? "المبلغ المسترد نقداً للخزينة: " : "Actual Cash Returned: "}${CurrencyHelper.formatCurrency(returned)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _neutralDark,
                ),
              ),
            ],
          ),
          if (custody.settlementNotes != null && custody.settlementNotes!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              '${isArabic ? "ملاحظات التسوية ومعالجة العجز: " : "Settlement Notes: "}${custody.settlementNotes}',
              style: pw.TextStyle(
                fontSize: 9.5,
                color: _neutralDark,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildNotesCard({
    required String notes,
    required bool isArabic,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFEF3C7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _goldVip, width: 0.6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic ? "ملاحظات العهدة: " : "Custody Notes: ",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF92400E),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              notes,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExpensesTable({
    required CustodyEntity custody,
    required bool isArabic,
  }) {
    final expenses = custody.expenses;

    if (expenses.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 24),
        alignment: pw.Alignment.center,
        child: pw.Text(
          isArabic
              ? 'لم يتم تسجيل أى مصروفات على هذه العهدة حتى الآن'
              : 'No expenses recorded on this custody yet',
          style: const pw.TextStyle(fontSize: 10, color: _neutralMuted),
        ),
      );
    }

    final headers = isArabic
        ? ['#', 'التاريخ والوقت', 'التصنيف', 'البيان والتفاصيل', 'المنفّذ', 'المبلغ']
        : ['#', 'Date & Time', 'Category', 'Description / Statement', 'By', 'Amount'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${isArabic ? "جدول تفاصيل مصروفات العهدة (" : "Itemized Custody Expenses ("}${expenses.length}${isArabic ? " حركة)" : " items)"}',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _neutralDark,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.8),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FlexColumnWidth(2.5),
            4: const pw.FixedColumnWidth(65),
            5: const pw.FixedColumnWidth(65),
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _navyPrimary),
              children: headers.map((h) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    h,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                );
              }).toList(),
            ),

            // Expense Rows
            ...expenses.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final isEven = entry.key % 2 == 0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : _neutralLight,
                ),
                children: [
                  // #
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '$index',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  // Date
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      DateFormatter.formatDateTime(item.date),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.5, color: _neutralDark),
                    ),
                  ),
                  // Category
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      CustodyCategoryHelper.getLocalizedCategoryName(
                        item.category,
                        isArabic: isArabic,
                      ),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _blueAccent,
                      ),
                    ),
                  ),
                  // Description
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                    child: pw.Text(
                      CustodyCategoryHelper.getExpenseDisplayTitle(
                        item,
                        isArabic: isArabic,
                      ),
                      style: const pw.TextStyle(fontSize: 8, color: _neutralDark),
                    ),
                  ),
                  // Employee / Disbursed By
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      item.employeeName ?? '-',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.5, color: _neutralMuted),
                    ),
                  ),
                  // Amount
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      CurrencyHelper.formatCurrency(item.amount),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _orangeWarning,
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _neutralLight),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  child: pw.Text(
                    isArabic ? 'إجمالي المنصرف من العهدة' : 'Total Custody Spent',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _neutralDark,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(''),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    CurrencyHelper.formatCurrency(custody.spentAmount),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _orangeWarning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignaturesSection({
    required CustodyEntity custody,
    required bool isArabic,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                isArabic ? 'توقيع مستلم العهدة' : 'Recipient Signature',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _neutralDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '(${custody.recipientName})',
                style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                '..................................................',
                style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                isArabic ? 'توقيع المسؤول / الاعتماد' : 'Management / Approval',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _neutralDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                custody.settledBy != null && custody.settledBy!.isNotEmpty
                    ? '(${custody.settledBy})'
                    : (isArabic ? '(الإدارة المالية)' : '(Financial Management)'),
                style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                '..................................................',
                style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required bool isArabic,
    UserProfileModel? profile,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isArabic ? 'تم الاستخراج عبر تطبيق تحصيل' : 'Generated by Tahsel App',
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
        ],
      ),
    );
  }
}
