import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/my_debt_entity.dart';

class MyDebtItem {
  final String description;
  final double amountPaid;
  final double remainingDebt;
  final String date;
  final DateTime lastUpdatedAt;
  final MyDebtEntity entity;

  const MyDebtItem({
    required this.description,
    required this.amountPaid,
    required this.remainingDebt,
    required this.date,
    required this.lastUpdatedAt,
    required this.entity,
  });

  factory MyDebtItem.fromEntity(MyDebtEntity entity) {
    return MyDebtItem(
      description: entity.notes ?? '',
      amountPaid: entity.paidAmount,
      remainingDebt: entity.remainingDebt,
      date: DateFormat('yyyy/MM/dd').format(entity.createdAt),
      lastUpdatedAt: entity.lastTransactionDate,
      entity: entity,
    );
  }

  double get totalAmount => amountPaid + remainingDebt;
}

class MyDebtDetail {
  final String? personId;
  final String personName;
  final String status;
  final Color statusColor;
  final List<MyDebtItem> items;
  final DateTime lastActivity;
  final String? phoneNumber;
  final String notificationPreference;

  const MyDebtDetail({
    this.personId,
    required this.personName,
    required this.status,
    required this.statusColor,
    required this.items,
    required this.lastActivity,
    this.phoneNumber,
    this.notificationPreference = 'none',
  });

  factory MyDebtDetail.fromEntities(String name, List<MyDebtEntity> entities) {
    final items = entities.map((e) => MyDebtItem.fromEntity(e)).toList();
    
    String? phone;
    String? pId;
    String preference = 'none';
    for (var entity in entities) {
      if (entity.phoneNumber != null && entity.phoneNumber!.isNotEmpty) {
        phone = entity.phoneNumber;
      }
      if (entity.notificationPreference != 'none') {
        preference = entity.notificationPreference;
      }
      if (entity.personId != null) {
        pId = entity.personId;
      }
    }

    DateTime latest = DateTime(2000);
    for (var item in items) {
      if (item.lastUpdatedAt.isAfter(latest)) {
        latest = item.lastUpdatedAt;
      }
    }

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

    return MyDebtDetail(
      personId: pId,
      personName: name,
      status: status,
      statusColor: statusColor,
      items: items,
      lastActivity: latest,
      phoneNumber: phone,
      notificationPreference: preference,
    );
  }

  double get totalDebt =>
      items.fold(0, (sum, item) => sum + item.remainingDebt);

  double get totalPaid =>
      items.fold(0, (sum, item) => sum + item.amountPaid);

  String get lastTransactionDate =>
      items.isNotEmpty ? items.last.date : '';
}
