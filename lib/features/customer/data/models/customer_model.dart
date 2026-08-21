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
    super.firstDate,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawName = json['name'] ?? json['customerName'] ?? json['personName'];
    final nameStr = rawName != null ? rawName.toString().trim() : (id ?? '');

    return CustomerModel(
      id: id,
      name: nameStr.isNotEmpty ? nameStr : (id ?? 'عميل'),
      phoneNumber: json['phoneNumber']?.toString(),
      notificationPreference:
          json['notificationPreference']?.toString() ?? 'none',
      lastUsedAt: parseDate(json['lastUsedAt']),
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      ledgerNumber: json['ledgerNumber']?.toString(),
      firstDate: parseNullableDate(json['firstDate']),
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
      if (firstDate != null) 'firstDate': Timestamp.fromDate(firstDate!),
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
      firstDate: entity.firstDate,
    );
  }
}
