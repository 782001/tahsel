import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import '../../data/models/app_version_model.dart';
import '../cubit/update_cubit.dart';

class UpdateDialog extends StatelessWidget {
  final AppVersionModel versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !versionInfo.forceUpdate,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),

        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          titlePadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 10.h),
          contentPadding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 24.h),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded, color: AppColors.primaryColor, size: 28.h),
              SizedBox(width: 12.w),
              Expanded(
                child: TextWidget(
                  AppStrings.newUpdateAvailable.tr(),
                  style: TextStyles.font18WeightBoldText().copyWith(
                    color: AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
          content: BlocBuilder<UpdateCubit, UpdateState>(
            builder: (context, state) {
              if (state is UpdateDownloading) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextWidget(
                      AppStrings.downloading.tr(),
                      style: TextStyles.font14Weight400RightAligned().copyWith(
                        color: AppColors.subTitleColor,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        minHeight: 8.h,
                        backgroundColor: AppColors.veryLightGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextWidget(
                      "${(state.progress * 100).toInt()}%",
                      style: TextStyles.font16WeightBoldText().copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                );
              }
        
              if (state is UpdateInstalled) {
                return TextWidget(
                  Platform.isAndroid 
                    ? AppStrings.updateReadyToInstall.tr()
                    : AppStrings.updateReadyToOpen.tr(),
                  style: TextStyles.font16WeightBoldText().copyWith(
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                );
              }
        
              if (state is UpdateError) {
                return TextWidget(
                  "${AppStrings.updateFailed.tr()}\n${state.message}",
                  style: TextStyles.font14Weight400RightAligned().copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                );
              }
        
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextWidget(
                      "${AppStrings.version.tr()}: ${versionInfo.versionName}",
                      style: TextStyles.font14WeightBoldText().copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextWidget(
                    versionInfo.updateMessage,
                    style: TextStyles.font16Weight400Text().copyWith(
                      color: AppColors.subTitleColor,
                    ),
                  ),
                ],
              );
            },
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            BlocBuilder<UpdateCubit, UpdateState>(
              builder: (context, state) {
                if (state is UpdateDownloading || state is UpdateInstalled) {
                  return const SizedBox.shrink();
                }
        
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!versionInfo.forceUpdate)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: TextWidget(
                          AppStrings.updateLater.tr(),
                          style: TextStyles.font14Weight500Action().copyWith(
                            color: AppColors.subTitleColor,
                          ),
                        ),
                      ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.isDark ? AppColors.blackReal : Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<UpdateCubit>().startUpdate(versionInfo);
                      },
                      child: TextWidget(
                        AppStrings.updateNow.tr(),
                        style: TextStyles.font14WeightBoldText().copyWith(
                          color: AppColors.isDark ? AppColors.blackReal : Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ));
  }
}
