import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/routes/app_routes.dart';
import '../cubit/customer_reports/customer_reports_cubit.dart';
import 'add_customer_dialog.dart';

class CustomerListCard extends StatelessWidget {
  final dynamic customer;
  final String uid;

  const CustomerListCard({
    super.key,
    required this.customer,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Card(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.blackLight.withAlpha(20), width: 1),
      ),
      color: AppColors.debtCardSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.customerReportDetails,
            arguments: {'uid': uid, 'customerName': customer.name},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.customStyle(
                        color: AppColors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${customer.totalTransactions} ${AppStrings.operations.tr()}',
                                style: TextStyles.customStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (customer.phoneNumber != null &&
                            customer.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.blackLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.phoneNumber!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((customer.ledgerNumber != null &&
                            customer.ledgerNumber!.isNotEmpty) ||
                        (customer.taxNumber != null &&
                            customer.taxNumber!.isNotEmpty) ||
                        (customer.commercialRegistration != null &&
                            customer.commercialRegistration!.isNotEmpty)) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (customer.ledgerNumber != null &&
                              customer.ledgerNumber!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.menu_book_outlined,
                              text:
                                  '${AppStrings.ledgerNumber.tr()}: ${customer.ledgerNumber}',
                            ),
                          if (customer.taxNumber != null &&
                              customer.taxNumber!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.receipt_outlined,
                              text:
                                  '${AppStrings.taxNumber.tr()}: ${customer.taxNumber}',
                            ),
                          if (customer.commercialRegistration != null &&
                              customer.commercialRegistration!.isNotEmpty)
                            _buildBadge(
                              icon: Icons.badge_outlined,
                              text:
                                  '${AppStrings.commercialRegistration.tr()}: ${customer.commercialRegistration}',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                    tooltip: AppStrings.editCustomer.tr(),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => BlocProvider.value(
                          value: context.read<CustomerReportsCubit>(),
                          child: AddCustomerDialog(
                            uid: uid,
                            customer: customer,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.blackLight.withAlpha(100),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blackLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.blackLight,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.customStyle(
                color: AppColors.blackLight,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
