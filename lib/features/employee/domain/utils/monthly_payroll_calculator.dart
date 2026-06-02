import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';

class MonthlyPayrollCalculator {
  /// Computes the payroll period (start → end) for a given [referenceDate]
  /// based on the employee's [payrollClosingDay].
  ///
  /// Example: if closingDay = 25 and referenceDate = 2026-05-10:
  ///   periodStart = 2026-04-26, periodEnd = 2026-05-25
  ///
  /// If closingDay = 25 and referenceDate = 2026-05-28:
  ///   periodStart = 2026-05-26, periodEnd = 2026-06-25
  static ({DateTime start, DateTime end}) getPayrollPeriod({
    required int closingDay,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final clampedClosing = closingDay.clamp(1, 28);

    DateTime periodEnd;
    DateTime periodStart;

    if (ref.day <= clampedClosing) {
      // We are still within the period that ends this month.
      periodEnd = DateTime(ref.year, ref.month, clampedClosing);
      // Period started the day after the closing day of the previous month.
      final prevMonth = DateTime(ref.year, ref.month - 1, clampedClosing);
      periodStart = prevMonth.add(const Duration(days: 1));
    } else {
      // We have passed the closing day — we are in the next period.
      final nextMonth = DateTime(ref.year, ref.month + 1, clampedClosing);
      periodEnd = nextMonth;
      periodStart = DateTime(ref.year, ref.month, clampedClosing)
          .add(const Duration(days: 1));
    }

    return (start: periodStart, end: periodEnd);
  }

  /// Pure domain function to calculate pending salary based on contract type
  /// and confirmed attendance records.
  static Map<String, dynamic> calculate({
    required EmployeeEntity employee,
    required List<AttendanceEntity> attendanceLogs,
    DateTime? referenceDate,
  }) {
    double pendingBase = 0.0;
    double pendingOvertimeComp = 0.0;
    double unpaidOvertimeHours = 0.0;
    double unpaidWorkedHours = 0.0;
    double pendingDeductions = 0.0;
    int unpaidDaysCount = 0;
    int unpaidAttendanceCount = 0;
    int attendedDays = 0;
    double totalAbsentDays = 0.0;
    double excessAbsentDays = 0.0;

    final period = getPayrollPeriod(
      closingDay: employee.payrollClosingDay,
      referenceDate: referenceDate,
    );

    // Filter attendance to only include records that haven't been paid yet
    // AND are finalized (checked out, or absent/excused which have no checkout)
    // AND for monthly employees, fall within the current payroll period.
    final unpaidAttendance = attendanceLogs.where((log) {
      if (log.isPaid) return false;

      if (employee.salaryType == 'monthly') {
        final parts = log.date.split('-');
        final logDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        if (logDate.isBefore(period.start) || logDate.isAfter(period.end)) {
          return false;
        }
      }

      if (log.status == 'absent' || log.status == 'excused') return true;
      if (log.checkOut == null) return false;
      return true;
    }).toList();

    final salaryType = employee.salaryType;
    final baseAmount = employee.salaryAmount;
    final dailyHours = employee.expectedDailyHours;
    final otMultiplier = employee.overtimeMultiplier;

    // Monthly employees use a FIXED 30-day contract model.
    // workingDaysPerMonth is removed; we always use 30.
    const int fixedMonthDays = 30;

    double overtimeHourlyRate = 10.0;
    if (employee.customOvertimeRate != null) {
      overtimeHourlyRate = employee.customOvertimeRate!;
    } else {
      if (salaryType == 'monthly') {
        overtimeHourlyRate =
            baseAmount / (fixedMonthDays * dailyHours) * otMultiplier;
      } else if (salaryType == 'daily') {
        overtimeHourlyRate = baseAmount / dailyHours * otMultiplier;
      } else {
        overtimeHourlyRate = baseAmount * otMultiplier;
      }
    }

    if (salaryType == 'hourly') {
      for (final log in unpaidAttendance) {
        if (log.checkOut != null) {
          final workedHrs =
              log.checkOut!.difference(log.checkIn).inMinutes / 60.0;
          unpaidWorkedHours += workedHrs;
          pendingBase += workedHrs * baseAmount;
          unpaidAttendanceCount++;
        }
      }
    } else if (salaryType == 'daily') {
      for (final log in unpaidAttendance) {
        unpaidDaysCount++;
        unpaidAttendanceCount++;
        if (log.status == 'present' || log.status == 'late') {
          pendingBase += baseAmount;
        } else if (log.status == 'half_day') {
          pendingBase += baseAmount * 0.5;
        }
        unpaidOvertimeHours += log.overtimeHours;
        pendingOvertimeComp += log.overtimeHours * overtimeHourlyRate;

        double hourlyRate =
            employee.customDeductionRate ?? (baseAmount / dailyHours);
        pendingDeductions += log.deductionHours * hourlyRate;
      }
    } else {
      // Check if any confirmed presence (present, late, half_day) exists.
      // If no confirmed presence exists, base salary, overtime and deductions are 0.
      final bool hasConfirmedPresence = unpaidAttendance.any(
        (log) => log.status == 'present' || log.status == 'late' || log.status == 'half_day',
      );

      // Compute monthly metrics
      attendedDays = unpaidAttendance.where(
        (log) => log.status == 'present' || log.status == 'late' || log.status == 'half_day',
      ).length;

      for (final log in unpaidAttendance) {
        if (log.status == 'absent') {
          totalAbsentDays += 1.0;
        } else if (log.status == 'half_day') {
          totalAbsentDays += 0.5;
        }
      }

      final int allowedPaidWeekends = employee.allowedPaidWeekendsPerMonth;
      excessAbsentDays = (totalAbsentDays > allowedPaidWeekends)
          ? totalAbsentDays - allowedPaidWeekends
          : 0.0;

      unpaidDaysCount = unpaidAttendance.length;
      unpaidAttendanceCount = unpaidAttendance.length;

      if (!hasConfirmedPresence) {
        pendingBase = 0.0;
        pendingOvertimeComp = 0.0;
        unpaidOvertimeHours = 0.0;
        pendingDeductions = 0.0;
      } else {
        // STEP 1: Start with full monthly salary as base.
        pendingBase = baseAmount;

        final double dailyRate = baseAmount / fixedMonthDays;
        final double hourlyRate = employee.customDeductionRate ??
            (baseAmount / (fixedMonthDays * dailyHours));
        final double deductionMultiplier = employee.dailyDeductionMultiplier;

        // STEP 2: Calculate actual overtime/deductions.
        double actualOvertimeHours = 0.0;

        for (final log in unpaidAttendance) {
          actualOvertimeHours += log.overtimeHours;
          // Deduction hours from late arrival etc.
          pendingDeductions += log.deductionHours * hourlyRate;
        }

        // STEP 7: Apply daily deduction multiplier to excess absences.
        pendingDeductions += excessAbsentDays * dailyRate * deductionMultiplier;

        // STEP 5 & 6: Convert unused weekend days to overtime-equivalent bonus hours.
        final double unusedWeekendDays =
            (totalAbsentDays < allowedPaidWeekends)
                ? allowedPaidWeekends - totalAbsentDays
                : 0.0;

        final double weekendBonusHours = unusedWeekendDays * dailyHours;

        unpaidOvertimeHours = actualOvertimeHours + weekendBonusHours;
        pendingOvertimeComp = unpaidOvertimeHours * overtimeHourlyRate;
      }
    }

    final double netSalary =
        pendingBase +
        pendingOvertimeComp -
        pendingDeductions -
        employee.outstandingBalance;

    // Compute the current payroll period for monthly employees.
    DateTime? periodStart;
    DateTime? periodEnd;
    if (salaryType == 'monthly') {
      periodStart = period.start;
      periodEnd = period.end;
    }

    return {
      'pendingBase': pendingBase,
      'pendingOvertimeComp': pendingOvertimeComp,
      'unpaidOvertimeHours': unpaidOvertimeHours,
      'unpaidWorkedHours': unpaidWorkedHours,
      'pendingDeductions': pendingDeductions,
      'unpaidDaysCount': unpaidDaysCount,
      'unpaidCount': unpaidAttendanceCount,
      'netSalary': netSalary < 0 ? 0.0 : netSalary,
      'overtimeRate': overtimeHourlyRate,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'attendedDays': attendedDays,
      'absentDays': totalAbsentDays,
      'unpaidDays': excessAbsentDays,
    };
  }
}
