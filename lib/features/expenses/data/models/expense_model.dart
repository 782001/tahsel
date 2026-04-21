import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    super.id,
    required super.uid,
    required super.amount,
    required super.category,
    required super.description,
    required super.createdAt,
    required super.monthKey,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAtData = json['createdAt'];
    DateTime createdAtDate;
    
    if (createdAtData is Timestamp) {
      createdAtDate = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAtDate = DateTime.parse(createdAtData);
    } else {
      createdAtDate = DateTime.now();
    }

    String monthKeyVal = json['monthKey'] as String? ?? '';
    if (monthKeyVal.isEmpty) {
      monthKeyVal = "${createdAtDate.year}/${createdAtDate.month.toString().padLeft(2, '0')}";
    }

    return ExpenseModel(
      id: id,
      uid: json['uid'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      createdAt: createdAtDate,
      monthKey: monthKeyVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'amount': amount,
      'category': category,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt), // Always store as Timestamp for Firestore queries
      'monthKey': monthKey,
    };
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      uid: entity.uid,
      amount: entity.amount,
      category: entity.category,
      description: entity.description,
      createdAt: entity.createdAt,
      monthKey: entity.monthKey,
    );
  }
}
