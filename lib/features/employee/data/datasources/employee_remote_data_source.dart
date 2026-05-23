import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/firebase_error_handler.dart';
import '../models/employee_model.dart';
import '../models/attendance_model.dart';
import '../models/payroll_model.dart';
import '../models/advance_model.dart';

class EmployeeRemotePaginationResult {
  final List<EmployeeModel> employees;
  final DocumentSnapshot? lastDoc;

  EmployeeRemotePaginationResult({required this.employees, this.lastDoc});
}

class AttendanceRemotePaginationResult {
  final List<AttendanceModel> attendanceLogs;
  final DocumentSnapshot? lastDoc;

  AttendanceRemotePaginationResult({
    required this.attendanceLogs,
    this.lastDoc,
  });
}

class PayrollRemotePaginationResult {
  final List<PayrollModel> payrollLogs;
  final DocumentSnapshot? lastDoc;

  PayrollRemotePaginationResult({required this.payrollLogs, this.lastDoc});
}

class AdvanceRemotePaginationResult {
  final List<AdvanceModel> advanceLogs;
  final DocumentSnapshot? lastDoc;

  AdvanceRemotePaginationResult({required this.advanceLogs, this.lastDoc});
}

abstract class EmployeeRemoteDataSource {
  Future<String> addEmployee(EmployeeModel employee);
  Future<void> editEmployee(EmployeeModel employee);
  Future<EmployeeRemotePaginationResult> getEmployees(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<List<EmployeeModel>> searchEmployees(String uid, String query);
  Future<String> checkInEmployee(AttendanceModel attendance);
  Future<void> checkOutEmployee({
    required String uid,
    required String attendanceId,
    required DateTime checkOut,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  });
  Future<AttendanceRemotePaginationResult> getAttendance(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<String> paySalary(
    PayrollModel payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  });
  Future<PayrollRemotePaginationResult> getPayrollHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<String> requestAdvance(AdvanceModel advance);
  Future<AdvanceRemotePaginationResult> getAdvanceHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  });
  Future<void> settleAdvances({
    required String uid,
    required List<String> advanceIds,
    required String payrollId,
  });
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final FirebaseFirestore firestore;

  EmployeeRemoteDataSourceImpl({required this.firestore});

  // ... (keeping other methods as is, just finding the correct place for the method)

  @override
  Future<String> addEmployee(EmployeeModel employee) async {
    try {
      final userRef = firestore.collection('users').doc(employee.uid);
      final collectionRef = userRef.collection('employees');

      final docRef = (employee.id != null && employee.id!.isNotEmpty)
          ? collectionRef.doc(employee.id)
          : collectionRef.doc();

      final batch = firestore.batch();
      batch.set(docRef, employee.toJson());

      // Idempotent increments on total employees inside user summaries doc
      final allTimeSummaryRef = userRef.collection('summaries').doc('all_time');
      batch.set(allTimeSummaryRef, {
        'employeeCount': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to add employee: $e');
    }
  }

  @override
  Future<void> editEmployee(EmployeeModel employee) async {
    try {
      if (employee.id == null || employee.id!.isEmpty) {
        throw Exception('Employee ID cannot be empty for edit operation');
      }
      final docRef = firestore
          .collection('users')
          .doc(employee.uid)
          .collection('employees')
          .doc(employee.id);

      await docRef.update(employee.toJson());
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to edit employee: $e');
    }
  }

  @override
  Future<EmployeeRemotePaginationResult> getEmployees(
    String uid, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('employees')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final employees = snapshot.docs
          .map((doc) => EmployeeModel.fromJson(doc.data(), doc.id))
          .toList();

      return EmployeeRemotePaginationResult(
        employees: employees,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch employees: $e');
    }
  }

  @override
  Future<List<EmployeeModel>> searchEmployees(String uid, String query) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('employees')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => EmployeeModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to search employees: $e');
    }
  }

  @override
  Future<String> checkInEmployee(AttendanceModel attendance) async {
    try {
      final userRef = firestore.collection('users').doc(attendance.uid);
      final docRef = (attendance.id != null && attendance.id!.isNotEmpty)
          ? userRef.collection('attendances').doc(attendance.id)
          : userRef.collection('attendances').doc();

      await docRef.set(attendance.toJson());
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to check in: $e');
    }
  }

  @override
  Future<void> checkOutEmployee({
    required String uid,
    required String attendanceId,
    required DateTime checkOut,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  }) async {
    try {
      final docRef = firestore
          .collection('users')
          .doc(uid)
          .collection('attendances')
          .doc(attendanceId);

      await docRef.update({
        'checkOut': Timestamp.fromDate(checkOut),
        'overtimeHours': overtimeHours,
        'deductionHours': deductionHours,
        'lateMinutes': lateMinutes,
        'status': status,
        'notes': notes,
      });
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to check out: $e');
    }
  }

  @override
  Future<AttendanceRemotePaginationResult> getAttendance(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('attendances')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('checkIn', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final logs = snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data(), doc.id))
          .toList();

      return AttendanceRemotePaginationResult(
        attendanceLogs: logs,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch attendance logs: $e');
    }
  }

  @override
  Future<String> paySalary(
    PayrollModel payroll, {
    List<String> attendanceIds = const [],
    List<String> advanceIds = const [],
  }) async {
    try {
      final userRef = firestore.collection('users').doc(payroll.uid);
      final docRef = (payroll.id != null && payroll.id!.isNotEmpty)
          ? userRef.collection('payrolls').doc(payroll.id)
          : userRef.collection('payrolls').doc();

      // Phase 1: Validate reads OUTSIDE the transaction to avoid
      // the Windows platform-channel threading crash caused by too many
      // sequential transaction.get() calls inside runTransaction.
      for (final attId in attendanceIds) {
        final snap = await userRef.collection('attendances').doc(attId).get();
        if (!snap.exists) {
          throw Exception('Attendance record $attId does not exist.');
        }
        final data = snap.data() as Map<String, dynamic>;
        if (data['isPaid'] == true) {
          throw Exception('Attendance record $attId is already paid.');
        }
      }

      for (final advId in advanceIds) {
        final snap = await userRef.collection('advances').doc(advId).get();
        if (!snap.exists) {
          throw Exception('Advance record $advId does not exist.');
        }
        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] == 'deducted') {
          throw Exception('Advance record $advId is already deducted.');
        }
      }

      // Phase 2: Atomic batch write for all mutations.
      final batch = firestore.batch();

      batch.set(docRef, payroll.toJson());

      for (final attId in attendanceIds) {
        batch.update(userRef.collection('attendances').doc(attId), {
          'isPaid': true,
          'payrollId': docRef.id,
        });
      }

      for (final advId in advanceIds) {
        batch.update(userRef.collection('advances').doc(advId), {
          'status': 'deducted',
          'payrollId': docRef.id,
        });
      }

      final monthlyRef = userRef
          .collection('summaries')
          .doc('monthly_${payroll.monthKey}');
      final allTimeRef = userRef.collection('summaries').doc('all_time');

      for (final ref in [monthlyRef, allTimeRef]) {
        batch.set(ref, {
          'totalSalariesPaid': FieldValue.increment(payroll.netSalary),
          'totalOvertimePaid': FieldValue.increment(
            payroll.overtimeCompensation,
          ),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Update employee's outstanding balance
      final empRef = userRef.collection('employees').doc(payroll.employeeId);
      batch.update(empRef, {
        'outstandingBalance': payroll.carriedForwardBalance ?? 0.0,
      });

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to pay salary: $e');
    }
  }

  @override
  Future<PayrollRemotePaginationResult> getPayrollHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('payrolls')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('paymentDate', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final history = snapshot.docs
          .map((doc) => PayrollModel.fromJson(doc.data(), doc.id))
          .toList();

      return PayrollRemotePaginationResult(
        payrollLogs: history,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch payroll history: $e');
    }
  }

  @override
  Future<String> requestAdvance(AdvanceModel advance) async {
    try {
      final userRef = firestore.collection('users').doc(advance.uid);
      final docRef = (advance.id != null && advance.id!.isNotEmpty)
          ? userRef.collection('advances').doc(advance.id)
          : userRef.collection('advances').doc();

      final batch = firestore.batch();
      batch.set(docRef, advance.toJson());

      // Update summaries: advance is a partial salary payment
      final monthKey = DateFormat('yyyy-MM', 'en').format(advance.date);
      final monthlyRef = userRef
          .collection('summaries')
          .doc('monthly_$monthKey');
      final allTimeRef = userRef.collection('summaries').doc('all_time');

      for (final ref in [monthlyRef, allTimeRef]) {
        batch.set(ref, {
          'totalSalariesPaid': FieldValue.increment(advance.amount),
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to request advance: $e');
    }
  }

  @override
  Future<AdvanceRemotePaginationResult> getAdvanceHistory(
    String uid,
    String employeeId, {
    int limit = 15,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = firestore
          .collection('users')
          .doc(uid)
          .collection('advances')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('date', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final history = snapshot.docs
          .map((doc) => AdvanceModel.fromJson(doc.data(), doc.id))
          .toList();

      return AdvanceRemotePaginationResult(
        advanceLogs: history,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to fetch advance history: $e');
    }
  }

  @override
  Future<void> settleAdvances({
    required String uid,
    required List<String> advanceIds,
    required String payrollId,
  }) async {
    try {
      if (advanceIds.isEmpty) return;
      final userRef = firestore.collection('users').doc(uid);
      final batch = firestore.batch();

      for (final id in advanceIds) {
        final docRef = userRef.collection('advances').doc(id);
        batch.update(docRef, {'status': 'deducted', 'payrollId': payrollId});
      }

      await batch.commit();
    } catch (e) {
      FirebaseErrorHandler.handle(e);
      throw Exception('Failed to settle advances: $e');
    }
  }
}
