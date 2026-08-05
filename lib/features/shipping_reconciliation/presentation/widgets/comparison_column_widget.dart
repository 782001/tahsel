import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';

class ComparisonColumnWidget extends StatelessWidget {
  final String title;
  final Color color;
  final Map<String, String> dataMap;

  const ComparisonColumnWidget({
    super.key,
    required this.title,
    required this.color,
    required this.dataMap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isDesktop ? 8 : 8.w,
                height: isDesktop ? 8 : 8.h,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: isDesktop ? 6 : 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 12 : 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 8 : 8.h),
          ...dataMap.entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 6 : 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 10 : 10,
                      color: AppColors.sandText,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 11 : 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blackReal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
