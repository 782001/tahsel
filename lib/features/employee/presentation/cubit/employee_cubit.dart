import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../domain/entities/advance_entity.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/payroll_entity.dart';
import '../../domain/usecases/advance_usecases.dart';
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
  final RequestAdvanceUseCase requestAdvanceUseCase;
  final GetAdvancesUseCase getAdvancesUseCase;
  final SettleAdvancesUseCase settleAdvancesUseCase;
  final GetEmployeeUseCase getEmployeeUseCase;

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
    required this.requestAdvanceUseCase,
    required this.getAdvancesUseCase,
    required this.settleAdvancesUseCase,
    required this.getEmployeeUseCase,
  }) : super(EmployeeInitial());

  Future<void> fetchEmployees(String uid, {bool forceRefresh = false}) async {
    if (!forceRefresh && state is EmployeeFetchSuccess) {
      return;
    }

    emit(EmployeeLoading());

    final result = await getEmployeesUseCase(
      GetEmployeesParams(uid: uid, limit: 15),
    );

    result.fold(
      (failure) {
        emit(EmployeeFailure(failure.message));
      },
      (paginatedList) {
        emit(
          EmployeeFetchSuccess(
            employees: paginatedList.employees,
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
      emit(EmployeeActionSuccess(AppStrings.employeeAddedSuccess.tr()));
      fetchEmployees(employee.uid, forceRefresh: true);
    });
  }

  Future<void> editEmployee(EmployeeEntity employee) async {
    emit(EmployeeLoading());
    final result = await editEmployeeUseCase(employee);
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (_) {
      emit(EmployeeActionSuccess(AppStrings.employeeEditedSuccess.tr()));
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
    result.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (id) => emit(EmployeeActionSuccess(AppStrings.checkinSuccess.tr())),
    );
  }

  Future<void> markAbsentOrExcused({
    required String uid,
    required String employeeId,
    required String employeeName,
    required String date,
    required String status,
    required String notes,
  }) async {
    emit(EmployeeLoading());
    final attendance = AttendanceEntity(
      employeeId: employeeId,
      employeeName: employeeName,
      uid: uid,
      checkIn: null,
      checkOut: null,
      date: date,
      status: status,
      notes: notes,
      overtimeHours: 0.0,
      lateMinutes: 0,
      isPaid: false,
    );
    final result = await checkInUseCase(attendance);
    result.fold(
      (failure) {
        if (failure is DuplicateAttendanceFailure) {
          emit(EmployeeFailure(AppStrings.attendanceAlreadyRegisteredShort.tr()));
        } else {
          emit(EmployeeFailure(failure.message));
        }
      },
      (id) {
        final successMessage = status == 'absent'
            ? AppStrings.absentRecorded.tr()
            : AppStrings.excusedRecorded.tr();
        emit(EmployeeActionSuccess(successMessage));
      },
    );
  }

  Future<void> checkOut({
    required String uid,
    required String employeeId,
    required String attendanceId,
    required DateTime checkOutTime,
    required double overtimeHours,
    required double deductionHours,
    required int lateMinutes,
    required String status,
    required String notes,
  }) async {
    // Preserve the current detail state for optimistic UI update
    final previousState = state;
    if (previousState is! EmployeeDetailsFetchSuccess) {
      emit(EmployeeLoading());
    }

    final result = await checkOutUseCase(
      CheckOutParams(
        uid: uid,
        employeeId: employeeId,
        attendanceId: attendanceId,
        checkOut: checkOutTime,
        overtimeHours: overtimeHours,
        deductionHours: deductionHours,
        lateMinutes: lateMinutes,
        status: status,
        notes: notes,
      ),
    );
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (_) {
      // Optimistically update the attendance record in the local state
      // so the pending salary card reflects the checkout immediately.
      if (previousState is EmployeeDetailsFetchSuccess) {
        final updatedLogs = previousState.attendanceLogs.map((log) {
          if (log.id == attendanceId) {
            return AttendanceEntity(
              id: log.id,
              employeeId: log.employeeId,
              employeeName: log.employeeName,
              uid: log.uid,
              checkIn: log.checkIn,
              checkOut: checkOutTime,
              date: log.date,
              status: status,
              overtimeHours: overtimeHours,
              deductionHours: deductionHours,
              lateMinutes: lateMinutes,
              notes: notes,
              expectedWorkingHours: log.expectedWorkingHours,
              isPaid: log.isPaid,
              payrollId: log.payrollId,
            );
          }
          return log;
        }).toList();

        emit(previousState.copyWith(attendanceLogs: updatedLogs));
      }
      emit(EmployeeActionSuccess(AppStrings.checkoutSuccess.tr()));
    });
  }

  Future<void> payPayroll(
    PayrollEntity payroll, {
    List<String>? advanceIdsToDeduct,
    List<String> attendanceIds = const [],
  }) async {
    emit(EmployeeLoading());
    final result = await paySalaryUseCase(
      payroll,
      attendanceIds: attendanceIds,
      advanceIds: advanceIdsToDeduct ?? const [],
    );
    result.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (_) => emit(EmployeeActionSuccess(AppStrings.payrollPaidSuccess.tr())),
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

    // Fetch fresh employee data
    final employeeResult = await getEmployeeUseCase(
      GetEmployeeParams(uid: uid, employeeId: employeeId),
    );

    // Fetch initial 15 logs for all three
    final attendanceResult = await getAttendanceUseCase(
      GetAttendanceParams(uid: uid, employeeId: employeeId, limit: 15),
    );

    final payrollResult = await getPayrollUseCase(
      GetPayrollParams(uid: uid, employeeId: employeeId, limit: 15),
    );

    final advanceResult = await getAdvancesUseCase(
      GetAdvancesParams(uid: uid, employeeId: employeeId, limit: 15),
    );

    employeeResult.fold(
      (failure) => emit(EmployeeFailure(failure.message)),
      (employee) {
        attendanceResult.fold((failure) => emit(EmployeeFailure(failure.message)), (
          attendancePaginated,
        ) {
          payrollResult.fold((failure) => emit(EmployeeFailure(failure.message)), (
            payrollPaginated,
          ) async {
            advanceResult.fold((failure) => emit(EmployeeFailure(failure.message)), (
              advancePaginated,
            ) async {
              // Logic to fetch more attendance if needed to calculate pending salaries
              List<AttendanceEntity> currentAttendance = List.from(
                attendancePaginated.attendanceLogs,
              );
              Object? lastAttendanceDoc = attendancePaginated.lastDoc;
              bool hasReachedMaxAttendance =
                  attendancePaginated.attendanceLogs.length < 15;

              if (payrollPaginated.payrollLogs.isNotEmpty &&
                  currentAttendance.isNotEmpty) {
                final latestPaymentDate =
                    payrollPaginated.payrollLogs.first.paymentDate;
                while (currentAttendance.isNotEmpty &&
                    (currentAttendance.last.checkIn ??
                            DateFormat('yyyy-MM-dd')
                                .parse(currentAttendance.last.date))
                        .isAfter(latestPaymentDate) &&
                    !hasReachedMaxAttendance) {
                  final extraResult = await getAttendanceUseCase(
                    GetAttendanceParams(
                      uid: uid,
                      employeeId: employeeId,
                      limit: 15,
                      lastDoc: lastAttendanceDoc,
                    ),
                  );

                  bool fetchedMore = false;
                  extraResult.fold(
                    (failure) {
                      hasReachedMaxAttendance = true;
                    },
                    (extraPaginated) {
                      currentAttendance.addAll(extraPaginated.attendanceLogs);
                      lastAttendanceDoc = extraPaginated.lastDoc;
                      hasReachedMaxAttendance =
                          extraPaginated.attendanceLogs.length < 15;
                      fetchedMore = extraPaginated.attendanceLogs.isNotEmpty;
                    },
                  );
                  if (!fetchedMore) break;
                }
              }

              emit(
                EmployeeDetailsFetchSuccess(
                  employee: employee,
                  attendanceLogs: currentAttendance,
                  payrollLogs: payrollPaginated.payrollLogs,
                  advanceLogs: advancePaginated.advanceLogs,
                  lastAttendanceDoc: lastAttendanceDoc,
                  lastPayrollDoc: payrollPaginated.lastDoc,
                  lastAdvanceDoc: advancePaginated.lastDoc,
                  hasReachedMaxAttendance: hasReachedMaxAttendance,
                  hasReachedMaxPayroll: payrollPaginated.payrollLogs.length < 15,
                  hasReachedMaxAdvance: advancePaginated.advanceLogs.length < 15,
                ),
              );
            });
          });
        });
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
      (failure) =>
          emit(currentState.copyWith(isPaginationLoadingAttendance: false)),
      (paginated) {
        emit(
          currentState.copyWith(
            attendanceLogs: [
              ...currentState.attendanceLogs,
              ...paginated.attendanceLogs,
            ],
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
      (failure) =>
          emit(currentState.copyWith(isPaginationLoadingPayroll: false)),
      (paginated) {
        emit(
          currentState.copyWith(
            payrollLogs: [
              ...currentState.payrollLogs,
              ...paginated.payrollLogs,
            ],
            lastPayrollDoc: paginated.lastDoc,
            hasReachedMaxPayroll: paginated.payrollLogs.length < 15,
            isPaginationLoadingPayroll: false,
          ),
        );
      },
    );
  }

  Future<void> requestAdvance(AdvanceEntity advance) async {
    emit(EmployeeLoading());
    final result = await requestAdvanceUseCase(advance);
    result.fold((failure) => emit(EmployeeFailure(failure.message)), (_) {
      emit(EmployeeActionSuccess(AppStrings.advanceRequestedSuccess.tr()));
      fetchEmployeeDetails(advance.uid, advance.employeeId, forceRefresh: true);
    });
  }

  Future<void> loadMoreAdvances(String uid, String employeeId) async {
    final currentState = state;
    if (currentState is! EmployeeDetailsFetchSuccess ||
        currentState.hasReachedMaxAdvance ||
        currentState.isPaginationLoadingAdvance) {
      return;
    }

    emit(currentState.copyWith(isPaginationLoadingAdvance: true));

    final result = await getAdvancesUseCase(
      GetAdvancesParams(
        uid: uid,
        employeeId: employeeId,
        limit: 15,
        lastDoc: currentState.lastAdvanceDoc,
      ),
    );

    result.fold(
      (failure) =>
          emit(currentState.copyWith(isPaginationLoadingAdvance: false)),
      (paginated) {
        emit(
          currentState.copyWith(
            advanceLogs: [
              ...currentState.advanceLogs,
              ...paginated.advanceLogs,
            ],
            lastAdvanceDoc: paginated.lastDoc,
            hasReachedMaxAdvance: paginated.advanceLogs.length < 15,
            isPaginationLoadingAdvance: false,
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
}
