import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_entity.dart';

class MyDebtModel extends MyDebtEntity {
  const MyDebtModel({
    required super.id,
    super.personId,
    required super.personName,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingDebt,
    super.phoneNumber,
    super.notes,
    required super.createdAt,
    required super.lastTransactionDate,
    super.isDeleted = false,
    super.notificationPreference = 'none',
  });

  factory MyDebtModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MyDebtModel(
      id: snapshot.id,
      personId: data['personId'],
      personName: data['personName'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      remainingDebt: (data['remainingDebt'] ?? 0.0).toDouble(),
      phoneNumber: data['phoneNumber'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastTransactionDate: (data['lastTransactionDate'] as Timestamp).toDate(),
      isDeleted: data['isDeleted'] ?? false,
      notificationPreference: data['notificationPreference'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personId': personId,
      'personName': personName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingDebt': remainingDebt,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTransactionDate': Timestamp.fromDate(lastTransactionDate),
      'isDeleted': isDeleted,
      'notificationPreference': notificationPreference,
    };
  }
}

class MyDebtTransactionModel extends MyDebtTransactionEntity {
  const MyDebtTransactionModel({
    required super.id,
    required super.debtId,
    required super.amount,
    required super.type,
    super.note,
    required super.date,
  });

  factory MyDebtTransactionModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MyDebtTransactionModel(
      id: snapshot.id,
      debtId: data['debtId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? '',
      note: data['note'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debtId': debtId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': Timestamp.fromDate(date),
    };
  }
}
