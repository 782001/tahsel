import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/total_debts_summary_skeleton.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../debt/presentation/cubit/total_debts/total_debts_cubit.dart';
import '../../../debt/presentation/cubit/total_debts/total_debts_state.dart';

class TotalDebtsSummaryCard extends StatefulWidget {
  const TotalDebtsSummaryCard({super.key});

  @override
  State<TotalDebtsSummaryCard> createState() => _TotalDebtsSummaryCardState();
}

class _TotalDebtsSummaryCardState extends State<TotalDebtsSummaryCard> {
  @override
  void initState() {
    super.initState();
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<TotalDebtsCubit>().getTotalDebts(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TotalDebtsCubit, TotalDebtsState>(
      builder: (context, state) {
        if (state is TotalDebtsLoading || state is TotalDebtsInitial) {
          return const TotalDebtsSummarySkeleton();
        }

        if (state is TotalDebtsError) {
          return const SizedBox.shrink(); // Hide on error
        }

        if (state is TotalDebtsLoaded) {
          return FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.debtCardSurface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppColors.isDark ? 0.3 : 0.05,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.whiteOpacity(0.05)
                      : AppColors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        AppStrings.totalDebts.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '${state.totalAmount.toStringAsFixed(1)} ${AppStrings.currencyEgp.tr()}',
                    style: TextStyles.customStyle(
                      color: AppColors.error,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (state.customerCount > 0) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          color: AppColors.disabledColor,
                          size: 16,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${state.customerCount} ${AppStrings.customers.tr()}',
                          style: TextStyles.customStyle(
                            color: AppColors.disabledColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
