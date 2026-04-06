import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import '../../../../core/utils/app_colors.dart';

class ExpenseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String date;
  final bool isGrid;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.isGrid = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.surface;

    if (isGrid) {
      // ... kept as is (no slidable for grid in typical mobile UX)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -16,
              top: -16,
              bottom: -16,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.stitchBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.stitchBlue, size: 20),
                    ),
                    Text(
                      date,
                      style: TextStyles.customStyle(
                        color: AppColors.blackLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '-${amount.toStringAsFixed(1)}',
                          textDirection: TextDirection.ltr,
                          style: TextStyles.customStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Slidable(
      key: ValueKey(title + date + amount.toString()),
      enabled: onDelete != null,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            icon: Icons.delete_outline,
            label: AppStrings.delete.tr(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -16,
              top: -16,
              bottom: -16,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                // Icon — fixed size, never overflows
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.stitchBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.stitchBlue, size: 24),
                ),
                const SizedBox(width: 12),
                // Title + subtitle — takes remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: AppColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.customStyle(
                          color: AppColors.blackLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount + date — wrap content with max width constraint to avoid overflow
                Container(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '-${amount.toStringAsFixed(1)}',
                          textDirection: TextDirection.ltr,
                          style: TextStyles.customStyle(
                            color: AppColors.error,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        maxLines: 1,
                        style: TextStyles.customStyle(
                          color: AppColors.blackLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
