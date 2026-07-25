import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_operation.dart';

class CustomerOperationTile extends StatelessWidget {
  final CustomerOperation operation;

  const CustomerOperationTile({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: AppColors.blackLight.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.type.name.tr(),
                  style: TextStyles.customStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  intl.DateFormat('yyyy/MM/dd hh:mm a').format(operation.date),
                  style: TextStyles.customStyle(
                    color: AppColors.blackLight.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${operation.type == CustomerOperationType.payment ? "-" : "+"}${operation.amount.toSmartAmount()} ${AppStrings.egp.tr()}',
            style: TextStyles.customStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (operation.type) {
      case CustomerOperationType.purchase:
        return AppColors.primaryColor;
      case CustomerOperationType.debt:
        return AppColors.error;
      case CustomerOperationType.payment:
        return AppColors.success;
    }
  }

  IconData _getIcon() {
    switch (operation.type) {
      case CustomerOperationType.purchase:
        return Icons.shopping_bag_outlined;
      case CustomerOperationType.debt:
        return Icons.money_off_csred_outlined;
      case CustomerOperationType.payment:
        return Icons.check_circle_outline_rounded;
    }
  }
}
