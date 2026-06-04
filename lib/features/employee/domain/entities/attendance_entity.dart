import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String? id;
  final String employeeId;
  final String employeeName;
  final String uid;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String date; // 'yyyy-MM-dd'
  final String status; // 'present', 'absent', 'late', 'half_day'
  final double overtimeHours;
  final int lateMinutes;
  final String notes;
  final double expectedWorkingHours;
  final double deductionHours;
  final bool isPaid;
  final String? payrollId;

  const AttendanceEntity({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.uid,
    this.checkIn,
    this.checkOut,
    required this.date,
    required this.status,
    required this.overtimeHours,
    required this.lateMinutes,
    required this.notes,
    this.expectedWorkingHours = 8.0,
    this.deductionHours = 0.0,
    this.isPaid = false,
    this.payrollId,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    uid,
    checkIn,
    checkOut,
    date,
    status,
    overtimeHours,
    lateMinutes,
    notes,
    expectedWorkingHours,
    deductionHours,
    isPaid,
    payrollId,
  ];
}
