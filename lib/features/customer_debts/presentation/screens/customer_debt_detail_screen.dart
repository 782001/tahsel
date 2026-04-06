import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/debt_item_card.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/header_banner.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/summary_row.dart';

class CustomerDebtDetailScreen extends StatelessWidget {
  final CustomerDebtDetail detail;

  const CustomerDebtDetailScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsible App Bar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200.h,
            pinned: true,
            backgroundColor: AppColors.primaryColor,
            centerTitle: true,
            title: Text(
              detail.customerName,
              style: TextStyles.customStyle(
                color: AppColors.whiteColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: HeaderBanner(detail: detail),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Container(
                height: 20.h,
                decoration: BoxDecoration(
                  color: AppColors.scafoldBackGround,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
              ),
            ),
          ),

          // ── Summary Cards ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
              child: SummaryRow(detail: detail),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Section header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    AppStrings.activityDetails.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${detail.items.length} ${AppStrings.transactionCount.tr()}',
                      style: TextStyles.customStyle(
                        color: AppColors.primaryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          // ── Debt Items List ─────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: DebtItemCard(
                  item: detail.items[index],
                  index: index + 1,
                ),
              );
            }, childCount: detail.items.length),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}
