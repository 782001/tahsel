import 'package:intl/intl.dart';

class DateFormatter {
  static String formatNumericDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static String formatNumericMonth(DateTime date) {
    return DateFormat('yyyy/MM').format(date);
  }
}
