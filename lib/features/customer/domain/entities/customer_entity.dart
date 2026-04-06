import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String? id;
  final String name;
  final DateTime lastUsedAt;
  final int totalTransactions;

  const CustomerEntity({
    this.id,
    required this.name,
    required this.lastUsedAt,
    this.totalTransactions = 1,
  });

  @override
  List<Object?> get props => [id, name, lastUsedAt, totalTransactions];
}
