import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class MyDebtDetailsSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const MyDebtDetailsSummaryItem({super.key, 
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.customStyle(
              color: AppColors.whiteOpacity(0.7),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value ${AppStrings.currencyEgp.tr()}',
              style: TextStyles.customStyle(
                color: Colors.white,
                fontSize: isHighlighted ? 16.sp : 14.sp,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
