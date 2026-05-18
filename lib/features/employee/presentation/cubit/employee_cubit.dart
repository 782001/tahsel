import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import '../../../offline_sync/data/models/offline_record.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/payroll_entity.dart';
import '../../domain/usecases/employee_usecases.dart';
import 'employee_state.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final AddEmployeeUseCase addEmployeeUseCase;
  final EditEmployeeUseCase editEmployeeUseCase;
  final GetEmployeesUseCase getEmployeesUseCase;
  final SearchEmployeesUseCase searchEmployeesUseCase;
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetAttendanceUseCase getAttendanceUseCase;
  final PaySalaryUseCase paySalaryUseCase;
  final GetPayrollUseCase getPayrollUseCase;
  final GetPendingEmployeeRecordsUseCase getPendingEmployeeRecordsUseCase;

  EmployeeCubit({
    required this.addEmployeeUseCase,
    required this.editEmployeeUseCase,
    required this.getEmployeesUseCase,
    required this.searchEmployeesUseCase,
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getAttendanceUseCase,
    required this.paySalaryUseCase,
    required this.getPayrollUseCase,
    required this.getPendingEmployeeRecordsUseCase,
  }) : super(EmployeeInitial());

  Future<void> fetchEmployees(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is EmployeeFetchSuccess) {
      return;
    }

    emit(EmployeeLoading());

    // Fetch local pending offline records first (Offline-First Approach)
    final pendingResult = await getPendingEmployeeRecordsUseCase();
    final List<OfflineRecord> pendingRecords = pendingResult.fold(
      (_) => [],
      (records) => records,
    );

    final result = await getEmployeesUseCase(
      GetEmployeesParams(uid: uid, limit: 15),
    );

    result.fold(
      (failure) {
        if (pendingRecords.isNotEmpty) {
          // If Firestore is offline, show offline employees reconstructed from local payload
          final offlineEmployees = _reconstructEmployeesFromOffline(
            pendingRecords,
          );
          emit(
            EmployeeFetchSuccess(
              employees: offlineEmployees,
              pendingRecords: pendingRecords,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(EmployeeFailure(failure.message));
        }
      },
      (paginatedList) {
        // Merge real remote employees with local unsynced employees
        final List<EmployeeEntity> merged = List.from(paginatedList.employees);
        final offlineEmployees = _reconstructEmployeesFromOffline(
          pendingRecords,
        );

        for (var offlineEmp in offlineEmployees) {
          if (!merged.any((e) => e.id == offlineEmp.id)) {
            merged.insert(0, offlineEmp);
          }
        }

        emit(
          EmployeeFetchSuccess(
            employees: merged,
            pendingRecords: pendingRecords,
            lastDoc: paginatedList.lastDoc,
            hasReachedMax: paginatedList.employees.length < 15,
          ),
        );
      },
    );
  }

  Future<void> loadMoreEmployees(String uid) async {
    final currentState = state;
    if (currentState is! EmployeeFetchSuccess || currentState.hasReachedMax) {
      return;
    }

    final result = await getEmployeesUseCase(
      GetEmployeesParams(uid: uid, limit: 15, lastDoc: currentState.lastDoc),
    );

    result.fold((_) => null, (paginatedList) {
      final combined = [...currentState.employees, ...paginatedList.employees];
      final unique = <String, EmployeeEntity>{};

      for (var e in combined) {
        unique[e.id ?? ''] = e;
      }

      emit(
        EmployeeFetchSuccess(
          employees: unique.values.toList(),
          pendingRecords: currentState.pendingRecords,
          lastDoc: paginatedList.lastDoc,
          hasReachedMax: paginatedList.employees.length < 15,
        ),
      );
    });
  }

  Future<void> addEmployee(EmployeeEntity employee) async {
    emit(EmployeeLoading());
    final result = await addEmployeeUseCase(employee);
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (id) {
      emit(
        EmployeeActionSuccess(
          AppStrings.employeeAddedSuccess.tr(),
        ),
      );
      fetchEmployees(employee.uid, forceRefresh: true);
    });
  }

  Future<void> editEmployee(EmployeeEntity employee) async {
    emit(EmployeeLoading());
    final result = await editEmployeeUseCase(employee);
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (_) {
      emit(
        EmployeeActionSuccess(
          AppStrings.employeeEditedSuccess.tr(),
        ),
      );
      fetchEmployees(employee.uid, forceRefresh: true);
    });
  }

  Future<void> search(String uid, String query) async {
    if (query.isEmpty) {
      fetchEmployees(uid, forceRefresh: true);
      return;
    }
    emit(EmployeeLoading());
    final result = await searchEmployeesUseCase(
      SearchEmployeesParams(uid: uid, query: query),
    );
    result.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (employees) =>
          emit(EmployeeFetchSuccess(employees: employees, hasReachedMax: true)),
    );
  }

  Future<void> checkIn(AttendanceEntity attendance) async {
    emit(EmployeeLoading());
    final result = await checkInUseCase(attendance);
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (id) {
      emit(
        EmployeeActionSuccess(
          AppStrings.checkinSuccess.tr(),
        ),
      );
    });
  }

  Future<void> checkOut({
    required String uid,
    required String attendanceId,
    required DateTime checkOutTime,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  }) async {
    emit(EmployeeLoading());
    final result = await checkOutUseCase(
      CheckOutParams(
        uid: uid,
        attendanceId: attendanceId,
        checkOut: checkOutTime,
        overtimeHours: overtimeHours,
        deductionHours: deductionHours,
        lateMinutes: lateMinutes,
        status: status,
        notes: notes,
      ),
    );
    result.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (_) => emit(
        EmployeeActionSuccess(
          AppStrings.checkoutSuccess.tr(),
        ),
      ),
    );
  }

  Future<void> payPayroll(PayrollEntity payroll) async {
    emit(EmployeeLoading());
    final result = await paySalaryUseCase(payroll);
    result.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (_) => emit(
        EmployeeActionSuccess(
          AppStrings.payrollPaidSuccess.tr(),
        ),
      ),
    );
  }

  Future<void> fetchEmployeeDetails(
    String uid,
    String employeeId, {
    bool forceRefresh = false, 
  }) async {
    if (!forceRefresh && state is EmployeeDetailsFetchSuccess) {
      return;
    }
    
    emit(EmployeeLoading());

    // Fetch initial 15 logs for both
    final attendanceResult = await getAttendanceUseCase(
      GetAttendanceParams(uid: uid, employeeId: employeeId, limit: 15),
    );
    
    final payrollResult = await getPayrollUseCase(
      GetPayrollParams(uid: uid, employeeId: employeeId, limit: 15),
    );

    attendanceResult.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (attendancePaginated) {
        payrollResult.fold(
          (failure) => emit(EmployeeFailure(failure.message)),
          (payrollPaginated) async {
            // Logic to fetch more attendance if needed to calculate pending salaries
            List<AttendanceEntity> currentAttendance = List.from(attendancePaginated.attendanceLogs);
            Object? lastAttendanceDoc = attendancePaginated.lastDoc;
            bool hasReachedMaxAttendance = attendancePaginated.attendanceLogs.length < 15;

            if (payrollPaginated.payrollLogs.isNotEmpty && currentAttendance.isNotEmpty) {
              final latestPaymentDate = payrollPaginated.payrollLogs.first.paymentDate;
              while (currentAttendance.isNotEmpty &&
                  currentAttendance.last.checkIn.isAfter(latestPaymentDate) &&
                  !hasReachedMaxAttendance) {
                final extraResult = await getAttendanceUseCase(
                  GetAttendanceParams(uid: uid, employeeId: employeeId, limit: 15, lastDoc: lastAttendanceDoc),
                );
                
                bool fetchedMore = false;
                extraResult.fold(
                  (failure) {
                    hasReachedMaxAttendance = true;
                  },
                  (extraPaginated) {
                    currentAttendance.addAll(extraPaginated.attendanceLogs);
                    lastAttendanceDoc = extraPaginated.lastDoc;
                    hasReachedMaxAttendance = extraPaginated.attendanceLogs.length < 15;
                    fetchedMore = extraPaginated.attendanceLogs.isNotEmpty;
                  },
                );
                if (!fetchedMore) break;
              }
            }

            emit(
              EmployeeDetailsFetchSuccess(
                attendanceLogs: currentAttendance,
                payrollLogs: payrollPaginated.payrollLogs,
                lastAttendanceDoc: lastAttendanceDoc,
                lastPayrollDoc: payrollPaginated.lastDoc,
                hasReachedMaxAttendance: hasReachedMaxAttendance,
                hasReachedMaxPayroll: payrollPaginated.payrollLogs.length < 15,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> loadMoreAttendance(String uid, String employeeId) async {
    final currentState = state;
    if (currentState is! EmployeeDetailsFetchSuccess ||
        currentState.hasReachedMaxAttendance ||
        currentState.isPaginationLoadingAttendance) {
      return;
    }

    emit(currentState.copyWith(isPaginationLoadingAttendance: true));

    final result = await getAttendanceUseCase(
      GetAttendanceParams(
        uid: uid,
        employeeId: employeeId,
        limit: 15,
        lastDoc: currentState.lastAttendanceDoc,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginationLoadingAttendance: false)),
      (paginated) {
        emit(
          currentState.copyWith(
            attendanceLogs: [...currentState.attendanceLogs, ...paginated.attendanceLogs],
            lastAttendanceDoc: paginated.lastDoc,
            hasReachedMaxAttendance: paginated.attendanceLogs.length < 15,
            isPaginationLoadingAttendance: false,
          ),
        );
      },
    );
  }

  Future<void> loadMorePayroll(String uid, String employeeId) async {
    final currentState = state;
    if (currentState is! EmployeeDetailsFetchSuccess ||
        currentState.hasReachedMaxPayroll ||
        currentState.isPaginationLoadingPayroll) {
      return;
    }

    emit(currentState.copyWith(isPaginationLoadingPayroll: true));

    final result = await getPayrollUseCase(
      GetPayrollParams(
        uid: uid,
        employeeId: employeeId,
        limit: 15,
        lastDoc: currentState.lastPayrollDoc,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginationLoadingPayroll: false)),
      (paginated) {
        emit(
          currentState.copyWith(
            payrollLogs: [...currentState.payrollLogs, ...paginated.payrollLogs],
            lastPayrollDoc: paginated.lastDoc,
            hasReachedMaxPayroll: paginated.payrollLogs.length < 15,
            isPaginationLoadingPayroll: false,
          ),
        );
      },
    );
  }

  Future<void> fetchReports(String uid, {String? monthKey}) async {
    emit(EmployeeLoading());
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Fetch summaries
      final allTimeDoc = await userRef
          .collection('summaries')
          .doc('all_time')
          .get();
      final allTimeData = allTimeDoc.data() ?? {};

      double totalPaidSalaries =
          (allTimeData['totalSalariesPaid'] as num?)?.toDouble() ?? 0.0;
      double totalOvertimePaid =
          (allTimeData['totalOvertimePaid'] as num?)?.toDouble() ?? 0.0;
      int employeeCount = (allTimeData['employeeCount'] as num?)?.toInt() ?? 0;

      if (monthKey != null && monthKey.isNotEmpty) {
        final monthlyDoc = await userRef
            .collection('summaries')
            .doc('monthly_$monthKey')
            .get();
        final monthlyData = monthlyDoc.data() ?? {};
        totalPaidSalaries =
            (monthlyData['totalSalariesPaid'] as num?)?.toDouble() ?? 0.0;
        totalOvertimePaid =
            (monthlyData['totalOvertimePaid'] as num?)?.toDouble() ?? 0.0;
      }

      final activeEmployeesSnapshot = await userRef
          .collection('employees')
          .where('status', isEqualTo: 'active')
          .get();

      final activeCount = activeEmployeesSnapshot.docs.length;
      if (employeeCount < activeCount) {
        employeeCount = activeCount;
      }

      final attendanceSnapshot = await userRef
          .collection('attendances')
          .limit(100)
          .get();

      double attendanceRate = 0.0;
      if (attendanceSnapshot.docs.isNotEmpty) {
        final presentCount = attendanceSnapshot.docs
            .where(
              (doc) =>
                  doc.data()['status'] == 'present' ||
                  doc.data()['status'] == 'late',
            )
            .length;
        attendanceRate =
            (presentCount / attendanceSnapshot.docs.length) * 100.0;
      } else {
        attendanceRate = 100.0;
      }

      emit(
        EmployeeReportsSuccess(
          totalPaidSalaries: totalPaidSalaries,
          totalOvertimeCompensation: totalOvertimePaid,
          totalEmployees: employeeCount,
          activeEmployees: activeCount,
          averageAttendanceRate: attendanceRate,
        ),
      );
    } catch (e) {
      emit(EmployeeFailure(e.toString()));
    }
  }

  // --- Helpers ---
  List<EmployeeEntity> _reconstructEmployeesFromOffline(
    List<OfflineRecord> pendingRecords,
  ) {
    final List<EmployeeEntity> employees = [];
    final employeeRecords = pendingRecords.where((r) => r.type == 'employee');

    for (var r in employeeRecords) {
      try {
        final payload = jsonDecode(r.payloadJson) as Map<String, dynamic>;
        employees.add(
          EmployeeEntity(
            id: r.id,
            uid: payload['uid'] as String? ?? '',
            name: payload['name'] as String? ?? '',
            phone: payload['phone'] as String? ?? '',
            role: payload['role'] as String? ?? '',
            salaryType: payload['salaryType'] as String? ?? 'monthly',
            salaryAmount: (payload['salaryAmount'] as num?)?.toDouble() ?? 0.0,
            status: payload['status'] as String? ?? 'active',
            createdAt: payload['createdAt'] != null
                ? DateTime.parse(payload['createdAt'] as String)
                : DateTime.now(),
            notes: payload['notes'] as String? ?? '',
          ),
        );
      } catch (_) {}
    }
    return employees;
  }
}
