import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class ReportsTimeRangeSelector extends StatefulWidget {
  final Function(int index) onTabChanged;
  final int initialIndex;

  const ReportsTimeRangeSelector({
    super.key,
    required this.onTabChanged,
    this.initialIndex = 0,
  });

  @override
  State<ReportsTimeRangeSelector> createState() => _ReportsTimeRangeSelectorState();
}

class _ReportsTimeRangeSelectorState extends State<ReportsTimeRangeSelector> {
  late int _selectedIndex;
  final List<String> _tabs = [AppStrings.daily, AppStrings.weekly, AppStrings.monthly];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = (constraints.maxWidth) / _tabs.length;
          
          return Stack(
            children: [
              // Animated Indicator with Directional Alignment for RTL support
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: AlignmentDirectional(
                  -1.0 + (_selectedIndex * 2 / (_tabs.length - 1)),
                  0,
                ),
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Interaction Layer
              Row(
                children: List.generate(
                  _tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        widget.onTabChanged(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          _tabs[index].tr(),
                          style: TextStyles.customStyle(
                            fontSize: 14.sp,
                            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.w500,
                            color: _selectedIndex == index ? AppColors.primaryColor : AppColors.blackLight.withOpacity(0.5),
                          ),
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
