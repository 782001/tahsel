import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/delete_account_confirmation_dialog.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_cubit.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return InkWell(
      onTap: () async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => const DeleteAccountConfirmationDialog(),
        );

        if (shouldDelete ?? false) {
          if (context.mounted) {
            context.read<AuthCubit>().deleteAccount();
          }
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.veryLightGrey,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              radius: 20.r,
              child: Icon(
                Icons.person_remove_rounded,
                color: AppColors.error,
              ),
            ),
            SizedBox(width:isDesktop ? 16 : 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.deleteAccount.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackReal,
                    ),
                  ),
                  SizedBox(height:isDesktop ? 4 : 4.h),
                  Text(
                    AppStrings.deleteAccountWarning.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.sandText,
            ),
          ],
        ),
      ),
    );
  }
}
