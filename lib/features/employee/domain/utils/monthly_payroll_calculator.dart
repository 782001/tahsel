import 'package:tahsel/features/employee/domain/entities/attendance_entity.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/domain/entities/payroll_entity.dart';

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
      periodStart = DateTime(
        ref.year,
        ref.month,
        clampedClosing,
      ).add(const Duration(days: 1));
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

    // New monthly-specific metrics
    int totalDaysInPeriod = 0;
    int workedDays = 0;
    int missingDays = 0;
    int allowedOffDays = 0;
    int bonusDays = 0;
    int deductionDays = 0;
    double bonusHours = 0.0;

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

      // For monthly employees, only include completed attendance records
      // (absent/excused records are kept for HR tracking but NOT used for payroll calc)
      if (employee.salaryType == 'monthly') {
        if (log.status == 'absent' || log.status == 'excused') return false;
        if (log.checkOut == null) return false;
        return true;
      }

      if (log.status == 'absent' || log.status == 'excused') return true;
      if (log.checkOut == null) return false;
      return true;
    }).toList();

    final salaryType = employee.salaryType;
    final baseAmount = employee.salaryAmount;
    final dailyHours = employee.expectedDailyHours;
    final otMultiplier = employee.overtimeMultiplier;

    // Calculate total days in the payroll period (used for monthly).
    totalDaysInPeriod = period.end.difference(period.start).inDays + 1;

    double overtimeHourlyRate = 10.0;
    if (employee.customOvertimeRate != null) {
      overtimeHourlyRate = employee.customOvertimeRate!;
    } else {
      if (salaryType == 'monthly') {
        // ALWAYS use 30-day fixed month contract model for financial rates
        overtimeHourlyRate = baseAmount / (30.0 * dailyHours) * otMultiplier;
      } else if (salaryType == 'daily') {
        overtimeHourlyRate = baseAmount / dailyHours * otMultiplier;
      } else {
        overtimeHourlyRate = baseAmount * otMultiplier;
      }
    }

    if (salaryType == 'hourly') {
      for (final log in unpaidAttendance) {
        if (log.checkOut != null && log.checkIn != null) {
          final workedHrs =
              log.checkOut!.difference(log.checkIn!).inMinutes / 60.0;
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
      // ── MONTHLY EMPLOYEES ──
      // New logic: derive missing days from expected working days.
      // No longer requires explicit absence records for payroll calculation.

      // Count unique worked days (completed attendance: checkIn + checkOut)
      // Only present, late, half_day statuses count.
      workedDays = unpaidAttendance
          .where(
            (log) =>
                log.status == 'present' ||
                log.status == 'late' ||
                log.status == 'half_day',
          )
          .length;

      attendedDays = workedDays;
      allowedOffDays = employee.allowedPaidWeekendsPerMonth;

      // ExpectedWorkingDays = ActualDaysInPeriod - AllowedPaidWeekends
      final int expectedWorkingDays = totalDaysInPeriod - allowedOffDays;

      // MissingDays = ExpectedWorkingDays - WorkedDays
      missingDays = expectedWorkingDays - workedDays;

      unpaidDaysCount = unpaidAttendance.length;
      unpaidAttendanceCount = unpaidAttendance.length;

      if (workedDays == 0) {
        // No confirmed presence — zero everything out.
        pendingBase = 0.0;
        pendingOvertimeComp = 0.0;
        unpaidOvertimeHours = 0.0;
        pendingDeductions = 0.0;
        bonusDays = 0;
        deductionDays = 0;
        bonusHours = 0.0;
        excessAbsentDays = 0.0;
      } else {
        // STEP 1: Start with full monthly salary as base.
        pendingBase = baseAmount;

        // Financial calculations must ALWAYS use 30 days contract model
        final double dailyRate = baseAmount / 30.0;
        final double hourlyRate =
            employee.customDeductionRate ?? (baseAmount / (30.0 * dailyHours));
        final double deductionMultiplier = employee.dailyDeductionMultiplier;

        // STEP 2: Calculate actual overtime/deductions from attendance records.
        double actualOvertimeHours = 0.0;

        for (final log in unpaidAttendance) {
          actualOvertimeHours += log.overtimeHours;
          // Deduction hours from late arrival etc.
          pendingDeductions += log.deductionHours * hourlyRate;
        }

        // Determine bonus or deduction based on missing vs allowed off days.
        if (missingDays > 0) {
          // Excess absences → apply daily deduction multiplier.
          deductionDays = missingDays;
          bonusDays = 0;
          excessAbsentDays = deductionDays.toDouble();
          pendingDeductions += deductionDays * dailyRate * deductionMultiplier;
        } else if (missingDays < 0) {
          // Unused off days / Extra worked days → convert to bonus hours.
          bonusDays = -missingDays;
          deductionDays = 0;
          excessAbsentDays = 0.0;
        } else {
          // Exact match → no bonus, no deduction.
          bonusDays = 0;
          deductionDays = 0;
          excessAbsentDays = 0.0;
        }

        bonusHours = bonusDays * dailyHours;
        unpaidOvertimeHours = actualOvertimeHours + bonusHours;
        pendingOvertimeComp = unpaidOvertimeHours * overtimeHourlyRate;
      }

      // Track total absent days for backwards-compatible map keys
      totalAbsentDays = (totalDaysInPeriod - workedDays).toDouble();
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
      // New monthly-specific keys
      'totalDaysInPeriod': totalDaysInPeriod,
      'workedDays': workedDays,
      'missingDays': missingDays,
      'allowedOffDays': allowedOffDays,
      'bonusDays': bonusDays,
      'deductionDays': deductionDays,
      'bonusHours': bonusHours,
    };
  }

  /// Generates all payroll periods starting from the period containing the
  /// employee's [createdAt] date up to the period containing the [now] date.
  static List<({DateTime start, DateTime end})> getPeriodsSinceCreation({
    required DateTime createdAt,
    required int closingDay,
    required DateTime now,
  }) {
    final List<({DateTime start, DateTime end})> periods = [];

    // Get the period containing createdAt
    var currentPeriod = getPayrollPeriod(
      closingDay: closingDay,
      referenceDate: createdAt,
    );
    final targetPeriod = getPayrollPeriod(
      closingDay: closingDay,
      referenceDate: now,
    );

    // Add periods sequentially until we reach or pass targetPeriod.
    while (currentPeriod.start.isBefore(targetPeriod.start) ||
        currentPeriod.start.isAtSameMomentAs(targetPeriod.start)) {
      periods.add(currentPeriod);
      // To get the next period, start from the day after this period ends.
      final nextDay = currentPeriod.end.add(const Duration(days: 1));
      currentPeriod = getPayrollPeriod(
        closingDay: closingDay,
        referenceDate: nextDay,
      );
    }

    return periods;
  }

  /// Determines if a period is completed based on [now].
  /// A period is completed if the current day is strictly after the period's end date.
  static bool isPeriodCompleted({
    required ({DateTime start, DateTime end}) period,
    required DateTime now,
  }) {
    final todayOnly = DateTime(now.year, now.month, now.day);
    return todayOnly.isAfter(period.end);
  }

  /// Computes the payment window start and end dates for a given period end.
  static ({DateTime start, DateTime end}) getPaymentWindow({
    required DateTime periodEnd,
    required int windowStart,
    required int windowEnd,
  }) {
    final int nextMonth = periodEnd.month == 12 ? 1 : periodEnd.month + 1;
    final int nextMonthYear = periodEnd.month == 12
        ? periodEnd.year + 1
        : periodEnd.year;

    if (windowStart <= windowEnd) {
      final start = DateTime(nextMonthYear, nextMonth, windowStart);
      final end = DateTime(nextMonthYear, nextMonth, windowEnd);
      return (start: start, end: end);
    } else {
      final start = DateTime(periodEnd.year, periodEnd.month, windowStart);
      final end = DateTime(nextMonthYear, nextMonth, windowEnd);
      return (start: start, end: end);
    }
  }

  /// Computes the status of a period based on [now].
  /// Returns one of: 'in_progress', 'waiting_window', 'ready', 'overdue'.
  static String getPeriodStatus({
    required ({DateTime start, DateTime end}) period,
    required int windowStart,
    required int windowEnd,
    required DateTime now,
  }) {
    final todayOnly = DateTime(now.year, now.month, now.day);
    if (todayOnly.isBefore(period.end) ||
        todayOnly.isAtSameMomentAs(period.end)) {
      return 'in_progress';
    }

    final window = getPaymentWindow(
      periodEnd: period.end,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    if (todayOnly.isBefore(window.start)) {
      return 'waiting_window';
    } else if (todayOnly.isAfter(window.end)) {
      return 'overdue';
    } else {
      return 'ready';
    }
  }

  /// Returns a list of completed periods since the employee was created that have not been paid yet.
  static List<({DateTime start, DateTime end})> getUnpaidCompletedPeriods({
    required EmployeeEntity employee,
    required List<PayrollEntity> payrollLogs,
    required DateTime now,
  }) {
    if (employee.salaryType != 'monthly') return [];

    final allPeriods = getPeriodsSinceCreation(
      createdAt: employee.createdAt,
      closingDay: employee.payrollClosingDay,
      now: now,
    );

    final completedPeriods = allPeriods
        .where((p) => isPeriodCompleted(period: p, now: now))
        .toList();

    // A completed period is unpaid if there's no payroll log matching its start & end dates.
    final unpaidPeriods = completedPeriods.where((p) {
      final isPaid = payrollLogs.any((log) {
        if (log.periodStart != null && log.periodEnd != null) {
          return log.periodStart!.year == p.start.year &&
              log.periodStart!.month == p.start.month &&
              log.periodStart!.day == p.start.day &&
              log.periodEnd!.year == p.end.year &&
              log.periodEnd!.month == p.end.month &&
              log.periodEnd!.day == p.end.day;
        } else {
          // Fallback to monthKey match for legacy records
          final String logMonthKey = log.monthKey; // Format: 'yyyy-MM'
          final String expectedMonthKey =
              "${p.end.year}-${p.end.month.toString().padLeft(2, '0')}";
          return logMonthKey == expectedMonthKey;
        }
      });
      return !isPaid;
    }).toList();

    return unpaidPeriods;
  }
}
