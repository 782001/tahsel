import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

import 'package:url_launcher/url_launcher.dart';

class TahselPrintPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final String pdfFileName;
  final List<PdfPreviewAction>? actions;
  final bool allowPrinting;
  final bool allowSharing;

  const TahselPrintPreviewScreen({
    super.key,
    required this.title,
    required this.buildPdf,
    required this.pdfFileName,
    this.actions,
    this.allowPrinting = true,
    this.allowSharing = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    required String pdfFileName,
    List<PdfPreviewAction>? actions,
    bool allowPrinting = true,
    bool allowSharing = true,
  }) {
    return open(
      context: context,
      title: title,
      buildPdf: buildPdf,
      pdfFileName: pdfFileName,
      actions: actions,
      allowPrinting: allowPrinting,
      allowSharing: allowSharing,
    );
  }

  static Future<void> open({
    required BuildContext context,
    required String title,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    required String pdfFileName,
    List<PdfPreviewAction>? actions,
    bool allowPrinting = true,
    bool allowSharing = true,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TahselPrintPreviewScreen(
          title: title,
          buildPdf: buildPdf,
          pdfFileName: pdfFileName,
          actions: actions,
          allowPrinting: allowPrinting,
          allowSharing: allowSharing,
        ),
      ),
    );
  }

  Future<void> _openSavedFile(File file, Uint8List bytes) async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final uri = Uri.file(file.path);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      try {
        await Process.run('explorer.exe', [file.path]);
      } catch (_) {}
    } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: title,
        );
      } catch (_) {
        try {
          await Printing.sharePdf(
            bytes: bytes,
            filename: pdfFileName,
            subject: title,
          );
        } catch (_) {}
      }
    } else if (!kIsWeb && Platform.isMacOS) {
      try {
        final uri = Uri.file(file.path);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}
      try {
        await Process.run('open', [file.path]);
      } catch (_) {}
    } else if (!kIsWeb && Platform.isLinux) {
      try {
        final uri = Uri.file(file.path);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}
      try {
        await Process.run('xdg-open', [file.path]);
      } catch (_) {}
    }
  }

  Future<void> _savePdfToStorage(
    BuildContext context,
    PdfPageFormat format,
  ) async {
    try {
      final bytes = await buildPdf(format);

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: pdfFileName,
          subject: title,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.pdfSavedSuccessfully.tr()),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      Directory? targetDir;
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

      targetDir ??= await getApplicationDocumentsDirectory();

      final tahselDir = Directory('${targetDir.path}/Tahsel_Documents');
      if (!await tahselDir.exists()) {
        await tahselDir.create(recursive: true);
      }

      final file = File('${tahselDir.path}/$pdfFileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              '${AppStrings.pdfSavedSuccessfully.tr()}\n${file.path}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Allow gesture lifecycle and frame rendering to cleanly finish before opening external viewer
      await Future.delayed(const Duration(milliseconds: 300));
      await _openSavedFile(file, bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorSavingInvoice.tr()}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    final defaultActions = <PdfPreviewAction>[
      PdfPreviewAction(
        icon: const Icon(Icons.save_alt_rounded),
        onPressed: (ctx, buildFn, format) => _savePdfToStorage(ctx, format),
      ),
      if (actions != null) ...actions!,
    ];

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        title: Text(
          title,
          style: TextStyles.font18Weight500Action().copyWith(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.dividerColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: PdfPreview(
          build: buildPdf,
          initialPageFormat: PdfPageFormat.a4,
          allowPrinting: allowPrinting,
          allowSharing: allowSharing,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          maxPageWidth: 700,
          pdfFileName: pdfFileName,
          actionBarTheme: PdfActionBarTheme(
            backgroundColor: AppColors.surface,
            iconColor: AppColors.primaryColor,
            actionSpacing: 8,
          ),
          scrollViewDecoration: BoxDecoration(
            color: AppColors.scafoldBackGround,
          ),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          onPrinted: (ctx) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(AppStrings.printSuccess.tr()),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          loadingWidget: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 3,
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.loading.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          onError: (context, error) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppStrings.pdfErrorLoading.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: defaultActions,
        ),
      ),
    );
  }
}
