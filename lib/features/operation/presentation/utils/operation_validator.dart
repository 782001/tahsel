import 'package:tahsel/core/utils/app_strings.dart';

class OperationValidator {
  static String? validateCustomerName({
    required String? name,
    required double totalAmount,
    required double paidAmount,
  }) {
    final trimmedName = name?.trim() ?? '';
    if (paidAmount > totalAmount) {
      return AppStrings.validationInvalidAmount;
    }

    final hasDebt = totalAmount > paidAmount;

    if (hasDebt && trimmedName.isEmpty) {
      return AppStrings.validationCustomerNameDebtRequired;
    }
    
    return null;
  }
}
