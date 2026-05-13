import 'package:intl/intl.dart';

class DateFormatter {
  static String formatNumericDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  static String formatNumericMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String formatArabicMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'ar').format(date);
  }

  static String formatLocalizedDate(DateTime date, String locale) {
    if (locale == 'ar') {
      return DateFormat('d MMMM yyyy', 'ar').format(date);
    }
    return DateFormat('MMMM d, yyyy', 'en').format(date);
  }
}
