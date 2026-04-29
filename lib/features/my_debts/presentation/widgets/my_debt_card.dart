import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';

class MyDebtCard extends StatelessWidget {
  final MyDebtPersonEntity person;

  const MyDebtCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsCubit, MyDebtsState>(
      builder: (context, state) {
        final isProcessing = state.processingId == person.name;
        final isOffline = state.status == MyDebtsStatus.offlineLoaded;
        final totalPaid = person.totalDebtAmount - person.totalRemainingDebt;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: AppColors.debtCardSurface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppColors.isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: isOffline
                  ? null
                  : () async {
                      final uid = AppStrings.userToken;
                      await sl<NavigatorService>().pushNamedWithArgs(
                        routeName: AppRoutes.myDebtDetails,
                        arguments: person,
                      );
                      if (context.mounted && uid != null) {
                        context.read<MyDebtsCubit>().loadPersons(
                          uid,
                          forceRefresh: true,
                        );
                      }
                    },
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Opacity(
                      opacity: (isProcessing || isOffline) ? 0.7 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            person.name,
                                            style: TextStyles.customStyle(
                                              color: AppColors.textColor,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (person.isPending) ...[
                                          SizedBox(width: 8.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              AppStrings.syncing.tr(),
                                              style: TextStyles.customStyle(
                                                color: AppColors.error,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (person.phoneNumber != null &&
                                        person.phoneNumber!.isNotEmpty)
                                      Text(
                                        person.phoneNumber!,
                                        style: TextStyles.customStyle(
                                          color: AppColors.subTitleColor,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAmountInfo(
                                AppStrings.remainingDebt.tr(),
                                person.totalRemainingDebt,
                                AppColors.error,
                              ),
                              _buildAmountInfo(
                                AppStrings.paid.tr(),
                                totalPaid,
                                AppColors.success,
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.disabledColor,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${AppStrings.lastTransactionDate.tr()}: ${DateFormat('yyyy/MM/dd').format(person.lastUsedAt)}',
                                style: TextStyles.customStyle(
                                  color: AppColors.disabledColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isProcessing)
                    Positioned.fill(
                      child: ShimmerLoading(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    final bool isPaid = person.totalRemainingDebt <= 0;
    final color = isPaid ? AppColors.success : AppColors.error;
    final text = isPaid ? AppStrings.paid : AppStrings.remaining;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text.tr(),
        style: TextStyles.customStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            color: AppColors.subTitleColor,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${amount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
