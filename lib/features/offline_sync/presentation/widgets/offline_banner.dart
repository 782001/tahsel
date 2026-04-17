import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../standard_features/no-internet/logic/connectivity_cubit.dart';
import '../../../standard_features/no-internet/logic/connectivity_state.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/extensions/string_extensions.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, state) {
            if (state is ConnectivityDisconnected) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                color: AppColors.warning.withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: AppColors.warning,
                      size: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppStrings.noInternetConnection.tr(),
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
