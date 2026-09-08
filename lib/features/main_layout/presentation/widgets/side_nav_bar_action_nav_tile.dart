import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class SideNavBarActionNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? tag;
  final bool isSelected;
  final VoidCallback onTap;

  const SideNavBarActionNavTile({
    super.key,
    required this.icon,
    required this.label,
    this.tag,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<SideNavBarActionNavTile> createState() =>
      SideNavBarActionNavTileState();
}

class SideNavBarActionNavTileState extends State<SideNavBarActionNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          if (mounted) {
            setState(() {
              _isHovered = hovered;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.1)
                : (_isHovered
                    ? activeColor.withValues(alpha: 0.05)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected ? activeColor : AppColors.blackLight,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyles.customStyle(
                    fontSize: 16,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? activeColor
                        : AppColors.blackLight,
                  ),
                ),
              ),
              if (widget.tag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.vipGoldStart,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    widget.tag!,
                    style: TextStyles.customStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isSelected) const SizedBox(width: 8),
              ],
              if (widget.isSelected)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
