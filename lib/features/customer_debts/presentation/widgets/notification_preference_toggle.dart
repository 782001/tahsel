import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_state.dart';

class NotificationPreferenceToggle extends StatelessWidget {
  final String customerName;

  const NotificationPreferenceToggle({super.key, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        String currentPreference = 'none';
        if (state is CustomerLoaded) {
          final customer = state.customers
              .where((c) => c.name.trim() == customerName.trim())
              .firstOrNull;
          currentPreference = customer?.notificationPreference ?? 'none';
        }

        return Container(
          padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: isDesktop ? 8 : 8.w),
                  Text(
                    AppStrings.notificationChannel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 12 : 12.h),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'none',
                      label: Text(
                        AppStrings.none.tr(),
                        style: TextStyles.customStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.notifications_off_outlined),
                    ),
                    ButtonSegment(
                      value: 'whatsapp',
                      label: Text(
                        AppStrings.whatsapp.tr(),
                        style: TextStyles.customStyle(fontSize: 12),
                      ),
                      icon: Image.asset(
                        Assets.imagesWhatsapp,
                        width: isDesktop ? 22 : 22.w,
                        height: isDesktop ? 22 : 22.w,
                      ),
                    ),
                    ButtonSegment(
                      value: 'sms',
                      label: Text(
                        AppStrings.sms.tr(),
                        style: TextStyles.customStyle(fontSize: 12),
                      ),
                      icon: const Icon(Icons.sms_outlined),
                    ),
                  ],
                  selected: {currentPreference},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isEmpty) return;
                    final uid = AppStrings.userToken;
                    if (uid.isNotEmpty) {
                      context.read<CustomerCubit>().updateCustomerPreference(
                        uid,
                        customerName,
                        newSelection.first,
                      );
                    }
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    selectedBackgroundColor: AppColors.primaryColor,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: AppColors.disabledColor,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
