/// Domain-layer guard that enforces employee status-based business rules.
///
/// This is the **single source of truth** for which operations are allowed
/// based on an employee's current status (active / suspended / inactive).
///
/// ✔ Consumed by UseCases before executing mutations.
/// ✔ Consumed by the Presentation layer for UI gating.
/// ❌ Never duplicated in Cubits or Widgets.
class EmployeeOperationGuard {
  const EmployeeOperationGuard();

  // ─── permission checks ──────────────────────────────────────────────

  /// Only **active** employees may check in.
  bool canCheckIn(String status) => _isActive(status);

  /// Only **active** employees may check out.
  bool canCheckOut(String status) => _isActive(status);

  /// Only **active** employees may receive salary payments.
  bool canPaySalary(String status) => _isActive(status);

  /// Only **active** employees may request advances.
  bool canRequestAdvance(String status) => _isActive(status);

  /// Only **active** employees may have attendance modifications
  /// (mark absent / excused).
  bool canModifyAttendance(String status) => _isActive(status);

  // ─── helpers ────────────────────────────────────────────────────────

  bool _isActive(String status) => status.toLowerCase() == 'active';

  /// Returns `true` when the employee is suspended.
  bool isSuspended(String status) => status.toLowerCase() == 'suspended';

  /// Returns `true` when the employee is inactive.
  bool isInactive(String status) => status.toLowerCase() == 'inactive';
}
