import 'package:flutter_test/flutter_test.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/payroll_entity.dart';
import 'package:tahsel/features/employee/domain/entities/advance_entity.dart';

void main() {
  group('Employee Management Entities - Equality & Field Checks', () {
    test('EmployeeEntity should match equality props correctly', () {
      final employee1 = EmployeeEntity(
        id: 'emp1',
        uid: 'user_uid_123',
        name: 'Abdalla',
        phone: '1234567890',
        role: 'Senior Developer',
        salaryAmount: 5000.0,
        salaryType: 'monthly',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        notes: 'Lead engineer',
      );

      final employee2 = EmployeeEntity(
        id: 'emp1',
        uid: 'user_uid_123',
        name: 'Abdalla',
        phone: '1234567890',
        role: 'Senior Developer',
        salaryAmount: 5000.0,
        salaryType: 'monthly',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        notes: 'Lead engineer',
      );

      final employee3 = EmployeeEntity(
        id: 'emp2',
        uid: 'user_uid_123',
        name: 'Jane Doe',
        phone: '0987654321',
        role: 'Designer',
        salaryAmount: 4000.0,
        salaryType: 'monthly',
        status: 'inactive',
        createdAt: DateTime(2026, 2, 1),
        notes: 'UI designer',
      );

      expect(employee1, equals(employee2));
      expect(employee1, isNot(equals(employee3)));
      expect(employee1.props.contains('Abdalla'), isTrue);
    });

    test('AttendanceEntity properties and duration calculation', () {
      final checkInTime = DateTime(2026, 5, 18, 9, 0); // 9:00 AM
      final checkOutTime = DateTime(2026, 5, 18, 17, 30); // 5:30 PM (8.5 hours)

      final log = AttendanceEntity(
        id: 'att1',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        checkIn: checkInTime,
        checkOut: checkOutTime,
        date: '2026-05-18',
        status: 'present',
        overtimeHours: 1.5,
        lateMinutes: 10,
        notes: 'Good day',
      );

      expect(log.employeeId, 'emp1');
      expect(log.employeeName, 'Abdalla');
      expect(log.uid, 'user_uid_123');
      expect(log.status, 'present');
      expect(log.overtimeHours, 1.5);
      expect(log.lateMinutes, 10);
      expect(log.notes, 'Good day');

      // Calculate working hours as done in UI
      final diff = log.checkOut != null && log.checkIn != null
          ? log.checkOut!.difference(log.checkIn!).inMinutes / 60.0
          : 0.0;
      expect(diff, equals(8.5));
    });

    test('AttendanceEntity for exception statuses (absent/excused) should support null checkIn and checkOut', () {
      const log = AttendanceEntity(
        id: 'att_exc',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        checkIn: null,
        checkOut: null,
        date: '2026-05-19',
        status: 'absent',
        overtimeHours: 0.0,
        lateMinutes: 0,
        notes: 'Sick leave',
      );

      expect(log.checkIn, isNull);
      expect(log.checkOut, isNull);
      expect(log.status, 'absent');
      expect(log.notes, 'Sick leave');

      final diff = log.checkOut != null && log.checkIn != null
          ? log.checkOut!.difference(log.checkIn!).inMinutes / 60.0
          : 0.0;
      expect(diff, equals(0.0));
    });

    test('PayrollEntity properties equality check', () {
      final paymentDate = DateTime(2026, 5, 18);
      final payroll1 = PayrollEntity(
        id: 'pay1',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        paymentDate: paymentDate,
        amount: 5000.0,
        bonus: 200.0,
        deduction: 50.0,
        overtimeCompensation: 150.0,
        netSalary: 5300.0,
        monthKey: '2026-05',
        notes: 'May 2026 Payment',
      );

      final payroll2 = PayrollEntity(
        id: 'pay1',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        paymentDate: paymentDate,
        amount: 5000.0,
        bonus: 200.0,
        deduction: 50.0,
        overtimeCompensation: 150.0,
        netSalary: 5300.0,
        monthKey: '2026-05',
        notes: 'May 2026 Payment',
      );

      expect(payroll1, equals(payroll2));
      expect(payroll1.netSalary, equals(5300.0));
      expect(payroll1.monthKey, equals('2026-05'));
    });
    group('Attendance Duration Formatting Checks', () {
      test('Should compute 0 if checkout is null', () {
        final log = AttendanceEntity(
          id: 'att2',
          employeeId: 'emp1',
          employeeName: 'Abdalla',
          uid: 'user_uid_123',
          checkIn: DateTime(2026, 5, 18, 9, 0),
          checkOut: null,
          date: '2026-05-18',
          status: 'present',
          overtimeHours: 0.0,
          lateMinutes: 0,
          notes: '',
        );

        final diff = log.checkOut != null && log.checkIn != null
            ? log.checkOut!.difference(log.checkIn!).inMinutes / 60.0
            : 0.0;
        expect(diff, equals(0.0));
      });
    });

    group(
      'Employee Contract Configuration default values and custom overrides',
      () {
        test(
          'Should default to standard contract configurations when none are specified',
          () {
            final employee = EmployeeEntity(
              id: 'emp_defaults',
              uid: 'uid_defaults',
              name: 'Abdalla Defaults',
              phone: '123',
              role: 'Dev',
              salaryAmount: 5000.0,
              salaryType: 'monthly',
              status: 'active',
              createdAt: DateTime(2026, 1, 1),
              notes: '',
            );

            expect(employee.allowedPaidWeekendsPerMonth, 4);
            expect(employee.dailyDeductionMultiplier, 1.0);
            expect(employee.expectedDailyHours, 8.0);
            expect(employee.overtimeMultiplier, 1.5);
            expect(employee.customOvertimeRate, isNull);
            expect(employee.customDeductionRate, isNull);
          },
        );

        test('Should preserve custom contract values when explicitly set', () {
          final employee = EmployeeEntity(
            id: 'emp_custom',
            uid: 'uid_custom',
            name: 'Abdalla Custom',
            phone: '123',
            role: 'Dev',
            salaryAmount: 5000.0,
            salaryType: 'monthly',
            status: 'active',
            createdAt: DateTime(2026, 1, 1),
            notes: '',
            allowedPaidWeekendsPerMonth: 6,
            dailyDeductionMultiplier: 1.5,
            expectedDailyHours: 6.0,
            overtimeMultiplier: 2.0,
            customOvertimeRate: 75.0,
            customDeductionRate: 50.0,
          );

          expect(employee.allowedPaidWeekendsPerMonth, 6);
          expect(employee.dailyDeductionMultiplier, 1.5);
          expect(employee.expectedDailyHours, 6.0);
          expect(employee.overtimeMultiplier, 2.0);
          expect(employee.customOvertimeRate, 75.0);
          expect(employee.customDeductionRate, 50.0);
        });
      },
    );

    test('AdvanceEntity properties and equality check', () {
      final date = DateTime(2026, 5, 18);
      final advance1 = AdvanceEntity(
        id: 'adv1',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        amount: 500.0,
        date: date,
        status: 'unpaid',
        notes: 'Medical emergency',
      );

      final advance2 = AdvanceEntity(
        id: 'adv1',
        employeeId: 'emp1',
        employeeName: 'Abdalla',
        uid: 'user_uid_123',
        amount: 500.0,
        date: date,
        status: 'unpaid',
        notes: 'Medical emergency',
      );

      expect(advance1, equals(advance2));
      expect(advance1.amount, equals(500.0));
      expect(advance1.status, equals('unpaid'));
    });
  });
}
