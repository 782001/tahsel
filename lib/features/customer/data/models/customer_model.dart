import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    super.id,
    required super.name,
    super.phoneNumber,
    super.notificationPreference = 'none',
    required super.lastUsedAt,
    super.totalTransactions = 1,
    super.ledgerNumber,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CustomerModel(
      id: id,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      notificationPreference:
          json['notificationPreference'] as String? ?? 'none',
      lastUsedAt: (json['lastUsedAt'] as Timestamp).toDate(),
      totalTransactions: json['totalTransactions'] as int? ?? 1,
      ledgerNumber: json['ledgerNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'notificationPreference': notificationPreference,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
      'totalTransactions': totalTransactions,
      if (ledgerNumber != null) 'ledgerNumber': ledgerNumber,
    };
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      notificationPreference: entity.notificationPreference,
      lastUsedAt: entity.lastUsedAt,
      totalTransactions: entity.totalTransactions,
      ledgerNumber: entity.ledgerNumber,
    );
  }
}
