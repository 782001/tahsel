import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    super.id,
    required super.employeeId,
    required super.employeeName,
    required super.uid,
    required super.checkIn,
    super.checkOut,
    required super.date,
    required super.status,
    required super.overtimeHours,
    required super.lateMinutes,
    required super.notes,
    super.expectedWorkingHours,
    super.deductionHours,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json, String id) {
    final checkInData = json['checkIn'];
    DateTime checkInDate;
    if (checkInData is Timestamp) {
      checkInDate = checkInData.toDate().toLocal();
    } else if (checkInData is String) {
      checkInDate = DateTime.parse(checkInData).toLocal();
    } else {
      checkInDate = DateTime.now();
    }

    final checkOutData = json['checkOut'];
    DateTime? checkOutDate;
    if (checkOutData != null) {
      if (checkOutData is Timestamp) {
        checkOutDate = checkOutData.toDate().toLocal();
      } else if (checkOutData is String) {
        checkOutDate = DateTime.parse(checkOutData).toLocal();
      }
    }

    String dateStr = '';
    if (json['date'] is String) {
      dateStr = json['date'] as String;
    } else if (json['date'] is Timestamp) {
      // ignore: unused_local_variable
      final dateObj = (json['date'] as Timestamp).toDate().toLocal();
      dateStr = "\${dateObj.year}-\${dateObj.month.toString().padLeft(2, '0')}-\${dateObj.day.toString().padLeft(2, '0')}";
    } else {
      dateStr = json['date']?.toString() ?? '';
    }

    return AttendanceModel(
      id: id,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      checkIn: checkInDate,
      checkOut: checkOutDate,
      date: dateStr,
      status: json['status'] as String? ?? 'present',
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0.0,
      lateMinutes: (json['lateMinutes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      expectedWorkingHours: (json['expectedWorkingHours'] as num?)?.toDouble() ?? 8.0,
      deductionHours: (json['deductionHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'uid': uid,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'date': date,
      'status': status,
      'overtimeHours': overtimeHours,
      'lateMinutes': lateMinutes,
      'notes': notes,
      'expectedWorkingHours': expectedWorkingHours,
      'deductionHours': deductionHours,
    };
  }

  factory AttendanceModel.fromEntity(AttendanceEntity entity) {
    return AttendanceModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      uid: entity.uid,
      checkIn: entity.checkIn,
      checkOut: entity.checkOut,
      date: entity.date,
      status: entity.status,
      overtimeHours: entity.overtimeHours,
      lateMinutes: entity.lateMinutes,
      notes: entity.notes,
      expectedWorkingHours: entity.expectedWorkingHours,
      deductionHours: entity.deductionHours,
    );
  }
}
