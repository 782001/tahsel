import 'package:equatable/equatable.dart';

class EmployeeActivityEntity extends Equatable {
  final String id;
  final String ownerUid;
  final String employeeUid;
  final String employeeName;
  final String rolePreset;
  final String actionCategory; // 'pos', 'debt', 'debt_settle', 'expense', 'vault', 'inventory', 'supplier_debt', 'hr'
  final String actionType; // 'quick_sale', 'debt_add', 'expense_add', etc.
  final String actionTitle;
  final String details;
  final double? amount;
  final Map<String, dynamic>? extraData;
  final DateTime timestamp;
  final bool isOfflineSync;

  const EmployeeActivityEntity({
    required this.id,
    required this.ownerUid,
    required this.employeeUid,
    required this.employeeName,
    this.rolePreset = 'custom',
    required this.actionCategory,
    required this.actionType,
    required this.actionTitle,
    required this.details,
    this.amount,
    this.extraData,
    required this.timestamp,
    this.isOfflineSync = false,
  });

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        employeeUid,
        employeeName,
        rolePreset,
        actionCategory,
        actionType,
        actionTitle,
        details,
        amount,
        extraData,
        timestamp,
        isOfflineSync,
      ];
}
