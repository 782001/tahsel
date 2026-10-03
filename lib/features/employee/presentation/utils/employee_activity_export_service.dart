import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/data/datasources/employee_activity_remote_data_source.dart';
import 'package:tahsel/features/employee/data/models/app_employee_model.dart';
import 'package:tahsel/features/employee/domain/entities/employee_activity_entity.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';

import 'activity_field_localizer.dart';

class EmployeeActivityExportService {
  EmployeeActivityExportService._();

  // ── Tahsel Brand Identity Colors ──
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _secondaryColor = PdfColor.fromInt(0xFF2E72CC);
  static const PdfColor _cardTint = PdfColor.fromInt(0xFFD6E4F0);
  static const PdfColor _neutralDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _neutralMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _neutralLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _successColor = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _errorColor = PdfColor.fromInt(0xFFDC2626);

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

  /// Open Modal to choose between PDF or Excel export
  static void showExportOptions(
    BuildContext context, {
    required String title,
    String? subtitle,
    AppEmployeeModel? employee,
    required List<EmployeeActivityEntity> activities,
    required EmployeeActivityStats stats,
    DateTimeRange? dateRange,
  }) {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.noActivitiesToExport.tr(),
            style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    final contentWidget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 20,
        vertical: isDesktop ? 24 : 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGreyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.exportActivityLog.tr(),
            style: TextStyles.customStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.chooseExportFormat.tr()} (${activities.length} ${AppStrings.operationsCount.tr()})',
            style: TextStyles.customStyle(
              fontSize: 12,
              color: AppColors.sandText,
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryColor, size: 24),
            ),
            title: Text(
              AppStrings.pdfPrintReady.tr(),
              style: TextStyles.customStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppStrings.pdfPrintReadyDesc.tr(),
              style: TextStyles.customStyle(fontSize: 11, color: AppColors.sandText),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.pop(context);
              exportPdf(
                context,
                title: title,
                subtitle: subtitle,
                employee: employee,
                activities: activities,
                stats: stats,
                dateRange: dateRange,
              );
            },
          ),
          const Divider(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.table_chart_rounded, color: AppColors.success, size: 24),
            ),
            title: Text(
              AppStrings.excelSheetExport.tr(),
              style: TextStyles.customStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppStrings.excelSheetExportDesc.tr(),
              style: TextStyles.customStyle(fontSize: 11, color: AppColors.sandText),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.pop(context);
              exportExcel(
                context,
                title: title,
                employee: employee,
                activities: activities,
                stats: stats,
                dateRange: dateRange,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Material(
                  color: Colors.transparent,
                  child: contentWidget,
                ),
              ),
            ),
          );
        }
        return contentWidget;
      },
    );
  }

  /// Export Activities as PDF using TahselPrintService
  static Future<void> exportPdf(
    BuildContext context, {
    required String title,
    String? subtitle,
    AppEmployeeModel? employee,
    required List<EmployeeActivityEntity> activities,
    required EmployeeActivityStats stats,
    DateTimeRange? dateRange,
  }) async {
    final currency = CurrencyService.instance.currentSymbol;
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Tahsel_Activity_$nowStr.pdf';

    await TahselPrintService.openPrintPreview(
      context: context,
      title: title,
      buildPdf: (format) => _buildPdfDocument(
        title: title,
        subtitle: subtitle,
        employee: employee,
        activities: activities,
        stats: stats,
        currency: currency,
        dateRange: dateRange,
      ),
      pdfFileName: filename,
    );
  }

  static Future<Uint8List> _buildPdfDocument({
    required String title,
    String? subtitle,
    AppEmployeeModel? employee,
    required List<EmployeeActivityEntity> activities,
    required EmployeeActivityStats stats,
    required String currency,
    DateTimeRange? dateRange,
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
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(24),
        ),
        header: (context) => _buildPdfHeader(
          profile: profile,
          logoImage: logoImage,
          title: title,
          subtitle: subtitle,
          dateRange: dateRange,
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) {
          final List<pw.Widget> content = [];

          // 1. Employee Details Banner (When available)
          content.add(pw.SizedBox(height: 8));
          content.add(_buildPdfEmployeeDetailsCard(employee, activities.firstOrNull));
          content.add(pw.SizedBox(height: 10));

          // 2. KPI Summary Banner
          content.add(_buildPdfKpiSummary(stats, currency, activities.length));
          content.add(pw.SizedBox(height: 14));

          // 3. Activities Detailed Table
          content.add(_buildPdfActivitiesTable(activities, currency));

          return content;
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildPdfHeader({
    required UserProfileModel? profile,
    required pw.MemoryImage? logoImage,
    required String title,
    String? subtitle,
    DateTimeRange? dateRange,
  }) {
    final nowFormatted = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    final periodText = dateRange != null
        ? '${DateFormat('yyyy/MM/dd').format(dateRange.start)} إلى ${DateFormat('yyyy/MM/dd').format(dateRange.end)}'
        : AppStrings.allTime.tr();

    final businessName = (profile?.projectName.isNotEmpty == true)
        ? profile!.projectName
        : ((profile?.fullName.isNotEmpty == true)
            ? profile!.fullName
            : 'تطبيق تحصيل');

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName.cleanForPdf('Tahsel'),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  title.cleanForPdf(),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _neutralDark,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle.cleanForPdf(),
                    style: const pw.TextStyle(fontSize: 10, color: _neutralMuted),
                  ),
                ],
                pw.SizedBox(height: 2),
                pw.Text(
                  '${AppStrings.statementPeriod.tr()}: $periodText | ${AppStrings.exportDate.tr()}: $nowFormatted'.cleanForPdf(),
                  style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
                ),
              ],
            ),
          ),
          if (logoImage != null)
            pw.Container(
              width: 52,
              height: 52,
              child: pw.Image(logoImage),
            ),
        ],
      ),
    );
  }

  /// Employee Information Box in PDF
  static pw.Widget _buildPdfEmployeeDetailsCard(
    AppEmployeeModel? employee,
    EmployeeActivityEntity? fallbackAct,
  ) {
    if (employee != null) {
      final role = ActivityFieldLocalizer.formatRole(employee.rolePreset);
      final status = employee.isActive
          ? AppStrings.accountActiveStatus.tr()
          : AppStrings.accountDisabledStatus.tr();

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _neutralLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _primaryColor, width: 0.8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text(
                    '${AppStrings.appEmployeeNameField.tr()}: ',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                  ),
                  pw.Text(
                    employee.name.cleanForPdf(),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _neutralDark),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Text(
                    '${AppStrings.rolePreset.tr()}: ',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
                  ),
                  pw.Text(
                    role.cleanForPdf(),
                    style: const pw.TextStyle(fontSize: 9, color: _neutralDark),
                  ),
                ],
              ),
            ),
            pw.Row(
              children: [
                pw.Text(
                  '${AppStrings.employeeEmail.tr()}: ',
                  style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
                ),
                pw.Text(
                  employee.email.cleanForPdf(),
                  style: const pw.TextStyle(fontSize: 8.5, color: _neutralDark),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: employee.isActive ? const PdfColor.fromInt(0xFFDCFCE7) : const PdfColor.fromInt(0xFFFEE2E2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: employee.isActive ? _successColor : _errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Team summary banner if no single employee
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _neutralLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${AppStrings.teamActivityLogTitle.tr()}: ${AppStrings.allTeamEmployees.tr()}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _primaryColor),
          ),
          pw.Text(
            AppStrings.teamActivityTimelineDesc.tr(),
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfKpiSummary(
    EmployeeActivityStats stats,
    String currency,
    int loadedCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _cardTint,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _primaryColor, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfKpiItem(AppStrings.totalOperationsStat.tr(), '$loadedCount'),
          _buildPdfKpiItem(
            AppStrings.sales.tr(),
            '${stats.salesCount} (${stats.totalSalesAmount.toStringAsFixed(1)} $currency)',
            valueColor: _successColor,
          ),
          _buildPdfKpiItem(
            AppStrings.expenses.tr(),
            '${stats.expensesCount} (${stats.totalExpensesAmount.toStringAsFixed(1)} $currency)',
            valueColor: _errorColor,
          ),
          _buildPdfKpiItem(AppStrings.categoryDebts.tr(), '${stats.debtsCount}'),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfKpiItem(String title, String value, {PdfColor? valueColor}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? _primaryColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfActivitiesTable(
    List<EmployeeActivityEntity> activities,
    String currency,
  ) {
    final headers = [
      '#',
      AppStrings.dateTimeHeader.tr(),
      AppStrings.appEmployeeNameField.tr(),
      AppStrings.categoryKey.tr(),
      AppStrings.actionTitleHeader.tr(),
      AppStrings.amount.tr(),
      AppStrings.diffAndDetailsHeader.tr(),
      AppStrings.syncTypeHeader.tr(),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FixedColumnWidth(65),
        2: pw.FixedColumnWidth(60),
        3: pw.FixedColumnWidth(48),
        4: pw.FixedColumnWidth(75),
        5: pw.FixedColumnWidth(48),
        6: pw.FlexColumnWidth(2.5),
        7: pw.FixedColumnWidth(42),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryColor),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: pw.Center(
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        ...activities.asMap().entries.map((entry) {
          final i = entry.key;
          final act = entry.value;
          final isEven = i % 2 == 0;
          final dtStr = DateFormat('yyyy-MM-dd HH:mm').format(act.timestamp);
          final amtStr = act.amount != null && act.amount! > 0
              ? '${act.amount!.toStringAsFixed(1)} $currency'
              : '-';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : _neutralLight,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text(dtStr, style: const pw.TextStyle(fontSize: 7.5)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  act.employeeName.cleanForPdf(),
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text(
                    _getCategoryLabel(act.actionCategory).cleanForPdf(),
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  act.actionTitle.cleanForPdf(),
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text(amtStr.cleanForPdf(), style: const pw.TextStyle(fontSize: 7.5)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  act.details.cleanForPdf(),
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Center(
                  child: pw.Text(
                    act.isOfflineSync
                        ? AppStrings.offlineSynced.tr()
                        : AppStrings.directOnline.tr(),
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: act.isOfflineSync ? _secondaryColor : _neutralMuted,
                      fontWeight: act.isOfflineSync ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AppStrings.storeManagementSystem.tr(),
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
          pw.Text(
            AppStrings.pageXOfY.tr(namedArgs: {
              'current': '${context.pageNumber}',
              'total': '${context.pagesCount}',
            }),
            style: const pw.TextStyle(fontSize: 8, color: _neutralMuted),
          ),
        ],
      ),
    );
  }

  /// Export Activities as Excel (XLSX)
  static Future<String?> exportExcel(
    BuildContext context, {
    required String title,
    AppEmployeeModel? employee,
    required List<EmployeeActivityEntity> activities,
    required EmployeeActivityStats stats,
    DateTimeRange? dateRange,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = AppStrings.sheetActivityLog.tr();
      excel.rename('Sheet1', sheetName);

      final sheet = excel[sheetName];
      sheet.isRTL = true;

      // ── Header Styling with Tahsel Brand Colors ──
      const primaryHex = '#1E56A0';
      const tintHex = '#D6E4F0';

      void styleCell(int col, int row, {required String bgHex, required String fontHex, bool bold = false}) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.cellStyle = CellStyle(
          bold: bold,
          backgroundColorHex: ExcelColor.fromHexString(bgHex),
          fontColorHex: ExcelColor.fromHexString(fontHex),
        );
      }

      // Row 0: Report Title Banner
      sheet.appendRow([TextCellValue(AppStrings.activityAuditReport.tr()), TextCellValue('')]);
      styleCell(0, 0, bgHex: primaryHex, fontHex: '#FFFFFF', bold: true);
      styleCell(1, 0, bgHex: primaryHex, fontHex: '#FFFFFF', bold: true);

      // Row 1: Generation Date & Time
      final nowFormatted = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      sheet.appendRow([TextCellValue(AppStrings.exportDate.tr()), TextCellValue(nowFormatted)]);

      // Row 2: Selected Period
      final periodText = dateRange != null
          ? '${DateFormat('yyyy-MM-dd').format(dateRange.start)} -> ${DateFormat('yyyy-MM-dd').format(dateRange.end)}'
          : AppStrings.allTime.tr();
      sheet.appendRow([TextCellValue(AppStrings.statementPeriod.tr()), TextCellValue(periodText)]);

      // Row 3: Employee Details Header
      if (employee != null) {
        final role = ActivityFieldLocalizer.formatRole(employee.rolePreset);
        final status = employee.isActive
            ? AppStrings.accountActiveStatus.tr()
            : AppStrings.accountDisabledStatus.tr();

        sheet.appendRow([
          TextCellValue(AppStrings.employeeCardTitle.tr()),
          TextCellValue(employee.name),
          TextCellValue(role),
          TextCellValue(employee.email),
          TextCellValue(status),
        ]);
        for (var c = 0; c < 5; c++) {
          styleCell(c, 3, bgHex: tintHex, fontHex: primaryHex, bold: true);
        }
      } else {
        sheet.appendRow([
          TextCellValue(AppStrings.teamActivityLogTitle.tr()),
          TextCellValue(AppStrings.allTeamEmployees.tr()),
        ]);
        styleCell(0, 3, bgHex: tintHex, fontHex: primaryHex, bold: true);
        styleCell(1, 3, bgHex: tintHex, fontHex: primaryHex, bold: true);
      }

      // Row 4: Summary KPIs
      sheet.appendRow([
        TextCellValue('${AppStrings.totalOperationsStat.tr()}: ${activities.length}'),
        TextCellValue('${AppStrings.sales.tr()}: ${stats.salesCount} (${stats.totalSalesAmount.toStringAsFixed(1)})'),
        TextCellValue('${AppStrings.expenses.tr()}: ${stats.expensesCount} (${stats.totalExpensesAmount.toStringAsFixed(1)})'),
        TextCellValue('${AppStrings.categoryDebts.tr()}: ${stats.debtsCount}'),
      ]);
      for (var c = 0; c < 4; c++) {
        styleCell(c, 4, bgHex: '#F1F5F9', fontHex: '#334155');
      }

      // Row 5: Blank Spacer Row
      sheet.appendRow([TextCellValue(''), TextCellValue('')]);

      // Row 6: Table Headers
      final List<String> tableHeaders = [
        '#',
        AppStrings.dateColumnHeader.tr(),
        AppStrings.timeColumnHeader.tr(),
        AppStrings.appEmployeeNameField.tr(),
        AppStrings.rolePreset.tr(),
        AppStrings.categoryKey.tr(),
        AppStrings.actionTitleHeader.tr(),
        AppStrings.amount.tr(),
        AppStrings.diffAndDetailsHeader.tr(),
        AppStrings.syncTypeHeader.tr(),
      ];

      const headerRowIndex = 6;
      sheet.appendRow(tableHeaders.map((h) => TextCellValue(h)).toList());

      for (var col = 0; col < tableHeaders.length; col++) {
        final double width = col == 0
            ? 8.0
            : (col == 8 ? 40.0 : (col == 6 ? 28.0 : 18.0));
        sheet.setColumnWidth(col, width);

        styleCell(col, headerRowIndex, bgHex: primaryHex, fontHex: '#FFFFFF', bold: true);
      }

      // Rows 7+: Data rows
      for (var i = 0; i < activities.length; i++) {
        final act = activities[i];
        final dateStr = DateFormat('yyyy-MM-dd').format(act.timestamp);
        final timeStr = DateFormat('HH:mm:ss').format(act.timestamp);

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(dateStr),
          TextCellValue(timeStr),
          TextCellValue(act.employeeName),
          TextCellValue(ActivityFieldLocalizer.formatRole(act.rolePreset)),
          TextCellValue(_getCategoryLabel(act.actionCategory)),
          TextCellValue(act.actionTitle),
          DoubleCellValue(act.amount ?? 0.0),
          TextCellValue(act.details),
          TextCellValue(act.isOfflineSync
              ? AppStrings.offlineSynced.tr()
              : AppStrings.directOnline.tr()),
        ]);

        final rowIndex = headerRowIndex + 1 + i;
        final isEven = i % 2 == 0;
        final rowBgHex = isEven ? '#FFFFFF' : '#F8FAFC';

        for (var c = 0; c < tableHeaders.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex));
          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString(rowBgHex),
          );
        }
      }

      final bytes = excel.save();
      if (bytes == null) {
        AppLogger.printMessage('EmployeeActivityExportService: excel.save() returned null');
        return null;
      }

      final dir = await _getPublicStorageDirectory();
      final fileName =
          'Tahsel_Activity_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.excelExportSuccess.tr(),
                    style: TextStyles.customStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (!kIsWeb && Platform.isWindows) {
        try {
          await Process.run('cmd', ['/c', 'start', '', file.path]);
        } catch (_) {
          try {
            await Process.run('explorer.exe', ['/select,', file.path]);
          } catch (_) {}
        }
      } else {
        try {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: AppStrings.teamActivityLogTitle.tr(),
          );
        } catch (e) {
          AppLogger.printMessage('Share.shareXFiles error: $e');
        }
      }

      return file.path;
    } catch (e) {
      AppLogger.printMessage('EmployeeActivityExportService.exportExcel error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.excelExportError.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  static String _getCategoryLabel(String category) {
    switch (category) {
      case 'sales':
        return AppStrings.categorySales.tr();
      case 'invoices':
        return AppStrings.categoryInvoices.tr();
      case 'debts':
        return AppStrings.categoryDebts.tr();
      case 'expenses':
        return AppStrings.categoryExpenses.tr();
      case 'vault':
        return AppStrings.categoryVault.tr();
      case 'inventory':
        return AppStrings.categoryInventory.tr();
      case 'employees':
        return AppStrings.categoryEmployees.tr();
      case 'reports':
        return AppStrings.categoryReports.tr();
      case 'settings':
        return AppStrings.categorySettings.tr();
      default:
        return AppStrings.all.tr();
    }
  }
}
