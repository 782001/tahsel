import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/styles.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../cubit/offline_sync_cubit.dart';

class SyncStatusListener extends StatelessWidget {
  final Widget child;

  const SyncStatusListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineSyncCubit, OfflineSyncState>(
      listener: (context, state) {
        if (state is OfflineSyncInProgress) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              backgroundColor: AppColors.primaryColor,
              content: Row(
                children: [
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppStrings.syncingData.tr(),
                    style:  TextStyles.customStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: const [
                SizedBox.shrink(), // required but empty
              ],
            ),
          );
        } else if (state is OfflineSyncSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(
            context,
          ).hideCurrentMaterialBanner(); 

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.syncSuccess.tr()),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is OfflineSyncFailure) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.syncFailed.tr()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: child,
    );
  }
}
