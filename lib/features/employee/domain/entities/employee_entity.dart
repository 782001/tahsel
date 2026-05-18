import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  final String? id;
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String salaryType; // 'monthly', 'daily', 'hourly'
  final double salaryAmount;
  final String status; // 'active', 'inactive', 'suspended'
  final DateTime createdAt;
  final String notes;

  const EmployeeEntity({
    this.id,
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.salaryType,
    required this.salaryAmount,
    required this.status,
    required this.createdAt,
    required this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    uid,
    name,
    phone,
    role,
    salaryType,
    salaryAmount,
    status,
    createdAt,
    notes,
  ];
}
