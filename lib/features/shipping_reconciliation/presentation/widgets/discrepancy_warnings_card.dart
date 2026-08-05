import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';

class DiscrepancyWarningsCard extends StatelessWidget {
  final List<String> discrepancyNotes;

  const DiscrepancyWarningsCard({super.key, required this.discrepancyNotes});

  @override
  Widget build(BuildContext context) {
    if (discrepancyNotes.isEmpty) return const SizedBox.shrink();

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.orange.shade900,
                size: isDesktop ? 20 : 20.r,
              ),
              SizedBox(width: isDesktop ? 8 : 8.w),
              Text(
                AppStrings.discrepancyNotesTitle.tr(),
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 13 : 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 8 : 8.h),
          ...discrepancyNotes.map(
            (note) => Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 4 : 4.h),
              child: Text(
                '• $note',
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 11 : 11,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
