import 'package:flutter/material.dart';

/// Represents a single debt transaction for a customer.
/// A customer may have multiple [DebtItem]s from different days.
class DebtItem {
  final String itemDescription; // ما أخذه الزبون
  final double amountPaid;      // المبلغ المدفوع
  final double remainingDebt;   // المتبقي / الديون
  final String date;            // تاريخ العملية

  const DebtItem({
    required this.itemDescription,
    required this.amountPaid,
    required this.remainingDebt,
    required this.date,
  });

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

  double get totalDebt =>
      items.fold(0, (sum, item) => sum + item.remainingDebt);

  double get totalPaid =>
      items.fold(0, (sum, item) => sum + item.amountPaid);

  String get lastTransactionDate =>
      items.isNotEmpty ? items.last.date : '';
}
