import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

/// A reusable tab selector widget styled like DebtsTabSelector.
/// Pass a list of tab labels and get a callback with the selected index.
class InventoryTabSelector extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int index) onTabChanged;

  const InventoryTabSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    return Container(
      height: isDesktop ? 50 : 50.h,
      padding: EdgeInsets.all(isDesktop ? 4 : 4.r),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow,
        borderRadius: BorderRadius.circular(isDesktop ? 25 : 25.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = (constraints.maxWidth) / tabs.length;

          return Stack(
            children: [
              // Animated Indicator
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
                    borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyles.customStyle(
                            fontSize: 14,
                            fontWeight: selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: selectedIndex == index
                                ? AppColors.primaryColor
                                : AppColors.blackLight.withValues(alpha: 0.5),
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
