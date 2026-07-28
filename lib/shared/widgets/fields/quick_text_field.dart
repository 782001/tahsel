import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/styles.dart';

class QuickAddTextField extends StatelessWidget {
  final String hint;
  final String? labelText;
  final TextEditingController? controller;
  final IconData? icon;
  final String? prefixText;
  final String? suffixText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isNumber;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final double? hintFontSize;
  final double? fontSize;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  const QuickAddTextField({
    super.key,
    required this.hint,
    this.labelText,
    this.controller,
    this.icon,
    this.prefixText,
    this.suffixText,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isNumber = false,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.hintFontSize = 14,
    this.fontSize = 14,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: AppColors.primaryColor,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ?? (isNumber ? TextInputType.number : TextInputType.text),
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      style: TextStyles.customStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w600,
        fontSize: fontSize ?? 14,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: labelText != null
            ? TextStyles.customStyle(
                color: AppColors.blackLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )
            : null,
        hintText: hint,
        errorText: errorText,
        hintStyle: TextStyles.customStyle(
          color: AppColors.blackLight.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
          fontSize: hintFontSize ?? 14,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.blackLight)
            : prefixText != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      prefixText!,
                      style: TextStyles.customStyle(
                        color: AppColors.stitchOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
        suffixIcon: _buildSuffixIcon(),
        suffixText: suffixText,
        suffixStyle: TextStyles.customStyle(
          color: AppColors.blackLight,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.stitchSurfaceHigh.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (controller == null) {
      if (suffixIcon != null) {
        return IconButton(
          icon: Icon(suffixIcon, color: AppColors.primaryColor),
          onPressed: onSuffixIconPressed,
        );
      }
      return null;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        if (!hasText && suffixIcon == null) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: AppColors.blackLight.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  controller?.clear();
                  onChanged?.call('');
                },
              ),
            if (suffixIcon != null)
              IconButton(
                icon: Icon(suffixIcon, color: AppColors.primaryColor),
                onPressed: onSuffixIconPressed,
              ),
          ],
        );
      },
    );
  }
}
