import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/column_concept.dart';

class ColumnMappingCard extends StatelessWidget {
  final ColumnConcept concept;
  final int? mappedColIndex;
  final List<String> rawHeaders;
  final List<List<dynamic>>? sampleRows;
  final Function(int? colIndex) onChanged;

  const ColumnMappingCard({
    super.key,
    required this.concept,
    required this.mappedColIndex,
    required this.rawHeaders,
    this.sampleRows,
    required this.onChanged,
  });

  String _getConceptLabel(ColumnConcept concept) {
    switch (concept) {
      case ColumnConcept.orderNumber:
        return AppStrings.conceptOrderNumber.tr();
      case ColumnConcept.customerName:
        return AppStrings.conceptCustomerName.tr();
      case ColumnConcept.phone:
        return AppStrings.conceptPhone.tr();
      case ColumnConcept.requiredAmount:
        return AppStrings.conceptRequiredAmount.tr();
      case ColumnConcept.collectedAmount:
        return AppStrings.conceptCollectedAmount.tr();
      case ColumnConcept.expectedAmount:
        return AppStrings.conceptExpectedAmount.tr();
      case ColumnConcept.shippingStatus:
        return AppStrings.conceptShippingStatus.tr();
      case ColumnConcept.collectionStatus:
        return AppStrings.conceptCollectionStatus.tr();
      case ColumnConcept.returnStatus:
        return AppStrings.conceptReturnStatus.tr();
      case ColumnConcept.product:
        return AppStrings.conceptProduct.tr();
      case ColumnConcept.governorate:
        return AppStrings.conceptGovernorate.tr();
      case ColumnConcept.address:
        return AppStrings.conceptAddress.tr();
      case ColumnConcept.date:
        return AppStrings.conceptDate.tr();
      case ColumnConcept.unknown:
        return AppStrings.unspecified.tr();
    }
  }

