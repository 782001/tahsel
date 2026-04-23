import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String? id;
  final String name;
  final String? phoneNumber;
  final String notificationPreference; // 'none', 'whatsapp', 'sms'
  final DateTime lastUsedAt;
  final int totalTransactions;
  final String? ledgerNumber;

  const CustomerEntity({
    this.id,
    required this.name,
    this.phoneNumber,
    this.notificationPreference = 'none',
    required this.lastUsedAt,
    this.totalTransactions = 1,
    this.ledgerNumber,
  });

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? notificationPreference,
    DateTime? lastUsedAt,
    int? totalTransactions,
    String? ledgerNumber,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notificationPreference: notificationPreference ?? this.notificationPreference,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      ledgerNumber: ledgerNumber ?? this.ledgerNumber,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        notificationPreference,
        lastUsedAt,
        totalTransactions,
        ledgerNumber,
      ];
}
