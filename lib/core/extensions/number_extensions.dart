import 'package:intl/intl.dart';

extension NumberExtensions on num {
  /// Formats the number as a currency string.
  /// Example: 1500.5.toCurrency(symbol: '\$') // $1,500.50
  String toCurrency({String symbol = '\$', int decimalDigits = 2}) {
    final format = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return format.format(this);
  }

  /// Formats the number in a smart way:
  /// - Compact if very large (e.g. 1.2M)
  /// - Fixed decimals if small
  String toSmartAmount({int decimalDigits = 1}) {
    if (this >= 1000000 || this <= -1000000) {
      return NumberFormat.compact().format(this);
    }
    return toStringAsFixed(decimalDigits);
  }

  /// Adds a delay of the given number in seconds.
  /// Example: await 2.delay(); // wait 2 seconds
  Future<void> delay() => Future.delayed(Duration(seconds: toInt()));

  /// Adds a delay of the given number in milliseconds.
  /// Example: await 500.delayMilliseconds(); // wait 500 milliseconds
  Future<void> delayMilliseconds() =>
      Future.delayed(Duration(milliseconds: toInt()));
}