  String _getSamplePreview(int colIndex) {
    if (sampleRows == null || sampleRows!.isEmpty) return '';
    final samples = <String>[];
    for (final row in sampleRows!) {
      if (colIndex < row.length) {
        final val = row[colIndex]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          samples.add(val);
        }
      }
      if (samples.length >= 2) break;
    }
    return samples.isEmpty ? '' : samples.join(', ');
  }

  void _showPickerBottomSheet(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.scafoldBackGround,
            borderRadius: isDesktop
                ? BorderRadius.circular(20.r)
                : BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: EdgeInsets.only(
                  top: isDesktop ? 10 : 10.h,
                  bottom: isDesktop ? 6 : 6.h,
                ),
                width: isDesktop ? 45 : 45.w,
                height: isDesktop ? 5 : 5.h,
                decoration: BoxDecoration(
                  color: AppColors.sandText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 16.w,
                  vertical: isDesktop ? 10 : 10.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.selectColumnFor.tr()} ${_getConceptLabel(concept)}',
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 15 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.primaryColor,
                        size: isDesktop ? 22 : 22.r,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.sandText.withValues(alpha: 0.2),
              ),

              // Column List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(isDesktop ? 16 : 16.r),
                  children: [
                    // Unselect / Not Available Option
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(
                          color: mappedColIndex == null
                              ? AppColors.sandText
                              : AppColors.sandText.withValues(alpha: 0.2),
                        ),
                      ),
                      tileColor: mappedColIndex == null
                          ? AppColors.stitchSurfaceLow
                          : Colors.transparent,
                      leading: Icon(
                        Icons.block_rounded,
                        color: AppColors.sandText,
                        size: isDesktop ? 22 : 22.r,
                      ),
                      title: Text(
                        AppStrings.notAvailableOption.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 13 : 13,
                          color: AppColors.sandText,
                        ),
                      ),
                      trailing: mappedColIndex == null
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap: () {
                        onChanged(null);
                        Navigator.pop(ctx);
                      },
                    ),

                    SizedBox(height: isDesktop ? 10 : 10.h),

                    // Available Headers Options
                    for (int i = 0; i < rawHeaders.length; i++) ...[
                      () {
                        final isSelected = mappedColIndex == i;
                        final headerName = rawHeaders[i].isEmpty
                            ? '${AppStrings.columnUnit.tr()} ${i + 1}'
                            : rawHeaders[i];
                        final sampleText = _getSamplePreview(i);

                        return Container(
                          margin: EdgeInsets.only(bottom: isDesktop ? 8 : 8.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.08)
                                : AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.sandText.withValues(alpha: 0.2),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            leading: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 10 : 10.w,
                                vertical: isDesktop ? 6 : 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '${AppStrings.columnUnit.tr()} ${i + 1}',
                                style: TextStyles.customStyle(
                                  fontSize: isDesktop ? 11 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                            title: Text(
                              headerName,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 14 : 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.blackReal,
                              ),
                            ),
                            subtitle: sampleText.isNotEmpty
                                ? Text(
                                    '${AppStrings.samplePrefix.tr()} $sampleText',
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 11 : 11,
                                      color: AppColors.sandText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
                            onTap: () {
                              onChanged(i);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Padding(padding: const EdgeInsets.all(20), child: content),
            ),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: content,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMapped =
        mappedColIndex != null && mappedColIndex! < rawHeaders.length;
    final isRequired = concept.isRequiredForMatching;

    // Status Colors
    final Color borderColor = isMapped
        ? AppColors.reconciliationMatched
        : (isRequired
              ? Colors.red.shade400
              : AppColors.sandText.withValues(alpha: 0.3));

    final Color bgColor = isMapped
        ? AppColors.reconciliationMatchedBg.withValues(alpha: 0.3)
        : (isRequired
              ? Colors.red.shade50.withValues(alpha: 0.5)
              : Theme.of(context).cardColor);

    final String selectedHeaderText = isMapped
        ? (rawHeaders[mappedColIndex!].isEmpty
              ? '${AppStrings.columnUnit.tr()} ${mappedColIndex! + 1}'
              : rawHeaders[mappedColIndex!])
        : AppStrings.notAvailableOption.tr();

    final String samplePreview = isMapped
        ? _getSamplePreview(mappedColIndex!)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: isMapped ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 14 : 14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concept Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isMapped
                            ? Icons.check_circle_rounded
                            : (isRequired
                                  ? Icons.error_outline_rounded
                                  : Icons.help_outline_rounded),
                        size: isDesktop ? 18 : 18.r,
                        color: isMapped
                            ? AppColors.reconciliationMatched
                            : (isRequired
                                  ? Colors.red.shade700
                                  : AppColors.sandText),
                      ),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                      Flexible(
                        child: Text(
                          _getConceptLabel(concept),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 14 : 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 8.w),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 8.w,
                    vertical: isDesktop ? 3 : 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMapped
                        ? AppColors.reconciliationMatched.withValues(
                            alpha: 0.15,
                          )
                        : (isRequired
                              ? Colors.red.shade100
                              : AppColors.sandText.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    isMapped
                        ? AppStrings.selectedColumnBadge.tr().replaceAll(
                            '{}',
                            '${mappedColIndex! + 1}',
                          )
                        : (isRequired
                              ? AppStrings.requiredForMatchingBadge.tr()
                              : AppStrings.optionalBadge.tr()),

                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 10 : 10,
                      fontWeight: FontWeight.bold,
                      color: isMapped
                          ? AppColors.reconciliationMatched
                          : (isRequired
                                ? Colors.red.shade800
                                : AppColors.sandText),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 10 : 10.h),

            // Interactive Selector Trigger Button
            InkWell(
              onTap: () => _showPickerBottomSheet(context),
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 12.w,
                  vertical: isDesktop ? 10 : 10.h,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 20 : 20.r,
                    ),
                    SizedBox(width: isDesktop ? 10 : 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedHeaderText,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 13 : 13,
                              fontWeight: FontWeight.bold,
                              color: isMapped
                                  ? AppColors.primaryColor
                                  : AppColors.sandText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (samplePreview.isNotEmpty) ...[
                            SizedBox(height: isDesktop ? 2 : 2.h),
                            Text(
                              '${AppStrings.sampleFromFilePrefix.tr()} $samplePreview',
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 11 : 11,
                                color: AppColors.sandText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                      size: isDesktop ? 22 : 22.r,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
