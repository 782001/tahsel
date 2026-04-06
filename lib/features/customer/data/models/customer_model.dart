import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    super.id,
    required super.name,
    required super.lastUsedAt,
    super.totalTransactions = 1,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CustomerModel(
      id: id,
      name: json['name'] as String,
      lastUsedAt: (json['lastUsedAt'] as Timestamp).toDate(),
      totalTransactions: json['totalTransactions'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'totalTransactions': totalTransactions,
    };
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      lastUsedAt: entity.lastUsedAt,
      totalTransactions: entity.totalTransactions,
    );
  }
}
