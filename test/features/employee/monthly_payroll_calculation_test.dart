import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/utils/monthly_payroll_calculator.dart';

void main() {
  group('Monthly Payroll Calculation Flow Tests (8-Step Model)', () {
    late EmployeeEntity monthlyEmployee;

    setUp(() {
      monthlyEmployee = EmployeeEntity(
        id: 'emp1',
        uid: 'user123',
        name: 'John Doe',
        phone: '123456',
        role: 'Engineer',
        salaryAmount: 6000.0, // Fixed contract salary
        salaryType: 'monthly',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        notes: '',
        allowedPaidWeekendsPerMonth: 4,
        dailyDeductionMultiplier: 1.5,
        expectedDailyHours: 8.0,
        overtimeMultiplier: 1.5,
        outstandingBalance: 0.0,
      );
    });

    test(
      'Step 1: Should return zero salary when no confirmed presence exists (Phantom Overtime Prevention)',
      () {
        // Setup: 0 attendances or only unpaid/absent attendances without any presence (present, late, half_day)
        final logs = <AttendanceEntity>[
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: null,
            date: '2026-05-01',
            status: 'absent',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
        ];

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 0.0);
        expect(result['pendingOvertimeComp'], 0.0);
        expect(result['unpaidOvertimeHours'], 0.0);
        expect(result['pendingDeductions'], 0.0);
        expect(result['netSalary'], 0.0);
        expect(result['attendedDays'], 0);
        expect(result['absentDays'], 1.0);
        expect(result['unpaidDays'], 0.0);
      },
    );

    test(
      'Steps 2, 3, 5, 6: Should allow full base salary and convert unused weekends to overtime bonus when presence exists and absences < allowed paid weekends',
      () {
        // Setup: Employee has 1 present day (presence verified), 2 absent days.
        // Total absences (2) < allowed paid weekends (4).
        // Unused weekends = 4 - 2 = 2 days.
        // Weekend bonus hours = 2 * 8.0 = 16.0 hours.
        // baseAmount = 6000.0. dailyHours = 8.0. Fixed Month Days = 30.
        // overtimeHourlyRate = 6000.0 / (30 * 8.0) * 1.5 = 25.0 * 1.5 = 37.5.
        // Expected overtime compensation = 16.0 * 37.5 = 600.0.
        final logs = <AttendanceEntity>[
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 17, 0),
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
          AttendanceEntity(
            id: '2',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 2, 9, 0),
            checkOut: null,
            date: '2026-05-02',
            status: 'absent',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
          AttendanceEntity(
            id: '3',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 3, 9, 0),
            checkOut: null,
            date: '2026-05-03',
            status: 'absent',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
        ];

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 6000.0);
        expect(result['unpaidOvertimeHours'], 16.0);
        expect(result['pendingOvertimeComp'], 600.0); // 16 * 37.5
        expect(result['pendingDeductions'], 0.0);
        expect(result['netSalary'], 6600.0); // base + overtime
        expect(result['attendedDays'], 1);
        expect(result['absentDays'], 2.0);
        expect(result['unpaidDays'], 0.0);
      },
    );

    test(
      'Steps 4, 7: Should apply daily deduction multiplier on excess absences when total absences exceed allowed paid weekends',
      () {
        // Setup: Employee has 1 present day (presence verified), 6 absent days.
        // Total absences (6) > allowed paid weekends (4).
        // Excess absences = 6 - 4 = 2 days.
        // dailyRate = 6000 / 30 = 200.0.
        // deductionMultiplier = 1.5.
        // Expected absence deduction = 2 * 200.0 * 1.5 = 600.0.
        // Unused weekends = 0.
        // Overtime hours = 0.
        final logs = <AttendanceEntity>[
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 17, 0),
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
          ...List.generate(
            6,
            (index) => AttendanceEntity(
              id: 'absent_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, 5, 2 + index, 9, 0),
              checkOut: null,
              date: '2026-05-${2 + index}',
              status: 'absent',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            ),
          ),
        ];

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 6000.0);
        expect(result['unpaidOvertimeHours'], 0.0);
        expect(result['pendingOvertimeComp'], 0.0);
        expect(result['pendingDeductions'], 600.0); // 2 excess days * 200 * 1.5
        expect(result['netSalary'], 5400.0); // 6000 - 600
        expect(result['attendedDays'], 1);
        expect(result['absentDays'], 6.0);
        expect(result['unpaidDays'], 2.0);
      },
    );

    test(
      'Step 8: Should correctly deduct outstanding balance from net salary',
      () {
        final employeeWithDebt = EmployeeEntity(
          id: 'emp1',
          uid: 'user123',
          name: 'John Doe',
          phone: '123456',
          role: 'Engineer',
          salaryAmount: 6000.0,
          salaryType: 'monthly',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
          notes: '',
          allowedPaidWeekendsPerMonth: 4,
          dailyDeductionMultiplier: 1.5,
          expectedDailyHours: 8.0,
          overtimeMultiplier: 1.5,
          outstandingBalance: 1200.0, // Set outstanding balance directly
        );

        final logs = <AttendanceEntity>[
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 17, 0),
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
        ];

        // Absences = 0. Allowed paid weekends = 4. Unused weekends = 4 days.
        // Weekend bonus hours = 4 * 8.0 = 32.0 hours.
        // Overtime comp = 32.0 * 37.5 = 1200.0.
        // Net salary before outstanding balance = 6000.0 + 1200.0 = 7200.0.
        // Net salary after outstanding balance = 7200.0 - 1200.0 = 6000.0.
        final result = MonthlyPayrollCalculator.calculate(
          employee: employeeWithDebt,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 6000.0);
        expect(result['unpaidOvertimeHours'], 32.0);
        expect(result['pendingOvertimeComp'], 1200.0);
        expect(result['netSalary'], 6000.0); // 7200 - 1200 debt
        expect(result['attendedDays'], 1);
        expect(result['absentDays'], 0.0);
        expect(result['unpaidDays'], 0.0);
      },
    );

    test(
      'Should handle custom overtime and custom deduction rate overrides',
      () {
        final customEmployee = EmployeeEntity(
          id: 'emp1',
          uid: 'user123',
          name: 'John Doe',
          phone: '123456',
          role: 'Engineer',
          salaryAmount: 6000.0,
          salaryType: 'monthly',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
          notes: '',
          allowedPaidWeekendsPerMonth: 4,
          dailyDeductionMultiplier: 1.5,
          expectedDailyHours: 8.0,
          overtimeMultiplier: 1.5,
          outstandingBalance: 0.0,
          customOvertimeRate: 50.0,
          customDeductionRate: 30.0,
        );

        final logs = <AttendanceEntity>[
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 17, 0),
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 2.0,
            lateMinutes: 0,
            notes: '',
            deductionHours: 1.5,
          ),
        ];

        // Unused weekends = 4.
        // Weekend bonus hours = 4 * 8 = 32 hours.
        // Total overtime hours = 2.0 (actual) + 32.0 (weekend) = 34.0 hours.
        // Overtime comp = 34.0 * 50.0 (custom rate) = 1700.0.
        // Deductions = 1.5 hours * 30.0 (custom rate) = 45.0.
        // Net salary = 6000.0 + 1700.0 - 45.0 = 7655.0.
        final result = MonthlyPayrollCalculator.calculate(
          employee: customEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 6000.0);
        expect(result['unpaidOvertimeHours'], 34.0);
        expect(result['pendingOvertimeComp'], 1700.0);
        expect(result['pendingDeductions'], 45.0);
        expect(result['netSalary'], 7655.0);
        expect(result['attendedDays'], 1);
        expect(result['absentDays'], 0.0);
        expect(result['unpaidDays'], 0.0);
      },
    );
  });
}
