import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/services/permission_service.dart';

/// Central helper for masking sensitive customer data (phone number,
/// ledger number, tax number, commercial registration) when the current
/// user lacks the [AppPermissions.customersViewPhone] permission.
class CustomerDataMasker {
  CustomerDataMasker._();

  /// Whether current active user has permission to view full customer phone & details.
  /// Owners always return `true`.
  static bool get canViewCustomerPhone =>
      PermissionService.instance.hasPermission(AppPermissions.customersViewPhone);

  /// Masks a phone number (e.g. '01012345678' -> '••••••••••' or '010••••••78' if preserveEdges is true).
  static String maskPhone(String? phone, {bool preserveEdges = false}) {
    if (phone == null || phone.trim().isEmpty) return '';
    final trimmed = phone.trim();
    if (!preserveEdges || trimmed.length < 7) {
      return '•' * trimmed.length.clamp(6, 11);
    }
    final prefix = trimmed.substring(0, 3);
    final suffix = trimmed.substring(trimmed.length - 2);
    final maskedLength = (trimmed.length - 5).clamp(4, 8);
    return '$prefix${'•' * maskedLength}$suffix';
  }

  /// Masks generic confidential text (e.g., ledger number, tax number, CR).
  static String maskGeneric(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final length = value.trim().length.clamp(4, 8);
    return '•' * length;
  }

  /// Returns actual phone if permitted, otherwise masked phone.
  static String formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    if (canViewCustomerPhone) return phone;
    return maskPhone(phone);
  }

  /// Returns actual generic data if permitted, otherwise masked string.
  static String formatGeneric(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    if (canViewCustomerPhone) return value;
    return maskGeneric(value);
  }

  /// Convenience helper for ledger number
  static String formatLedger(String? ledger) => formatGeneric(ledger);
  static String formatCustomerDisplayLedger(String? ledger) => formatGeneric(ledger);

  /// Convenience helper for tax number
  static String formatCustomerDisplayTax(String? tax) => formatGeneric(tax);

  /// Convenience helper for commercial registration
  static String formatCustomerDisplayCr(String? cr) => formatGeneric(cr);

  /// Convenience helper for customer phone
  static String formatCustomerDisplayPhone(String? phone) => formatPhone(phone);
}
