import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class DeleteAccountConfirmationDialog extends StatelessWidget {
  const DeleteAccountConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 20.r),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _buildDialogContent(context),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      width: isDesktop ? 420 : null,
      padding: EdgeInsets.all(isDesktop ? 20 : 20.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: isDesktop ? 40 : 40,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 20.h),
          Text(
            AppStrings.deleteAccountTitle.tr(),
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 18 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: isDesktop ? 12 : 12.h),
          Text(
            AppStrings.deleteAccountDescription.tr(),
            textAlign: TextAlign.center,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.normal,
              color: AppColors.blackLight,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 20.h),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                      side: BorderSide(color: AppColors.veryLightGrey),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 14 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackLight,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final isOffline = context.read<ConnectivityCubit>().state is ConnectivityDisconnected;
                    if (isOffline) {
                      showfailureToast(AppStrings.noInternetConnection.tr());
                      return;
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 18 : 12.h,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isDesktop ? 12 : 12.r,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.deleteAccountConfirm.tr(),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 14 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
