import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/routes/app_routes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/widgets/logout_confirmation_dialog.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              // Show confirmation dialog before logout
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => const LogoutConfirmationDialog(),
              );

              if (shouldLogout ?? false) {
                await sl<SecureStorageHelper>().deleteData(key: 'token');
                nav().pushNamedAndRemoveUntil(AppRoutes.login);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: AppColors.error),
              ),
            ),
            child: Text(
              AppStrings.logout.tr(),
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ),
        );
      },
    );
  }
}
