import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';

class ReconciliationDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const ReconciliationDataRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 4 : 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 12 : 12,
              color: isBold ? AppColors.blackReal : AppColors.sandText,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 12 : 12,
              color: valueColor ?? AppColors.blackReal,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
