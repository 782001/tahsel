import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';

class AuthTextFormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType textInputType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? suffixTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? hintText;
  final double height;
  final double borderRadius;
  final Function(String)? onChanged;
  final Color? suffixIconColor;
  final int? maxLines;
  final FocusNode? focusNode;
  final Widget? headerTrailingWidget;

  const AuthTextFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.textInputType,
    this.obscureText = false,
    this.suffixIcon,
    this.suffixTap,
    this.validator,
    this.enabled = true,
    this.hintText,
    this.height = 55.0,
    this.borderRadius = 14.0,
    this.onChanged,
    this.suffixIconColor,
    this.maxLines = 1,
    this.focusNode,
    this.headerTrailingWidget,
  });

  @override
  State<AuthTextFormField> createState() => _AuthTextFormFieldState();
}

class _AuthTextFormFieldState extends State<AuthTextFormField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.headerTrailingWidget != null) widget.headerTrailingWidget!,
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextWidget(
                  widget.label,
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.textInputType,
              obscureText: _obscureText,
              enabled: widget.enabled,
              onChanged: widget.onChanged,
              maxLines: widget.maxLines,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyles.font14Weight400RightAligned().copyWith(
                  color: AppColors.textColor2,
                ),
                filled: true,
                fillColor: AppColors.textColor.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14.h,
                  horizontal: 16.w,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  borderSide: BorderSide(color: Colors.redAccent, width: 1.w),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  borderSide: BorderSide(color: Colors.redAccent, width: 1.w),
                ),
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: widget.suffixIconColor ?? Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(
                          widget.suffixIcon!,
                          color: widget.suffixIconColor ?? Colors.grey,
                        ),
                        onPressed: widget.suffixTap,
                      )
                    : null,
                isDense: true,
                errorStyle: TextStyles.font14Weight400RightAligned().copyWith(
                  color: Colors.red,
                  fontSize: 12.sp,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}
