import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    super.id,
    required super.uid,
    required super.name,
    required super.phone,
    required super.role,
    required super.salaryType,
    required super.salaryAmount,
    required super.status,
    required super.createdAt,
    required super.notes,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAtData = json['createdAt'];
    DateTime createdAtDate;

    if (createdAtData is Timestamp) {
      createdAtDate = createdAtData.toDate().toLocal();
    } else if (createdAtData is String) {
      createdAtDate = DateTime.parse(createdAtData).toLocal();
    } else {
      createdAtDate = DateTime.now();
    }

    return EmployeeModel(
      id: id,
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      salaryType: json['salaryType'] as String? ?? 'monthly',
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      createdAt: createdAtDate,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'salaryType': salaryType,
      'salaryAmount': salaryAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  factory EmployeeModel.fromEntity(EmployeeEntity entity) {
    return EmployeeModel(
      id: entity.id,
      uid: entity.uid,
      name: entity.name,
      phone: entity.phone,
      role: entity.role,
      salaryType: entity.salaryType,
      salaryAmount: entity.salaryAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      notes: entity.notes,
    );
  }
}
