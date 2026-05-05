import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';

class MyNotificationPreferenceToggle extends StatelessWidget {
  final MyDebtPersonEntity person;

  const MyNotificationPreferenceToggle({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsCubit, MyDebtsState>(
      builder: (context, state) {
        // Find the person in the state to ensure we have the latest data (e.g. preference)
        final personInState = state.status == MyDebtsStatus.loaded
            ? state.persons.where((p) => p.name == person.name).firstOrNull ??
                  person
            : person;

        final currentPreference = personInState.notificationPreference;

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18.sp,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.notificationChannel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'none',
                      label: Text(
                        AppStrings.none.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: const Icon(Icons.notifications_off_outlined),
                    ),
                    ButtonSegment(
                      value: 'whatsapp',
                      label: Text(
                        AppStrings.whatsapp.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: Image.asset(
                        Assets.imagesWhatsapp,
                        width: 22.w,
                        height: 22.w,
                      ),
                    ),
                    ButtonSegment(
                      value: 'sms',
                      label: Text(
                        AppStrings.sms.tr(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      icon: const Icon(Icons.sms_outlined),
                    ),
                  ],
                  selected: {currentPreference},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isEmpty) return;
                    final uid = AppStrings.userToken;
                    if (uid.isNotEmpty) {
                      if (context.read<ConnectivityCubit>().state
                          is ConnectivityDisconnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.noInternetConnection.tr()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      context.read<MyDebtsCubit>().updatePreference(
                        uid,
                        person.name,
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
                      borderRadius: BorderRadius.circular(12.r),
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
