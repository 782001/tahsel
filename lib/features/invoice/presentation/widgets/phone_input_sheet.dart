import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class PhoneInputSheet extends StatefulWidget {
  const PhoneInputSheet({super.key});

  static Future<String?> show(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: isDesktop ? const BoxConstraints(maxWidth: 500) : null,
      builder: (ctx) => const PhoneInputSheet(),
    );
  }

  @override
  State<PhoneInputSheet> createState() => _PhoneInputSheetState();
}

class _PhoneInputSheetState extends State<PhoneInputSheet> {
  final TextEditingController phoneController = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.scafoldBackGround,
          borderRadius: isDesktop
              ? BorderRadius.circular(24.r)
              : BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Row(
              children: [
                Image.asset(
                  Assets.imagesWhatsapp,
                  width: 32.w,
                  height: 32.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    AppStrings.sendWhatsapp.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              AppStrings.customerPhone.tr(),
              style: TextStyles.customStyle(
                color: AppColors.disabledColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12.r),
                      border: errorText != null
                          ? Border.all(color: AppColors.error)
                          : null,
                    ),
                    child: TextField(
                      cursorColor: AppColors.primaryColor,
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyles.customStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '01xxxxxxxxx',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () async {
                    final contact = await ContactService.pickContact(context);
                    if (contact != null && contact['phone'] != null) {
                      setState(() {
                        phoneController.text = contact['phone']!;
                        errorText = null;
                      });
                    }
                  },
                  icon: Icon(
                    Icons.contact_phone_rounded,
                    color: AppColors.primaryColor,
                  ),
                  tooltip: AppStrings.selectFromContacts.tr(),
                ),
              ],
            ),
            if (errorText != null) ...[
              SizedBox(height: 8.h),
              Text(
                errorText!,
                style: TextStyles.customStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppStrings.cancel.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.disabledColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final phone = phoneController.text.trim();
                      if (phone.isEmpty) {
                        setState(() => errorText = AppStrings.requiredField.tr());
                        return;
                      }
                      Navigator.pop(context, phone);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      AppStrings.sendNow.tr(),
                      style: TextStyles.customStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
