import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';
import 'package:tahsel/features/reports/domain/entities/reports_entity.dart';
import 'package:tahsel/features/reports/presentation/widgets/profit_insight_ui_extension.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class FinancialReportPdfExporter {
  static const PdfColor _navyPrimary = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _blueAccent = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _emeraldDark = PdfColor.fromInt(0xFF115E59);
  static const PdfColor _emeraldLight = PdfColor.fromInt(0xFFCCFBF1);
  static const PdfColor _greenSuccess = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _greenLight = PdfColor.fromInt(0xFFDCFCE7);
  static const PdfColor _redDanger = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _redLight = PdfColor.fromInt(0xFFFEE2E2);
  static const PdfColor _orangeWarning = PdfColor.fromInt(0xFFEA580C);
  static const PdfColor _neutralDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _neutralMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _neutralLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Check whether the current user has report export permission
  static bool hasExportPermission() {
    return PermissionService.instance.isOwner ||
        PermissionService.instance.hasPermission(AppPermissions.reportsExport);
  }

  /// Get public visible storage directory
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

  /// Returns the PDF bytes for the financial report
  static Future<Uint8List> getFinancialPdfBytes({
    required ReportsEntity reports,
    required List<ProfitInsight> insights,
    required String periodTitle,
    required DateTime startDate,
    required DateTime endDate,
    required bool isShop,
    required bool isArabic,
  }) async {
    if (!hasExportPermission()) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      throw Exception(AppStrings.noPermissionForAction.tr());
    }

    return await _buildPdf(
      reports: reports,
      insights: insights,
      periodTitle: periodTitle,
      startDate: startDate,
      endDate: endDate,
      isShop: isShop,
      isArabic: isArabic,
    );
  }

  /// Open full-featured Tahsel print preview / share screen
  static Future<void> previewOrPrint({
    required BuildContext context,
    required ReportsEntity reports,
    required List<ProfitInsight> insights,
    required String periodTitle,
    required DateTime startDate,
    required DateTime endDate,
    required bool isShop,
    required bool isArabic,
  }) async {
    if (!hasExportPermission()) {
      showfailureToast(AppStrings.noPermissionForAction.tr());
      return;
    }

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final pdfFileName = 'Tahsel_Financial_Report_$nowStr.pdf';
    final title = isArabic
        ? 'تقرير الأداء المالي'
        : 'Financial Performance Report';

    await TahselPrintService.openPrintPreview(
      context: context,
      title: title,
      pdfFileName: pdfFileName,
      buildPdf: (_) async {
        return await getFinancialPdfBytes(
          reports: reports,
          insights: insights,
          periodTitle: periodTitle,
          startDate: startDate,
          endDate: endDate,
          isShop: isShop,
          isArabic: isArabic,
        );
      },
      allowPrinting: true,
      allowSharing: true,
    );
  }

  /// Export PDF directly and trigger OS share or open
  static Future<File?> exportAndShare({
    required ReportsEntity reports,
    required List<ProfitInsight> insights,
    required String periodTitle,
    required DateTime startDate,
    required DateTime endDate,
    required bool isShop,
    required bool isArabic,
  }) async {
    final pdfBytes = await getFinancialPdfBytes(
      reports: reports,
      insights: insights,
      periodTitle: periodTitle,
      startDate: startDate,
      endDate: endDate,
      isShop: isShop,
      isArabic: isArabic,
    );

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Financial_Report_$nowStr.pdf';

    final dir = await _getPublicStorageDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final subject = isArabic
        ? 'تقرير الأداء المالي - $periodTitle'
        : 'Financial Report - $periodTitle';

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
    required ReportsEntity reports,
    required List<ProfitInsight> insights,
    required String periodTitle,
    required DateTime startDate,
    required DateTime endDate,
    required bool isShop,
    required bool isArabic,
  }) async {
    final pdf = pw.Document();

    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();
    final profile = await BusinessProfileService.instance.getProfile();

    final canViewProfit = PermissionService.instance.hasPermission(
      AppPermissions.reportsViewNetProfit,
    );
    final canViewSales = PermissionService.instance.hasPermission(
      AppPermissions.reportsViewSales,
    );
    final canViewExpenses = PermissionService.instance.hasPermission(
      AppPermissions.expensesView,
    );
    final canViewDebts =
        PermissionService.instance.hasPermission(
          AppPermissions.customersView,
        ) ||
        PermissionService.instance.hasPermission(
          AppPermissions.customersViewReports,
        );
    final canViewInvoices = PermissionService.instance.hasPermission(
      AppPermissions.invoicesView,
    );

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
          profile: profile,
          logoImage: logoImage,
          periodTitle: periodTitle,
          startDate: startDate,
          endDate: endDate,
          isArabic: isArabic,
        ),
        footer: (context) => _buildFooter(context, isArabic),
        build: (context) {
          final List<pw.Widget> content = [];
          content.add(pw.SizedBox(height: 16));
          // 1. Top Summary Metric Cards (Income, Expenses, Net Profit, Operating Margin)
          content.add(
            _buildKpiSummary(
              reports: reports,
              canViewProfit: canViewProfit,
              canViewSales: canViewSales,
              canViewExpenses: canViewExpenses,
              isArabic: isArabic,
            ),
          );
          content.add(pw.SizedBox(height: 16));

          // 2. Debts and Collections (if permitted)
          if (canViewDebts) {
            content.add(
              _buildDebtsSection(reports: reports, isArabic: isArabic),
            );
            content.add(pw.SizedBox(height: 16));
          }

          // 3. Shop Invoices Breakdown (if shop & permitted)
          if (isShop && canViewInvoices) {
            content.add(
              _buildInvoicesSection(reports: reports, isArabic: isArabic),
            );
            content.add(pw.SizedBox(height: 16));
          }

          // 4. Cafe & PlayStation Breakdown (if cafe & permitted)
          if (!isShop && canViewSales) {
            content.add(
              _buildCafePlayStationSection(
                reports: reports,
                isArabic: isArabic,
              ),
            );
            content.add(pw.SizedBox(height: 16));
          }

          // 5. Smart Insights (if profit permitted and available)
          if (canViewProfit && insights.isNotEmpty) {
            content.add(
              _buildInsightsSection(
                insights: insights,
                isShop: isShop,
                isArabic: isArabic,
              ),
            );
          }

          return content;
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeader({
    required UserProfileModel? profile,
    required pw.MemoryImage? logoImage,
    required String periodTitle,
    required DateTime startDate,
    required DateTime endDate,
    required bool isArabic,
  }) {
    final nowStr = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    final rangeStr =
        '${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}';
    final projectName = (profile?.projectName ?? '').cleanForPdf();
    final hasProject = projectName.isNotEmpty;
    final phone = (profile?.phoneNumber ?? '').cleanForPdf();
    final vat = (profile?.vat ?? '').cleanForPdf();
    final cleanPeriodTitle = periodTitle.cleanForPdf();

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
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 44,
                  height: 44,
                  margin: pw.EdgeInsets.only(
                    left: isArabic ? 10 : 0,
                    right: isArabic ? 0 : 10,
                  ),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isArabic
                        ? 'تقرير الأداء المالي'
                        : 'Financial Performance Report',
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: _navyPrimary,
                    ),
                  ),
                  if (hasProject)
                    pw.Text(
                      projectName,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: _blueAccent,
                      ),
                    ),
                  pw.Text(
                    '${isArabic ? 'الفترة:' : 'Period:'} $cleanPeriodTitle ($rangeStr)',
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
              pw.Text(
                '${isArabic ? 'تاريخ الاستخراج:' : 'Generated:'} $nowStr',
                style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
              ),
              if (phone.isNotEmpty)
                pw.Text(
                  phone,
                  style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
                ),
              if (vat.isNotEmpty)
                pw.Text(
                  '${isArabic ? 'الرقم الضريبي:' : 'VAT:'} $vat',
                  style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiSummary({
    required ReportsEntity reports,
    required bool canViewProfit,
    required bool canViewSales,
    required bool canViewExpenses,
    required bool isArabic,
  }) {
    final currency = CurrencyService.instance.currentSymbol
        .cleanForPdf(AppStrings.currencyEgp.tr());
    final List<pw.Widget> tiles = [];

    if (canViewSales) {
      tiles.add(
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'إجمالي المبيعات' : 'Total Sales',
            value: '${reports.totalIncome.toSmartAmount()} $currency',
            bgColor: _greenLight,
            textColor: _greenSuccess,
          ),
        ),
      );
    }

    if (canViewExpenses) {
      if (tiles.isNotEmpty) tiles.add(pw.SizedBox(width: 8));
      tiles.add(
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'إجمالي المصروفات' : 'Total Expenses',
            value: '${reports.totalExpenses.toSmartAmount()} $currency',
            bgColor: _redLight,
            textColor: _redDanger,
          ),
        ),
      );
    }

    if (canViewProfit) {
      if (tiles.isNotEmpty) tiles.add(pw.SizedBox(width: 8));
      tiles.add(
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'صافي الأرباح' : 'Net Profit',
            value: '${reports.netProfit.toSmartAmount()} $currency',
            bgColor: _emeraldLight,
            textColor: _emeraldDark,
          ),
        ),
      );

      final double rawMargin = reports.totalIncome > 0
          ? ((reports.netProfit / reports.totalIncome) * 100)
          : 0.0;
      final double margin = (rawMargin.isNaN || rawMargin.isInfinite)
          ? 0.0
          : rawMargin.clamp(-100.0, 100.0);

      tiles.add(pw.SizedBox(width: 8));
      tiles.add(
        pw.Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'هامش الربح التشغيلي' : 'Operating Margin',
            value: '${margin.toStringAsFixed(1)}%',
            bgColor: _neutralLight,
            textColor: _navyPrimary,
          ),
        ),
      );
    }

    if (tiles.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Row(children: tiles);
  }

  static pw.Widget _buildDebtsSection({
    required ReportsEntity reports,
    required bool isArabic,
  }) {
    final currency = CurrencyService.instance.currentSymbol
        .cleanForPdf(AppStrings.currencyEgp.tr());

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _neutralLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic
                ? 'موقف الديون والمستحقات للعملاء'
                : 'Customer Debts & Receivables',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _navyPrimary,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'الديون غير المسددة' : 'Unpaid Receivables',
                  value: '${reports.unpaidDebts.toSmartAmount()} $currency',
                  textColor: _redDanger,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'الديون المحصلة' : 'Collected Debts',
                  value: '${reports.paidDebts.toSmartAmount()} $currency',
                  textColor: _greenSuccess,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'إجمالي الديون المسجلة' : 'Total Debts',
                  value: '${reports.totalDebts.toSmartAmount()} $currency',
                  textColor: _navyPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoicesSection({
    required ReportsEntity reports,
    required bool isArabic,
  }) {
    final currency = CurrencyService.instance.currentSymbol
        .cleanForPdf(AppStrings.currencyEgp.tr());

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _neutralLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isArabic
                    ? 'ملخص حركة فواتير المبيعات'
                    : 'Sales Invoices Summary',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _navyPrimary,
                ),
              ),
              pw.Text(
                '${isArabic ? 'إجمالي الفواتير:' : 'Total Invoices:'} ${reports.invoiceCount}',
                style: const pw.TextStyle(fontSize: 9, color: _neutralMuted),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'قيمة الفواتير' : 'Invoices Value',
                  value: '${reports.invoiceValue.toSmartAmount()} $currency',
                  textColor: _blueAccent,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'المحصل' : 'Collected',
                  value:
                      '${reports.invoiceCollected.toSmartAmount()} $currency',
                  textColor: _greenSuccess,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'المتبقي' : 'Remaining',
                  value:
                      '${reports.invoiceRemaining.toSmartAmount()} $currency',
                  textColor: _orangeWarning,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'فواتير مسددة بالكامل' : 'Paid Invoices',
                  value: '${reports.invoicePaidCount}',
                  textColor: _greenSuccess,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'فواتير مسددة جزئياً' : 'Partially Paid',
                  value: '${reports.invoicePartialCount}',
                  textColor: _orangeWarning,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildSubMetric(
                  title: isArabic ? 'فواتير غير مسددة' : 'Unpaid Invoices',
                  value: '${reports.invoiceUnpaidCount}',
                  textColor: _redDanger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCafePlayStationSection({
    required ReportsEntity reports,
    required bool isArabic,
  }) {
    final currency = CurrencyService.instance.currentSymbol
        .cleanForPdf(AppStrings.currencyEgp.tr());

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _neutralLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _border, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? 'إيرادات الكافيه' : 'Cafe Revenue',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPrimary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${reports.cafeIncome.toSmartAmount()} $currency',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _blueAccent,
                  ),
                ),
                pw.Text(
                  '${isArabic ? 'عدد الطلبات:' : 'Orders:'} ${reports.cafeCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _neutralLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: _border, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isArabic ? 'إيرادات البلايستيشن' : 'PlayStation Revenue',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPrimary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${reports.playstationIncome.toSmartAmount()} $currency',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _blueAccent,
                  ),
                ),
                pw.Text(
                  '${isArabic ? 'عدد الجلسات:' : 'Sessions:'} ${reports.playstationCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInsightsSection({
    required List<ProfitInsight> insights,
    required bool isShop,
    required bool isArabic,
  }) {
    final validInsights = insights.where((insight) {
      if (isShop) {
        final key = insight.messageKey.toLowerCase();
        if (key.contains('ps') || key.contains('playstation')) return false;
      }
      final msg = insight.getMessage(isShop).cleanForPdf();
      return msg.isNotEmpty;
    }).toList();

    if (validInsights.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF1F5F9),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isArabic
                ? 'التحليلات والمقارنة الذكية'
                : 'Smart Analytics & Insights',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _navyPrimary,
            ),
          ),
          pw.SizedBox(height: 8),
          ...validInsights.take(5).map((insight) {
            final cleanMessage = insight.getMessage(isShop).cleanForPdf();

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 4.5,
                    height: 4.5,
                    margin: pw.EdgeInsets.only(
                      top: 4,
                      left: isArabic ? 6 : 0,
                      right: isArabic ? 0 : 6,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: _blueAccent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      cleanMessage,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: _neutralDark,
                        lineSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricTile({
    required String title,
    required String value,
    required PdfColor bgColor,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title.cleanForPdf(),
            maxLines: 1,
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value.cleanForPdf(),
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSubMetric({
    required String title,
    required String value,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title.cleanForPdf(),
            maxLines: 1,
            style: const pw.TextStyle(fontSize: 7, color: _neutralMuted),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value.cleanForPdf(),
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, bool isArabic) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isArabic
                ? 'تم إنشاء هذا التقرير تلقائياً بواسطة تطبيق تحصيل'
                : 'Generated automatically by Tahsel App',
            style: const pw.TextStyle(fontSize: 7, color: _neutralMuted),
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
