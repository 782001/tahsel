import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/column_concept.dart';
import '../cubit/shipping_reconciliation_cubit.dart';
import '../cubit/shipping_reconciliation_state.dart';

class FileUploadStep extends StatelessWidget {
  const FileUploadStep({super.key});

  Future<void> _pickFile({
    required BuildContext context,
    required bool isInternal,
  }) async {
    final cubit = context.read<ShippingReconciliationCubit>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes =
          file.bytes ??
          (file.path != null ? File(file.path!).readAsBytesSync() : null);

      if (bytes != null) {
        if (isInternal) {
          await cubit.pickInternalFile(bytes: bytes, fileName: file.name);
        } else {
          await cubit.pickShippingFile(bytes: bytes, fileName: file.name);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<
      ShippingReconciliationCubit,
      ShippingReconciliationState
    >(
      builder: (context, state) {
        final loadedState = state is ShippingReconciliationFilesLoaded
            ? state
            : const ShippingReconciliationFilesLoaded();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner with Brand Styling
              Container(
                padding: EdgeInsets.all(isDesktop ? 18 : 14.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 12 : 10.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sync_alt_rounded,
                        color: AppColors.vipGoldStart,
                        size: isDesktop ? 32 : 26.r,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.shippingReportsReconciliation.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            AppStrings.offlineProcessingHint.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 12 : 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isDesktop ? 14 : 14.h),

              // Privacy Notice Banner
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 12.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 12 : 8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: AppColors.primaryColor,
                        size: isDesktop ? 22 : 20.r,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 12.w),
                    Expanded(
                      child: Text(
                        AppStrings.offlinePrivacyNotice.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 12 : 11,
                          color: AppColors.blackReal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isDesktop ? 16 : 16.h),

              // File Pickers Cards
              _buildFileCard(
                context: context,
                title: AppStrings.internalDbFileTitle.tr(),
                subtitle: AppStrings.internalDbFileSubtitle.tr(),
                icon: Icons.storage_rounded,
                fileName: loadedState.internalFile?.fileName,
                rowCount: loadedState.internalFile?.totalRows,
                rawHeaders: loadedState.internalFile?.headers,
                conceptMap:
                    loadedState.internalMapping?.conceptToColumnIndexMap,
                isInternal: true,
                onPick: () => _pickFile(context: context, isInternal: true),
              ),
              SizedBox(height: isDesktop ? 14 : 14.h),
              _buildFileCard(
                context: context,
                title: AppStrings.shippingReportFileTitle.tr(),
                subtitle: AppStrings.shippingReportFileSubtitle.tr(),
                icon: Icons.local_shipping_rounded,
                fileName: loadedState.shippingFile?.fileName,
                rowCount: loadedState.shippingFile?.totalRows,
                rawHeaders: loadedState.shippingFile?.headers,
                conceptMap:
                    loadedState.shippingMapping?.conceptToColumnIndexMap,
                isInternal: false,
                onPick: () => _pickFile(context: context, isInternal: false),
              ),

              SizedBox(height: isDesktop ? 16 : 16.h),

              // Feature Badges Footer Row
              Row(
                children: [
                  _buildFeatureBadge(
                    context: context,
                    icon: Icons.bolt_rounded,
                    label: AppStrings.featureSmartOfflineMatching.tr(),
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: isDesktop ? 12 : 8.w),
                  _buildFeatureBadge(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    label: AppStrings.featurePrivacySecurity100.tr(),
                    color: const Color(0xFF15803D),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8.w),
                  _buildFeatureBadge(
                    context: context,
                    icon: Icons.table_chart_rounded,
                    label: AppStrings.featureExportExcelSheet.tr(),
                    color: const Color(0xFF1D6F42),
                  ),
                ],
              ),

              SizedBox(height: isDesktop ? 24 : 24.h),

              // Action Buttons
              if (loadedState.canProceed) ...[
                if (loadedState.needsMappingReview)
                  Container(
                    margin: EdgeInsets.only(bottom: isDesktop ? 14 : 14.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 10.r,
                      ),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                          size: isDesktop ? 22 : 22.r,
                        ),
                        SizedBox(width: isDesktop ? 12 : 8.w),
                        Expanded(
                          child: Text(
                            AppStrings.columnMappingWarning.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                OutlinedButton.icon(
                  onPressed: () {
                    context
                        .read<ShippingReconciliationCubit>()
                        .openMappingReviewScreen();
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(AppStrings.reviewColumnMapping.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 14 : 14.h,
                    ),
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 12.h),
                ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<ShippingReconciliationCubit>()
                        .startReconciliation();
                  },
                  icon: const Icon(Icons.analytics_rounded),
                  label: Text(AppStrings.startReconciliation.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 14 : 14.h,
                    ),
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 12.h),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required int? rowCount,
    required List<String>? rawHeaders,
    required Map<ColumnConcept, int?>? conceptMap,
    required bool isInternal,
    required VoidCallback onPick,
  }) {
    final isLoaded = fileName != null;
    final successColor = AppColors.success;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isLoaded
              ? successColor
              : AppColors.primaryColor.withValues(alpha: 0.2),
          width: isLoaded ? 1.5 : 1.0,
        ),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isDesktop ? 22 : 22.r,
                  backgroundColor: isLoaded
                      ? successColor.withValues(alpha: 0.15)
                      : AppColors.primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    isLoaded ? Icons.check_circle_rounded : icon,
                    color: isLoaded ? successColor : AppColors.primaryColor,
                    size: isDesktop ? 24 : 24.r,
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 2 : 2.h),
                      Text(
                        subtitle,
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 14 : 14.h),

            if (isLoaded) ...[
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : 12.r),
                decoration: BoxDecoration(
                  color: AppColors.scafoldBackGround,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.sandText.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.fileNameLabel.tr()}: $fileName',
                            style: TextStyles.customStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blackReal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8.w,
                            vertical: isDesktop ? 6 : 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: isDesktop ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '$rowCount ${AppStrings.rowCountUnit.tr()}',
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 8 : 8.h),
                    if (conceptMap != null && rawHeaders != null)
                      Wrap(
                        spacing: isDesktop ? 6 : 6.w,
                        runSpacing: isDesktop ? 6 : 6.h,
                        children: [
                          _buildConceptBadge(
                            AppStrings.conceptOrderNumber.tr(),
                            conceptMap[ColumnConcept.orderNumber] != null
                                ? rawHeaders[conceptMap[ColumnConcept
                                      .orderNumber]!]
                                : null,
                            context,
                          ),
                          _buildConceptBadge(
                            AppStrings.conceptPhone.tr(),
                            conceptMap[ColumnConcept.phone] != null
                                ? rawHeaders[conceptMap[ColumnConcept.phone]!]
                                : null,
                            context,
                          ),
                          _buildConceptBadge(
                            isInternal
                                ? AppStrings.conceptRequiredAmount.tr()
                                : AppStrings.conceptCollectedAmount.tr(),
                            conceptMap[isInternal
                                        ? ColumnConcept.requiredAmount
                                        : ColumnConcept.collectedAmount] !=
                                    null
                                ? rawHeaders[conceptMap[isInternal
                                      ? ColumnConcept.requiredAmount
                                      : ColumnConcept.collectedAmount]!]
                                : null,
                            context,
                          ),
                          _buildConceptBadge(
                            AppStrings.conceptShippingStatus.tr(),
                            conceptMap[ColumnConcept.shippingStatus] != null
                                ? rawHeaders[conceptMap[ColumnConcept
                                      .shippingStatus]!]
                                : null,
                            context,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 10 : 10.h),
            ],

            OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(
                isLoaded
                    ? Icons.published_with_changes_rounded
                    : Icons.upload_file_rounded,
                size: isDesktop ? 20 : 20.r,
              ),
              label: Text(
                isLoaded
                    ? AppStrings.changeFile.tr()
                    : AppStrings.chooseFile.tr(),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLoaded
                      ? AppColors.blackReal
                      : AppColors.primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, isDesktop ? 45 : 44.h),
                foregroundColor: isLoaded
                    ? AppColors.blackReal
                    : AppColors.primaryColor,
                side: BorderSide(
                  color: isLoaded
                      ? AppColors.sandText.withValues(alpha: 0.5)
                      : AppColors.primaryColor,
                  width: isLoaded ? 1 : 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptBadge(
    String label,
    String? mappedHeader,
    BuildContext context,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMapped = mappedHeader != null && mappedHeader.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 8.w,
        vertical: isDesktop ? 4 : 4.h,
      ),
      decoration: BoxDecoration(
        color: isMapped ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isMapped ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Text(
        '$label: ${mappedHeader ?? AppStrings.unspecified.tr()}',
        style: TextStyles.customStyle(
          fontSize: 11,
          color: isMapped ? Colors.green.shade900 : Colors.red.shade900,
          fontWeight: isMapped ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 10 : 8.w,
          vertical: isDesktop ? 10 : 8.h,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isDesktop ? 16 : 14.r, color: color),
            SizedBox(width: isDesktop ? 6 : 6.w),
            Flexible(
              child: Text(
                label,
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 11 : 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
