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
        // Setup: 0 completed attendances in the period
        final logs = <AttendanceEntity>[
          // Non-completed check-in (no check-out) shouldn't count as worked days
          AttendanceEntity(
            id: '1',
            employeeId: 'emp1',
            employeeName: 'John Doe',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: null,
            date: '2026-05-01',
            status: 'present',
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
        expect(result['absentDays'], 30.0); // Derived: 30 days in period - 0 worked
        expect(result['unpaidDays'], 0.0); // Zeroed since workedDays == 0
      },
    );

    test(
      'Steps 2, 3, 5, 6: Should allow full base salary and convert unused weekends to overtime bonus when presence exists and absences < allowed paid weekends',
      () {
        // Setup: Employee has 28 present days (presence verified).
        // Total absences/missing = 30 - 28 = 2 days.
        // Total absences (2) < allowed paid weekends (4).
        // Unused weekends = 4 - 2 = 2 days.
        // Weekend bonus hours = 2 * 8.0 = 16.0 hours.
        // baseAmount = 6000.0. dailyHours = 8.0. period days = 30.
        // overtimeHourlyRate = 6000.0 / (30 * 8.0) * 1.5 = 25.0 * 1.5 = 37.5.
        // Expected overtime compensation = 16.0 * 37.5 = 600.0.
        final logs = List.generate(
          28,
          (index) {
            // Reference date is 2026-05-10, so period starts 2026-04-26 and ends 2026-05-25.
            final day = index < 5 ? (26 + index) : (index - 4);
            final month = index < 5 ? 4 : 5;
            final dateStr = '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, month, day, 9, 0),
              checkOut: DateTime(2026, month, day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

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
        expect(result['attendedDays'], 28);
        expect(result['absentDays'], 2.0);
        expect(result['unpaidDays'], 0.0);
      },
    );

    test(
      'Steps 4, 7: Should apply daily deduction multiplier on excess absences when total absences exceed allowed paid weekends',
      () {
        // Setup: Employee has 24 present days (presence verified).
        // Total absences/missing = 30 - 24 = 6 days.
        // Total absences (6) > allowed paid weekends (4).
        // Excess absences = 6 - 4 = 2 days.
        // dailyRate = 6000 / 30 = 200.0.
        // deductionMultiplier = 1.5.
        // Expected absence deduction = 2 * 200.0 * 1.5 = 600.0.
        // Unused weekends = 0.
        // Overtime hours = 0.
        final logs = List.generate(
          24,
          (index) {
            final day = index < 5 ? (26 + index) : (index - 4);
            final month = index < 5 ? 4 : 5;
            final dateStr = '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, month, day, 9, 0),
              checkOut: DateTime(2026, month, day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

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
        expect(result['attendedDays'], 24);
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

        // Employee attended all 30 days
        final logs = List.generate(
          30,
          (index) {
            final day = index < 5 ? (26 + index) : (index - 4);
            final month = index < 5 ? 4 : 5;
            final dateStr = '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, month, day, 9, 0),
              checkOut: DateTime(2026, month, day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

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
        expect(result['attendedDays'], 30);
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

        // Attended 30 days, first record has 2 hours overtime and 1.5 deduction hours.
        final logs = List.generate(
          30,
          (index) {
            final day = index < 5 ? (26 + index) : (index - 4);
            final month = index < 5 ? 4 : 5;
            final dateStr = '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, month, day, 9, 0),
              checkOut: DateTime(2026, month, day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: index == 0 ? 2.0 : 0.0,
              lateMinutes: 0,
              notes: '',
              deductionHours: index == 0 ? 1.5 : 0.0,
            );
          },
        );

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
        expect(result['attendedDays'], 30);
        expect(result['absentDays'], 0.0);
        expect(result['unpaidDays'], 0.0);
      },
    );

    test(
      'Edge Case: 31-day period should use actual period for expectedWorkingDays but 30-day model for financial rates',
      () {
        // Period: 2026-07-26 to 2026-08-25 = 31 days
        // closingDay = 25, referenceDate = 2026-08-10
        // expectedWorkingDays = 31 - 4 = 27
        // Employee worked 27 days → missingDays = 0, no bonus, no deduction
        // Overtime rate uses 30-day model: 6000 / (30 * 8) * 1.5 = 37.5
        final logs = List.generate(
          27,
          (index) {
            // Spread across 2026-07-26 to 2026-08-21
            final date = DateTime(2026, 7, 26).add(Duration(days: index));
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(date.year, date.month, date.day, 9, 0),
              checkOut: DateTime(date.year, date.month, date.day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 8, 10),
        );

        expect(result['totalDaysInPeriod'], 31);
        expect(result['workedDays'], 27);
        expect(result['missingDays'], 0); // 27 - 27
        expect(result['bonusDays'], 0);
        expect(result['deductionDays'], 0);
        expect(result['pendingBase'], 6000.0);
        expect(result['pendingDeductions'], 0.0);
        expect(result['pendingOvertimeComp'], 0.0);
        expect(result['netSalary'], 6000.0);
        // Verify financial rate uses 30-day model
        expect(result['overtimeRate'], 6000.0 / (30.0 * 8.0) * 1.5);
      },
    );

    test(
      'Edge Case: 28-day period (Feb) with deductions should use 30-day daily rate',
      () {
        // Period: 2026-02-26 to 2026-03-25 = 28 days (Feb has 28 days in 2026)
        // closingDay = 25, referenceDate = 2026-03-10 (within period)
        // expectedWorkingDays = 28 - 4 = 24
        // Employee worked 22 days → missingDays = 24 - 22 = 2
        // dailyRate = 6000 / 30 = 200.0 (NOT 6000/28)
        // deduction = 2 * 200 * 1.5 = 600.0
        final logs = List.generate(
          22,
          (index) {
            final date = DateTime(2026, 2, 26).add(Duration(days: index));
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(date.year, date.month, date.day, 9, 0),
              checkOut: DateTime(date.year, date.month, date.day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 3, 10),
        );

        expect(result['totalDaysInPeriod'], 28);
        expect(result['workedDays'], 22);
        expect(result['missingDays'], 2); // 24 - 22
        expect(result['deductionDays'], 2);
        expect(result['bonusDays'], 0);
        // dailyRate = 6000/30 = 200.0 (NOT 6000/28)
        expect(result['pendingDeductions'], 600.0); // 2 * 200 * 1.5
        expect(result['pendingBase'], 6000.0);
        expect(result['netSalary'], 5400.0); // 6000 - 600
      },
    );

    test(
      'Edge Case: 31-day period with bonus days converts extra worked days to overtime',
      () {
        // Period: 31 days, allowedOffDays = 4
        // expectedWorkingDays = 31 - 4 = 27
        // Employee worked 29 days → missingDays = 27 - 29 = -2
        // bonusDays = 2, bonusHours = 2 * 8 = 16
        // overtimeRate = 6000 / (30 * 8) * 1.5 = 37.5
        // overtimeComp = 16 * 37.5 = 600.0
        final logs = List.generate(
          29,
          (index) {
            final date = DateTime(2026, 7, 26).add(Duration(days: index));
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(date.year, date.month, date.day, 9, 0),
              checkOut: DateTime(date.year, date.month, date.day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 8, 10),
        );

        expect(result['totalDaysInPeriod'], 31);
        expect(result['workedDays'], 29);
        expect(result['missingDays'], -2); // 27 - 29
        expect(result['bonusDays'], 2);
        expect(result['deductionDays'], 0);
        expect(result['bonusHours'], 16.0); // 2 * 8
        expect(result['pendingOvertimeComp'], 600.0); // 16 * 37.5
        expect(result['pendingBase'], 6000.0);
        expect(result['netSalary'], 6600.0); // 6000 + 600
      },
    );

    test(
      'Edge Case: Exact match — workedDays equals expectedWorkingDays yields zero bonus/deduction',
      () {
        // Period: 30 days, allowedOffDays = 4
        // expectedWorkingDays = 30 - 4 = 26
        // Employee worked exactly 26 days → missingDays = 0
        final logs = List.generate(
          26,
          (index) {
            final day = index < 5 ? (26 + index) : (index - 4);
            final month = index < 5 ? 4 : 5;
            final dateStr =
                '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            return AttendanceEntity(
              id: 'att_$index',
              employeeId: 'emp1',
              employeeName: 'John Doe',
              uid: 'user123',
              checkIn: DateTime(2026, month, day, 9, 0),
              checkOut: DateTime(2026, month, day, 17, 0),
              date: dateStr,
              status: 'present',
              overtimeHours: 0.0,
              lateMinutes: 0,
              notes: '',
            );
          },
        );

        final result = MonthlyPayrollCalculator.calculate(
          employee: monthlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['totalDaysInPeriod'], 30);
        expect(result['workedDays'], 26);
        expect(result['missingDays'], 0); // 26 - 26
        expect(result['bonusDays'], 0);
        expect(result['deductionDays'], 0);
        expect(result['bonusHours'], 0.0);
        expect(result['pendingBase'], 6000.0);
        expect(result['pendingOvertimeComp'], 0.0);
        expect(result['pendingDeductions'], 0.0);
        expect(result['netSalary'], 6000.0);
      },
    );
  });

  group('Daily and Hourly Payroll Calculation Tests', () {
    test(
      'Daily Employee: Should calculate base, overtime, and deductions correctly per day',
      () {
        final dailyEmployee = EmployeeEntity(
          id: 'emp_daily',
          uid: 'user123',
          name: 'Daily worker',
          phone: '123456',
          role: 'Technician',
          salaryAmount: 200.0, // daily rate
          salaryType: 'daily',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
          notes: '',
          allowedPaidWeekendsPerMonth: 0,
          dailyDeductionMultiplier: 1.0,
          expectedDailyHours: 8.0,
          overtimeMultiplier: 1.5,
          outstandingBalance: 0.0,
        );

        final logs = [
          AttendanceEntity(
            id: 'd1',
            employeeId: 'emp_daily',
            employeeName: 'Daily worker',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 19, 0), // 8 regular + 2 overtime
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 2.0,
            lateMinutes: 0,
            notes: '',
            deductionHours: 1.0, // 1 hour deduction
          ),
          AttendanceEntity(
            id: 'd2',
            employeeId: 'emp_daily',
            employeeName: 'Daily worker',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 2, 9, 0),
            checkOut: DateTime(2026, 5, 2, 13, 0),
            date: '2026-05-02',
            status: 'half_day',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
        ];

        // Overtime rate: baseAmount (200) / dailyHours (8) * overtimeMultiplier (1.5) = 25 * 1.5 = 37.5
        // Overtime comp: 2.0 * 37.5 = 75.0
        // Base salary: 200.0 (present) + 100.0 (half_day) = 300.0
        // Deduction hourly rate: baseAmount (200) / dailyHours (8) = 25.0
        // Deductions: 1.0 * 25.0 = 25.0
        // Net Salary: 300.0 (base) + 75.0 (overtime) - 25.0 (deduction) = 350.0

        final result = MonthlyPayrollCalculator.calculate(
          employee: dailyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 300.0);
        expect(result['unpaidOvertimeHours'], 2.0);
        expect(result['pendingOvertimeComp'], 75.0);
        expect(result['pendingDeductions'], 25.0);
        expect(result['netSalary'], 350.0);
      },
    );

    test(
      'Hourly Employee: Should calculate base correctly based on worked hours',
      () {
        final hourlyEmployee = EmployeeEntity(
          id: 'emp_hourly',
          uid: 'user123',
          name: 'Hourly worker',
          phone: '123456',
          role: 'Parttime',
          salaryAmount: 25.0, // hourly rate
          salaryType: 'hourly',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
          notes: '',
          allowedPaidWeekendsPerMonth: 0,
          dailyDeductionMultiplier: 1.0,
          expectedDailyHours: 8.0,
          overtimeMultiplier: 1.5,
          outstandingBalance: 50.0, // outstanding balance
        );

        final logs = [
          AttendanceEntity(
            id: 'h1',
            employeeId: 'emp_hourly',
            employeeName: 'Hourly worker',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 1, 9, 0),
            checkOut: DateTime(2026, 5, 1, 13, 0), // 4 hours worked
            date: '2026-05-01',
            status: 'present',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
          AttendanceEntity(
            id: 'h2',
            employeeId: 'emp_hourly',
            employeeName: 'Hourly worker',
            uid: 'user123',
            checkIn: DateTime(2026, 5, 2, 9, 0),
            checkOut: DateTime(2026, 5, 2, 15, 0), // 6 hours worked
            date: '2026-05-02',
            status: 'present',
            overtimeHours: 0.0,
            lateMinutes: 0,
            notes: '',
          ),
        ];

        // Worked hours: 4.0 + 6.0 = 10.0 hours
        // Base salary: 10.0 * 25.0 = 250.0
        // Outstanding balance: 50.0
        // Net Salary: 250.0 - 50.0 = 200.0

        final result = MonthlyPayrollCalculator.calculate(
          employee: hourlyEmployee,
          attendanceLogs: logs,
          referenceDate: DateTime(2026, 5, 10),
        );

        expect(result['pendingBase'], 250.0);
        expect(result['unpaidWorkedHours'], 10.0);
        expect(result['netSalary'], 200.0);
      },
    );
  });
}
