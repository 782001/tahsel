import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leadingIcon;
  final VoidCallback? onLeadingTap;

  final Widget? actionIcon;
  final VoidCallback? onActionTap;

  final String? centerLogo;
  final String? centerTitle;
  final Color? backgroundColor;
  final Color? centerTitleColor;

  const CustomAppBar({
    super.key,
    this.leadingIcon,
    this.onLeadingTap,
    this.actionIcon,
    this.onActionTap,
    this.centerLogo,
    this.centerTitle,
    this.backgroundColor,
    this.centerTitleColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.scafoldBackGround,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,

      /// Leading icon
      leading: leadingIcon != null
          ? IconButton(icon: leadingIcon!, onPressed: onLeadingTap)
          : null,

      /// Center logo
      title: centerTitle != null
          ? TextWidget(
              centerTitle!,
              style: TextStyles.font18Weight500Action().copyWith(
                color: centerTitleColor ?? AppColors.textColor,
              ),
            )
          : Image.asset(
              centerLogo!,
              height: 34.h,
              width: 76.32.w,
              fit: BoxFit.fill,
            ),

      /// Action icon
      actions: actionIcon != null
          ? [IconButton(icon: actionIcon!, onPressed: onActionTap)]
          : [],
    );
  }
}
