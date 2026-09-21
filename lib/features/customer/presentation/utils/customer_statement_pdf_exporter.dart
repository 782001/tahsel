import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/pdf_asset_cache.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/services/tahsel_print_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/domain/entities/customer_operation.dart';
import 'package:tahsel/features/customer/presentation/utils/customer_operation_display_helper.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_share2/whatsapp_share2.dart';

class CustomerStatementPdfExporter {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1E56A0);
  static const PdfColor _primaryDark = PdfColor.fromInt(0xFF061A35);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFD6E4F0);
  static const PdfColor _debitRed = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _creditGreen = PdfColor.fromInt(0xFF16A34A);
  static const PdfColor _neutralDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _neutralMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _neutralLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Normalizes Arabic-Indic digits (٠-٩) to standard ASCII digits (0-9)
  static String _normalizePhone(String phone) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const englishDigits = '0123456789';
    String result = phone;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result;
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

    final tahselDir = Directory('${targetDir.path}/Tahsel_Statements');
    if (!await tahselDir.exists()) {
      await tahselDir.create(recursive: true);
    }
    return tahselDir;
  }

  /// Returns raw PDF bytes for customer statement
  static Future<Uint8List> getStatementPdfBytes({
    required String customerName,
    required CustomerEntity? customer,
    required List<CustomerOperation> operations,
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    String? periodTitle,
  }) async {
    return await _buildPdf(
      customerName: customerName,
      customer: customer,
      operations: operations,
      openingBalance: openingBalance,
      totalSpent: totalSpent,
      totalPaid: totalPaid,
      remaining: remaining,
      isArabic: isArabic,
      periodTitle: periodTitle,
    );
  }

  /// Print statement or open Tahsel print preview
  static Future<void> printStatement(
    BuildContext context, {
    required String customerName,
    required CustomerEntity? customer,
    required List<CustomerOperation> operations,
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    String? periodTitle,
    bool direct = false,
  }) async {
    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName = customerName.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
    final filename = 'Tahsel_Statement_${sanitizedName}_$nowStr.pdf';
    final title = AppStrings.statementOfAccountFor.tr().replaceAll('{name}', customerName);

    if (direct) {
      final bytes = await getStatementPdfBytes(
        customerName: customerName,
        customer: customer,
        operations: operations,
        openingBalance: openingBalance,
        totalSpent: totalSpent,
        totalPaid: totalPaid,
        remaining: remaining,
        isArabic: isArabic,
        periodTitle: periodTitle,
      );
      await TahselPrintService.directPrint(bytes: bytes, jobName: title);
    } else {
      await TahselPrintService.openPrintPreview(
        context: context,
        title: title,
        buildPdf: (format) => _buildPdf(
          customerName: customerName,
          customer: customer,
          operations: operations,
          openingBalance: openingBalance,
          totalSpent: totalSpent,
          totalPaid: totalPaid,
          remaining: remaining,
          isArabic: isArabic,
          periodTitle: periodTitle,
        ),
        pdfFileName: filename,
      );
    }
  }

  /// Export PDF and share via system share sheet / open Windows folder
  static Future<File> exportAndShare({
    required String customerName,
    required CustomerEntity? customer,
    required List<CustomerOperation> operations,
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    String? periodTitle,
  }) async {
    final pdfBytes = await _buildPdf(
      customerName: customerName,
      customer: customer,
      operations: operations,
      openingBalance: openingBalance,
      totalSpent: totalSpent,
      totalPaid: totalPaid,
      remaining: remaining,
      isArabic: isArabic,
      periodTitle: periodTitle,
    );

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName = customerName.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
    final filename = 'Tahsel_Statement_${sanitizedName}_$nowStr.pdf';

    final dir = await _getPublicStorageDirectory();
    final shareFile = File('${dir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final subject = AppStrings.statementOfAccountFor.tr().replaceAll('{name}', customerName);

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

  /// Send PDF or text statement summary via WhatsApp directly to customer
  static Future<void> shareViaWhatsApp({
    required String customerName,
    required CustomerEntity? customer,
    required List<CustomerOperation> operations,
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    String? periodTitle,
  }) async {
    final rawPhone = customer?.phoneNumber?.trim() ?? '';
    final normalizedPhone = _normalizePhone(rawPhone);
    final formattedPhone = normalizedPhone.isNotEmpty ? normalizedPhone.toWhatsAppFormat() : '';

    final pdfBytes = await _buildPdf(
      customerName: customerName,
      customer: customer,
      operations: operations,
      openingBalance: openingBalance,
      totalSpent: totalSpent,
      totalPaid: totalPaid,
      remaining: remaining,
      isArabic: isArabic,
      periodTitle: periodTitle,
    );

    final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName = customerName.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
    final filename = 'Statement_${sanitizedName}_$nowStr.pdf';

    final tempDir = await getTemporaryDirectory();
    final shareFile = File('${tempDir.path}/$filename');
    await shareFile.writeAsBytes(pdfBytes);

    final currency = AppStrings.currencyEgp.tr();
    final statusText = remaining > 0
        ? '${AppStrings.customerDebitStatus.tr()}: ${remaining.toSmartAmount()} $currency'
        : remaining == 0
            ? AppStrings.accountSettled.tr()
            : '${AppStrings.customerCreditStatus.tr()}: ${(-remaining).toSmartAmount()} $currency';

    final message = AppStrings.customerStatementWhatsappMessage
        .tr()
        .replaceAll('{name}', customerName)
        .replaceAll('{balance}', statusText);

    if (formattedPhone.isNotEmpty) {
      try {
        await WhatsappShare.shareFile(
          text: message,
          phone: formattedPhone,
          filePath: [shareFile.path],
        );
        return;
      } catch (_) {}

      // Fallback via URL launcher with message
      try {
        final whatsappUrl = Uri.parse(
          'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    // System share fallback
    try {
      await Share.shareXFiles(
        [XFile(shareFile.path, mimeType: 'application/pdf')],
        text: message,
      );
    } catch (_) {}
  }

  // ── PDF Generation ──

  static Future<Uint8List> _buildPdf({
    required String customerName,
    required CustomerEntity? customer,
    required List<CustomerOperation> operations,
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    String? periodTitle,
  }) async {
    final pdf = pw.Document();

    final ttfRegular = await PdfAssetCache.getRegularFont();
    final ttfBold = await PdfAssetCache.getBoldFont();
    final logoImage = await PdfAssetCache.getLogoImage();
    final profile = await BusinessProfileService.instance.getProfile();

    // Sort operations chronologically for the printed statement ledger with tie-breaker
    final chronologicalOps = List<CustomerOperation>.from(operations)
      ..sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        if (a.type != b.type) {
          if (a.type == CustomerOperationType.payment) return 1;
          if (b.type == CustomerOperationType.payment) return -1;
        }
        return 0;
      });

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
          margin: const pw.EdgeInsets.all(24),
        ),
        header: (context) {
          if (context.pageNumber > 1) {
            return _buildCompactHeader(
              customerName: customerName,
              periodTitle: periodTitle,
              isArabic: isArabic,
            );
          }
          return pw.SizedBox.shrink();
        },
        footer: (context) => _buildFooter(
          context: context,
          isArabic: isArabic,
          profile: profile,
        ),
        build: (context) {
          final hasSettlement = chronologicalOps.any((op) => op.isSettlement);
          final totalPaidToCustomer = chronologicalOps
              .where((op) => op.isSettlement)
              .fold<double>(0.0, (sum, op) => sum + op.amount.abs());

          return [
            _buildHeader(
              context: context,
              logoImage: logoImage,
              isArabic: isArabic,
              profile: profile,
              customerName: customerName,
              customer: customer,
              periodTitle: periodTitle,
            ),
            pw.SizedBox(height: 10),
            _buildSummaryCards(
              openingBalance: openingBalance,
              totalSpent: totalSpent,
              totalPaid: totalPaid,
              remaining: remaining,
              isArabic: isArabic,
              totalPaidToCustomer: totalPaidToCustomer,
            ),
            pw.SizedBox(height: 14),
            _buildLedgerTable(
              operations: chronologicalOps,
              openingBalance: openingBalance,
              isArabic: isArabic,
              hasSettlement: hasSettlement,
            ),
            pw.SizedBox(height: 16),
            pw.Wrap(
              children: [
                _buildSignaturesAndNotice(isArabic: isArabic),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCompactHeader({
    required String customerName,
    String? periodTitle,
    required bool isArabic,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${AppStrings.customerAccountStatement.tr()}: ${customerName.cleanForPdf()}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          if (periodTitle != null && periodTitle.isNotEmpty)
            pw.Text(
              periodTitle.cleanForPdf(),
              style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader({
    required pw.Context context,
    pw.MemoryImage? logoImage,
    required bool isArabic,
    UserProfileModel? profile,
    required String customerName,
    required CustomerEntity? customer,
    String? periodTitle,
  }) {
    final nowStr = DateFormat('yyyy-MM-dd - hh:mm a', 'en').format(DateTime.now());
    final projectName = profile?.projectName.trim() ?? '';
    final hasProject = projectName.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1.5)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store details & logo
              pw.Row(
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
                    crossAxisAlignment: isArabic
                        ? pw.CrossAxisAlignment.end
                        : pw.CrossAxisAlignment.start,
                    children: [
                      if (hasProject)
                        pw.Text(
                          projectName.cleanForPdf(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      if (profile != null && profile.phoneNumber.isNotEmpty)
                        pw.Text(
                          profile.phoneNumber.cleanForPdf(),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: _neutralMuted,
                          ),
                        ),
                      if (profile != null && profile.vat.isNotEmpty)
                        pw.Text(
                          '${AppStrings.taxNumber.tr()}: ${profile.vat.cleanForPdf()}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: _neutralMuted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Document title & date
              pw.Column(
                crossAxisAlignment: isArabic
                    ? pw.CrossAxisAlignment.start
                    : pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _primary,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      AppStrings.customerAccountStatement.tr(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    nowStr,
                    style: const pw.TextStyle(fontSize: 8.5, color: _neutralMuted),
                  ),
                  if (periodTitle != null && periodTitle.isNotEmpty)
                    pw.Text(
                      '${AppStrings.statementPeriod.tr()}: ${periodTitle.cleanForPdf()}',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Customer details box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _neutralLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _border),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      '${AppStrings.customerName.tr()}: ',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _neutralMuted,
                      ),
                    ),
                    pw.Text(
                      customerName.cleanForPdf(),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _neutralDark,
                      ),
                    ),
                  ],
                ),
                if (customer?.phoneNumber != null &&
                    customer!.phoneNumber!.isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Text(
                        '${AppStrings.phone.tr()}: ',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralMuted,
                        ),
                      ),
                      pw.Text(
                        customer.phoneNumber!.cleanForPdf(),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralDark,
                        ),
                      ),
                    ],
                  ),
                if (customer?.ledgerNumber != null &&
                    customer!.ledgerNumber!.isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Text(
                        '${AppStrings.ledgerNumber.tr()}: ',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralMuted,
                        ),
                      ),
                      pw.Text(
                        customer.ledgerNumber!.cleanForPdf(),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralDark,
                        ),
                      ),
                    ],
                  ),
                if (customer?.taxNumber != null &&
                    customer!.taxNumber!.isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Text(
                        '${AppStrings.taxNumber.tr()}: ',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralMuted,
                        ),
                      ),
                      pw.Text(
                        customer.taxNumber!.cleanForPdf(),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _neutralDark,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCards({
    required double openingBalance,
    required double totalSpent,
    required double totalPaid,
    required double remaining,
    required bool isArabic,
    double totalPaidToCustomer = 0.0,
  }) {
    final currency = AppStrings.currencyEgp.tr();

    final PdfColor statusColor = remaining > 0
        ? _debitRed
        : remaining == 0
            ? _creditGreen
            : _primary;

    final String statusLabel = remaining > 0
        ? AppStrings.customerDebitStatus.tr()
        : remaining == 0
            ? AppStrings.accountSettled.tr()
            : AppStrings.customerCreditStatus.tr();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _neutralLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          if (openingBalance != 0.0) ...[
            _buildStatCell(
              title: AppStrings.openingBalance.tr(),
              value: '${openingBalance.toSmartAmount()} $currency',
              color: _neutralDark,
            ),
            pw.Container(width: 1, height: 28, color: _border),
          ],
          _buildStatCell(
            title: AppStrings.totalPurchases.tr(),
            value: '${totalSpent.toSmartAmount()} $currency',
            color: _primary,
          ),
          pw.Container(width: 1, height: 28, color: _border),
          _buildStatCell(
            title: AppStrings.totalPaid.tr(),
            value: '${totalPaid.toSmartAmount()} $currency',
            color: _creditGreen,
          ),
          pw.Container(width: 1, height: 28, color: _border),
          if (totalPaidToCustomer > 0) ...[
            _buildStatCell(
              title: AppStrings.paidToCustomer.tr(),
              value: '${totalPaidToCustomer.toSmartAmount()} $currency',
              color: PdfColors.amber800,
              isBold: true,
            ),
            pw.Container(width: 1, height: 28, color: _border),
          ],
          _buildStatCell(
            title: statusLabel,
            value: '${remaining.abs().toSmartAmount()} $currency',
            color: statusColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCell({
    required String title,
    required String value,
    required PdfColor color,
    bool isBold = false,
  }) {
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
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLedgerTable({
    required List<CustomerOperation> operations,
    required double openingBalance,
    required bool isArabic,
    bool hasSettlement = false,
  }) {
    final currency = AppStrings.currencyEgp.tr();

    final List<String> headers = [
      '#',
      AppStrings.dateLabel.tr(),
      AppStrings.transactionType.tr(),
      AppStrings.notes.tr(),
      AppStrings.debitAmount.tr(),
      AppStrings.creditAmount.tr(),
      if (hasSettlement) AppStrings.paidToCustomer.tr(),
      AppStrings.runningBalance.tr(),
    ];

    if (operations.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        child: pw.Text(
          AppStrings.noData.tr(),
          style: const pw.TextStyle(fontSize: 11, color: _neutralMuted),
        ),
      );
    }

    final tableRows = <pw.TableRow>[];

    // Table Header
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primaryLight),
        children: headers
            .map(
              (h) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryDark,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    // If there is an opening balance, add an opening balance row
    if (openingBalance != 0.0) {
      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.amber50),
          children: [
            _tableCell('-', align: pw.Alignment.center),
            _tableCell('-', align: pw.Alignment.center),
            _tableCell(
              AppStrings.openingBalance.tr(),
              isBold: true,
              color: _neutralDark,
            ),
            _tableCell(AppStrings.openingBalance.tr()),
            _tableCell(
              openingBalance > 0 ? openingBalance.toSmartAmount() : '-',
              align: pw.Alignment.center,
              color: _debitRed,
            ),
            _tableCell(
              openingBalance < 0 ? (-openingBalance).toSmartAmount() : '-',
              align: pw.Alignment.center,
              color: _creditGreen,
            ),
            if (hasSettlement)
              _tableCell('-', align: pw.Alignment.center),
            _tableCell(
              '${openingBalance.toSmartAmount()} $currency',
              align: pw.Alignment.center,
              isBold: true,
              color: _primaryDark,
            ),
          ],
        ),
      );
    }

    // Populate rows
    for (int i = 0; i < operations.length; i++) {
      final op = operations[i];
      final isEven = i % 2 == 0;
      final dateStr = DateFormat('yyyy-MM-dd').format(op.date);

      final isSettlement = op.isSettlement;
      final isPayment = op.type == CustomerOperationType.payment && !isSettlement;
      final isQuotation = op.type == CustomerOperationType.quotation;

      final debitStr = (!isPayment && !isQuotation && !isSettlement)
          ? op.amount.abs().toSmartAmount()
          : '-';
      final creditStr = isPayment ? op.amount.abs().toSmartAmount() : '-';
      final paidToCustomerStr = isSettlement ? op.amount.abs().toSmartAmount() : '-';
      final String typeLabel = op.localizedTitle;

      final detailsStr = op.details ?? op.referenceNumber ?? '-';

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.white : _neutralLight,
          ),
          children: [
            _tableCell('${i + 1}', align: pw.Alignment.center),
            _tableCell(dateStr, align: pw.Alignment.center),
            _tableCell(
              typeLabel,
              isBold: true,
              color: isSettlement
                  ? PdfColors.amber800
                  : (isPayment ? _creditGreen : _primaryDark),
            ),
            _tableCell(detailsStr),
            _tableCell(
              debitStr,
              align: pw.Alignment.center,
              color: debitStr != '-' ? _debitRed : _neutralMuted,
            ),
            _tableCell(
              creditStr,
              align: pw.Alignment.center,
              color: creditStr != '-' ? _creditGreen : _neutralMuted,
            ),
            if (hasSettlement)
              _tableCell(
                paidToCustomerStr,
                align: pw.Alignment.center,
                isBold: isSettlement,
                color: paidToCustomerStr != '-' ? PdfColors.amber800 : _neutralMuted,
              ),
            _tableCell(
              '${op.runningBalance.toSmartAmount()} $currency',
              align: pw.Alignment.center,
              isBold: true,
              color: op.runningBalance > 0
                  ? _debitRed
                  : op.runningBalance == 0
                      ? _creditGreen
                      : _primary,
            ),
          ],
        ),
      );
    }

    final columnWidths = hasSettlement
        ? const <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(18),
            1: pw.FixedColumnWidth(50),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FlexColumnWidth(1.8),
            4: pw.FlexColumnWidth(1.1),
            5: pw.FlexColumnWidth(1.1),
            6: pw.FlexColumnWidth(1.1),
            7: pw.FlexColumnWidth(1.3),
          }
        : const <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(22),
            1: pw.FixedColumnWidth(55),
            2: pw.FlexColumnWidth(1.8),
            3: pw.FlexColumnWidth(2.0),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(1.2),
            6: pw.FlexColumnWidth(1.5),
          };

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    bool isBold = false,
    PdfColor color = _neutralDark,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
      alignment: align,
      child: pw.Text(
        text.cleanForPdf(),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildSignaturesAndNotice({required bool isArabic}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Legal acknowledgement notice
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _neutralLight,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _border, width: 0.5),
          ),
          child: pw.Text(
            AppStrings.statementNoticeText.tr(),
            style: const pw.TextStyle(
              fontSize: 8,
              color: _neutralMuted,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 18),
        // Signatures
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppStrings.accountantSignature.tr(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _neutralDark,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 140,
                  height: 0.8,
                  color: _neutralMuted,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppStrings.customerSignature.tr(),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _neutralDark,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 140,
                  height: 0.8,
                  color: _neutralMuted,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required bool isArabic,
    UserProfileModel? profile,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            (profile?.projectName ?? 'Tahsel System').cleanForPdf(),
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
