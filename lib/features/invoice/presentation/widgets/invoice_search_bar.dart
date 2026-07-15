import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';

class InvoiceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const InvoiceSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.primaryColor,
        style: TextStyles.customStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: AppStrings.searchInvoices.tr(),
          hintStyle: TextStyles.customStyle(
            color: AppColors.disabledColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryColor,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.disabledColor,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
