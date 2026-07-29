import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/logout_confirmation_dialog.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';

import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              final hasConn = await sl<InternetConnectionChecker>().hasConnection;
              if (!hasConn) {
                showfailureToast(AppStrings.noInternetConnection.tr());
                return;
              }
              if (!context.mounted) return;
              // Show confirmation dialog before logout
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => const LogoutConfirmationDialog(),
              );

              if (shouldLogout ?? false) {
                if (context.mounted) {
                  context.read<AuthCubit>().logout();
                }
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 12.r),
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
