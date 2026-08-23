import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/vault_summary_entity.dart';

class VaultBalanceCard extends StatelessWidget {
  final VaultSummaryEntity summary;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  const VaultBalanceCard({
    super.key,
    required this.summary,
    required this.onDeposit,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isNegative = summary.currentBalance < 0;

    final gradientColors = isNegative
        ? const [Color(0xFFB91C1C), Color(0xFFEF4444)]
        : const [AppColors.vaultEmeraldStart, AppColors.vaultEmeraldEnd];

    final shadowColor = isNegative
        ? const Color(0xFFB91C1C).withValues(alpha: 0.35)
        : AppColors.vaultEmeraldStart.withValues(alpha: 0.35);

    final buttonPrimaryColor = isNegative
        ? const Color(0xFFB91C1C)
        : AppColors.vaultEmeraldStart;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Glow Circle
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: isDesktop ? 120 : 120.w,
              height: isDesktop ? 120 : 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isDesktop ? 8 : 8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              isNegative
                                  ? Icons.warning_amber_rounded
                                  : Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 12 : 8.w),
                          Flexible(
                            child: Text(
                              AppStrings.currentBalance.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isDesktop ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 8.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 12 : 8.w,
                              vertical: isDesktop ? 6 : 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.onlineOnlyNotice.tr(),
                                maxLines: 1,
                                style: TextStyles.customStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 11 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 12 : 8.w),
                          if (isNegative) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 10 : 8.w,
                                vertical: isDesktop ? 5 : 4.h,
                              ),
                              margin: EdgeInsets.only(left: 6.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_down_rounded,
                                    color: Colors.white,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    AppStrings.vaultDeficit.tr(),
                                    style: TextStyles.customStyle(
                                      color: Colors.white,
                                      fontSize: isDesktop ? 11 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 14.h),
                Row(
                  children: [
                    if (isNegative) ...[
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trending_down_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: Text(
                        '${summary.currentBalance.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                        style: TextStyles.customStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 36 : 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 20 : 18.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDeposit,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: buttonPrimaryColor,
                        ),
                        label: Text(
                          AppStrings.manualDeposit.tr(),
                          style: TextStyles.customStyle(
                            color: buttonPrimaryColor,
                            fontSize: isDesktop ? 14 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 14 : 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 10.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onWithdraw,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white,
                        ),
                        label: Text(
                          AppStrings.manualWithdraw.tr(),
                          style: TextStyles.customStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 14 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: isDesktop ? 14 : 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
