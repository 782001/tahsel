import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../debt/domain/entities/debt_entity.dart';

/// Represents a single debt transaction for a customer.
/// A customer may have multiple [DebtItem]s from different days.
class DebtItem {
  final String itemDescription; // ما أخذه الزبون
  final double amountPaid; // المبلغ المدفوع
  final double remainingDebt; // المتبقي / الديون
  final String date; // تاريخ العملية
  final DateTime lastUpdatedAt; // Latest activity timestamp
  final DebtEntity entity; // Original entity for updates

  const DebtItem({
    required this.itemDescription,
    required this.amountPaid,
    required this.remainingDebt,
    required this.date,
    required this.lastUpdatedAt,
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
      lastUpdatedAt: entity.lastUpdatedAt ?? entity.timestamp ?? DateTime.now(),
      entity: entity,
    );
  }

  double get totalAmount => entity.totalAmount;
  DateTime? get dueDate => entity.dueDate;
  DateTime? get lastReminderSentAt => entity.lastReminderSentAt;
  String? get formattedDueDate => entity.dueDate != null
      ? DateFormat('yyyy/MM/dd').format(entity.dueDate!)
      : null;

  /// Checks whether this debt item has an active, un-reminded due date status
  bool get hasUnremindedDueStatus {
    if (remainingDebt <= 0 || dueDate == null) return false;
    final due = dueDate!;
    final dueNormalized = DateTime(due.year, due.month, due.day);
    final alertWindowStart = dueNormalized.subtract(const Duration(days: 3));

    if (lastReminderSentAt != null &&
        lastReminderSentAt!.isAfter(alertWindowStart)) {
      return false; // Already reminded for this due date cycle
    }
    return true;
  }

  /// Whether this debt is overdue and has NOT been reminded yet
  bool isUnremindedOverdue(DateTime today) {
    if (!hasUnremindedDueStatus) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAfter(due);
  }

  /// Whether this debt is due soon (today up to 3 days) and has NOT been reminded yet
  bool isUnremindedDueSoon(DateTime today, DateTime in3Days) {
    if (!hasUnremindedDueStatus) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return !due.isBefore(today) && !due.isAfter(in3Days);
  }
}

/// Represents a customer with all their debt items.
class CustomerDebtDetail {
  final String customerName;
  final String status;
  final Color statusColor;
  final List<DebtItem> items;
  final String? ledgerNumber;
  final DateTime lastActivity;

  const CustomerDebtDetail({
    required this.customerName,
    required this.status,
    required this.statusColor,
    required this.items,
    required this.lastActivity,
    this.ledgerNumber,
  });

  factory CustomerDebtDetail.fromEntities(
    String name,
    List<DebtEntity> entities,
  ) {
    final items = entities.map((e) => DebtItem.fromEntity(e)).toList();

    // Extract ledger number from the first entity that has it
    String? ledger;
    for (var entity in entities) {
      if (entity.ledgerNumber != null && entity.ledgerNumber!.isNotEmpty) {
        ledger = entity.ledgerNumber;
        break;
      }
    }

    // Latest activity across all debt items for this customer
    DateTime latest = DateTime(2000);
    for (var item in items) {
      if (item.lastUpdatedAt.isAfter(latest)) {
        latest = item.lastUpdatedAt;
      }
    }

    // Logic for status
    double totalRemaining = items.fold(
      0.0,
      (sum, item) => sum + (item.remainingDebt < 0 ? 0 : item.remainingDebt),
    );

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
      lastActivity: latest,
      ledgerNumber: ledger,
    );
  }

  double get totalDebt =>
      items.fold(0, (sum, item) => sum + (item.remainingDebt < 0 ? 0 : item.remainingDebt));

  double get totalPaid => items.fold(0, (sum, item) => sum + item.amountPaid);

  String get lastTransactionDate => items.isNotEmpty ? items.last.date : '';

  /// Returns all unpaid debt items for this customer that share the same due date (same year, month, day).
  List<DebtItem> debtsDueOn(DateTime targetDate) {
    return items.where((item) {
      if (item.remainingDebt <= 0 || item.dueDate == null) return false;
      return item.dueDate!.year == targetDate.year &&
          item.dueDate!.month == targetDate.month &&
          item.dueDate!.day == targetDate.day;
    }).toList();
  }

  /// Returns the most urgent unpaid debt item with a due date that qualifies for the top banner alert:
  /// - Unpaid (remainingDebt > 0)
  /// - Has a dueDate
  /// - Due within 3 days (today, next 3 days, or overdue)
  /// - Has NOT been reminded yet during this due date cycle
  DebtItem? get activeDueDebt {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertThreshold = today.add(const Duration(days: 4)); // Next 3 days

    DebtItem? mostUrgent;
    for (final item in items) {
      if (item.remainingDebt <= 0 || item.dueDate == null) continue;

      final due = item.dueDate!;
      final dueDateNormalized = DateTime(due.year, due.month, due.day);

      // Must be due within 3 days or already in the past
      if (dueDateNormalized.isBefore(alertThreshold)) {
        // If a reminder was sent on or after the alert window start, skip to prevent spamming
        final alertWindowStart =
            dueDateNormalized.subtract(const Duration(days: 3));
        if (item.lastReminderSentAt != null &&
            item.lastReminderSentAt!.isAfter(alertWindowStart)) {
          continue;
        }

        if (mostUrgent == null || due.isBefore(mostUrgent.dueDate!)) {
          mostUrgent = item;
        }
      }
    }
    return mostUrgent;
  }
}
