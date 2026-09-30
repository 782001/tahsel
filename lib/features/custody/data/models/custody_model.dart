import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/custody_entity.dart';
import '../../domain/entities/custody_expense_item.dart';

class CustodyExpenseItemModel extends CustodyExpenseItem {
  const CustodyExpenseItemModel({
    required super.id,
    required super.amount,
    required super.category,
    required super.description,
    required super.date,
    super.employeeName,
    super.receiptUrl,
  });

  factory CustodyExpenseItemModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return CustodyExpenseItemModel(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'other',
      description: map['description'] as String? ?? '',
      date: parsedDate,
      employeeName: map['employeeName'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (employeeName != null) 'employeeName': employeeName,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      if (employeeName != null) 'employeeName': employeeName,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  factory CustodyExpenseItemModel.fromEntity(CustodyExpenseItem entity) {
    return CustodyExpenseItemModel(
      id: entity.id,
      amount: entity.amount,
      category: entity.category,
      description: entity.description,
      date: entity.date,
      employeeName: entity.employeeName,
      receiptUrl: entity.receiptUrl,
    );
  }
}

class CustodyModel extends CustodyEntity {
  const CustodyModel({
    required super.id,
    required super.ownerUid,
    required super.recipientName,
    super.recipientEmployeeId,
    required super.recipientType,
    required super.initialAmount,
    required super.spentAmount,
    required super.remainingAmount,
    required super.status,
    super.notes,
    required super.createdAt,
    super.settledAt,
    super.settledBy,
    super.actualSettledAmount,
    super.varianceAmount,
    super.settlementNotes,
    super.expenses = const [],
  });

  factory CustodyModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt =
          DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedSettledAt;
    if (map['settledAt'] is Timestamp) {
      parsedSettledAt = (map['settledAt'] as Timestamp).toDate();
    } else if (map['settledAt'] is String) {
      parsedSettledAt = DateTime.tryParse(map['settledAt'] as String);
    }

    final rawExpenses = map['expenses'] as List<dynamic>? ?? [];
    final List<CustodyExpenseItemModel> expenses = [];
    final Set<String> seenExpenseKeys = {};
    bool hasDuplicates = false;

    for (final e in rawExpenses) {
      if (e is! Map) continue;
      final item =
          CustodyExpenseItemModel.fromMap(Map<String, dynamic>.from(e));
      String dedupeKey;
      if (item.id.startsWith('cust_exp_pur_')) {
        dedupeKey = 'purchase_${item.id.replaceFirst('cust_exp_', '')}';
      } else if (item.id.startsWith('pur_')) {
        dedupeKey = 'purchase_${item.id}';
      } else if (item.id.isNotEmpty) {
        dedupeKey = item.id;
      } else {
        dedupeKey =
            '${item.category}_${item.amount}_${item.date.millisecondsSinceEpoch}';
      }

      if (seenExpenseKeys.contains(dedupeKey)) {
        hasDuplicates = true;
        continue;
      }
      seenExpenseKeys.add(dedupeKey);
      expenses.add(item);
    }

    final double initialAmount =
        (map['initialAmount'] as num?)?.toDouble() ?? 0.0;
    final double rawSpent = (map['spentAmount'] as num?)?.toDouble() ?? 0.0;
    final double rawRemaining =
        (map['remainingAmount'] as num?)?.toDouble() ?? 0.0;

    final double spentAmount = hasDuplicates
        ? expenses.fold(0.0, (total, e) => total + e.amount)
        : rawSpent;
    final double remainingAmount = hasDuplicates
        ? (initialAmount - spentAmount)
        : rawRemaining;

    return CustodyModel(
      id: id,
      ownerUid: map['ownerUid'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      recipientEmployeeId: map['recipientEmployeeId'] as String?,
      recipientType: map['recipientType'] as String? ?? 'employee',
      initialAmount: initialAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      createdAt: parsedCreatedAt,
      settledAt: parsedSettledAt,
      settledBy: map['settledBy'] as String?,
      actualSettledAmount: (map['actualSettledAmount'] as num?)?.toDouble(),
      varianceAmount: (map['varianceAmount'] as num?)?.toDouble(),
      settlementNotes: map['settlementNotes'] as String?,
      expenses: expenses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'recipientName': recipientName,
      'recipientEmployeeId': recipientEmployeeId,
      'recipientType': recipientType,
      'initialAmount': initialAmount,
      'spentAmount': spentAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt!),
      if (settledBy != null) 'settledBy': settledBy,
      if (actualSettledAmount != null)
        'actualSettledAmount': actualSettledAmount,
      if (varianceAmount != null) 'varianceAmount': varianceAmount,
      if (settlementNotes != null) 'settlementNotes': settlementNotes,
      'expenses': expenses
          .map((e) => CustodyExpenseItemModel.fromEntity(e).toMap())
          .toList(),
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'recipientName': recipientName,
      'recipientEmployeeId': recipientEmployeeId,
      'recipientType': recipientType,
      'initialAmount': initialAmount,
      'spentAmount': spentAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
      if (settledBy != null) 'settledBy': settledBy,
      if (actualSettledAmount != null)
        'actualSettledAmount': actualSettledAmount,
      if (varianceAmount != null) 'varianceAmount': varianceAmount,
      if (settlementNotes != null) 'settlementNotes': settlementNotes,
      'expenses': expenses
          .map((e) => CustodyExpenseItemModel.fromEntity(e).toJsonMap())
          .toList(),
    };
  }

  factory CustodyModel.fromEntity(CustodyEntity entity) {
    return CustodyModel(
      id: entity.id,
      ownerUid: entity.ownerUid,
      recipientName: entity.recipientName,
      recipientEmployeeId: entity.recipientEmployeeId,
      recipientType: entity.recipientType,
      initialAmount: entity.initialAmount,
      spentAmount: entity.spentAmount,
      remainingAmount: entity.remainingAmount,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      settledAt: entity.settledAt,
      settledBy: entity.settledBy,
      actualSettledAmount: entity.actualSettledAmount,
      varianceAmount: entity.varianceAmount,
      settlementNotes: entity.settlementNotes,
      expenses: entity.expenses,
    );
  }
}
