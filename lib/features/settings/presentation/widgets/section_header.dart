import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 8.h),
      child: Text(
        title,
        style: TextStyles.customStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor2,
        ),
      ),
    );
  }
}
