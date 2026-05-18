import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class EmployeeDetailsTabSelector extends StatelessWidget {
  final Function(int index) onTabChanged;
  final int selectedIndex;

  const EmployeeDetailsTabSelector({
    super.key,
    required this.onTabChanged,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final List<Map<String, dynamic>> tabs = [
      {'label': AppStrings.attendance, 'icon': Icons.av_timer_rounded},
      {'label': AppStrings.payroll, 'icon': Icons.payments_rounded},
    ];

    return Container(
      height: isDesktop ? 50.h : 45.h,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 8 : 8.h,
      ),
      padding: EdgeInsets.all(isDesktop ? 4 : 4.r),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: AlignmentDirectional(
                  -1.0 + (selectedIndex * 2 / (tabs.length - 1)),
                  0,
                ),
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.5.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[index]['icon'] as IconData,
                              size: isDesktop ? 18 : 16,
                              color: selectedIndex == index
                                  ? AppColors.primaryColor
                                  : AppColors.blackLight.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (tabs[index]['label'] as String).tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: selectedIndex == index
                                    ? AppColors.primaryColor
                                    : AppColors.blackLight.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
