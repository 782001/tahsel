import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';

class CurrencyHelper {
  CurrencyHelper._();

  /// Formats a numerical amount to smart format with the active currency symbol (EGP).
  static String formatCurrency(num amount) {
    return '${amount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}';
  }
}
