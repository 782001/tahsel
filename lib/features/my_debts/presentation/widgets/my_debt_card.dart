import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debts_state.dart';
import 'package:tahsel/routes/app_routes.dart';

class MyDebtCard extends StatelessWidget {
  final MyDebtPersonEntity person;

  const MyDebtCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyDebtsCubit, MyDebtsState>(
      builder: (context, state) {
        // final isProcessing = state.processingId == person.name;
        final isOffline = state.status == MyDebtsStatus.offlineLoaded;
        final totalPaid = person.totalDebtAmount - person.totalRemainingDebt;
        final isDesktop = ResponsiveLayout.isDesktop(context);

        return Container(
          margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12),
          decoration: BoxDecoration(
            color: AppColors.debtCardSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.2 : 0.03,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isOffline
                  ? null
                  : () async {
                      final uid = AppStrings.userToken;
                      await sl<NavigatorService>().pushNamedWithArgs(
                        routeName: AppRoutes.myDebtDetails,
                        arguments: person,
                      );
                      if (context.mounted) {
                        context.read<MyDebtsCubit>().loadPersons(
                          uid,
                          forceRefresh: true,
                        );
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (person.isPending) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.syncing.tr(),
                                        style: TextStyles.customStyle(
                                          color: AppColors.error,
                                          fontSize: 10,
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
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildAmountInfo(
                            person.totalRemainingDebt < 0
                                ? AppStrings.supplierCredit.tr()
                                : AppStrings.remainingDebt.tr(),
                            person.totalRemainingDebt.abs(),
                            person.totalRemainingDebt < 0
                                ? AppColors.supplierCreditColor
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildAmountInfo(
                            AppStrings.paid.tr(),
                            totalPaid,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.disabledColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${AppStrings.lastTransactionDate.tr()}: ${DateFormat('yyyy/MM/dd').format(person.lastUsedAt)}',
                            style: TextStyles.customStyle(
                              color: AppColors.disabledColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    final bool hasCredit = person.totalRemainingDebt < 0;
    final bool isPaid = person.totalRemainingDebt <= 0;
    final color = hasCredit
        ? AppColors.supplierCreditColor
        : (isPaid ? AppColors.success : AppColors.error);
    final text = hasCredit
        ? AppStrings.supplierCredit
        : (isPaid ? AppStrings.paid : AppStrings.remaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.tr(),
        style: TextStyles.customStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, Color color) {
    final double displayAmount = amount.abs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            color: AppColors.subTitleColor,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${displayAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
          style: TextStyles.customStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
