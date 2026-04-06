import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../debt/domain/entities/debt_entity.dart';

/// Represents a single debt transaction for a customer.
/// A customer may have multiple [DebtItem]s from different days.
class DebtItem {
  final String itemDescription; // ما أخذه الزبون
  final double amountPaid;      // المبلغ المدفوع
  final double remainingDebt;   // المتبقي / الديون
  final String date;            // تاريخ العملية
  final DebtEntity entity;      // Original entity for updates

  const DebtItem({
    required this.itemDescription,
    required this.amountPaid,
    required this.remainingDebt,
    required this.date,
    required this.entity,
  });

  factory DebtItem.fromEntity(DebtEntity entity) {
    return DebtItem(
      itemDescription: entity.productOrSessionDetails ?? '',
      amountPaid: entity.paidAmount,
      remainingDebt: entity.remainingAmount,
      date: entity.timestamp != null
          ? DateFormat('yyyy/MM/dd').format(entity.timestamp!)
          : '',
      entity: entity,
    );
  }

  double get totalAmount => amountPaid + remainingDebt;
}

/// Represents a customer with all their debt items.
class CustomerDebtDetail {
  final String customerName;
  final String status;
  final Color statusColor;
  final List<DebtItem> items;

  const CustomerDebtDetail({
    required this.customerName,
    required this.status,
    required this.statusColor,
    required this.items,
  });

  factory CustomerDebtDetail.fromEntities(String name, List<DebtEntity> entities) {
    final items = entities.map((e) => DebtItem.fromEntity(e)).toList();
    
    // Logic for status
    double totalRemaining = items.fold(0.0, (sum, item) => sum + item.remainingDebt);
    
    String status = AppStrings.debtStatusBalance;
    Color statusColor = AppColors.info;

    if (totalRemaining > 1000) {
      status = AppStrings.debtStatusCritical;
      statusColor = AppColors.error;
    } else if (totalRemaining > 500) {
      status = AppStrings.debtStatusOverdue;
      statusColor = AppColors.warning;
    } else if (totalRemaining > 0) {
      status = AppStrings.debtStatusMinor;
      statusColor = AppColors.primaryColor;
    }

    return CustomerDebtDetail(
      customerName: name,
      status: status,
      statusColor: statusColor,
      items: items,
    );
  }

  double get totalDebt =>
      items.fold(0, (sum, item) => sum + item.remainingDebt);

  double get totalPaid =>
      items.fold(0, (sum, item) => sum + item.amountPaid);

  String get lastTransactionDate =>
      items.isNotEmpty ? items.last.date : '';
}
