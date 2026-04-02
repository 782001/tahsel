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

  /// Adds a delay of the given number in seconds.
  /// Example: await 2.delay(); // wait 2 seconds
  Future<void> delay() => Future.delayed(Duration(seconds: toInt()));

  /// Adds a delay of the given number in milliseconds.
  /// Example: await 500.delayMilliseconds(); // wait 500 milliseconds
  Future<void> delayMilliseconds() =>
      Future.delayed(Duration(milliseconds: toInt()));
}
