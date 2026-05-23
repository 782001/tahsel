import 'package:intl/intl.dart';

class SummaryHelper {
  static String getDailyKey(DateTime date) {
    return 'daily_${DateFormat('yyyy-MM-dd').format(date)}';
  }

  static String getWeeklyKey(DateTime date) {
    // We use ISO week number for consistency
    final week = _getIsoWeekNumber(date);
    return 'weekly_${date.year}-$week';
  }

  static String getMonthlyKey(DateTime date) {
    return 'monthly_${DateFormat('yyyy-MM').format(date)}';
  }

  static String getAllTimeKey() {
    return 'all_time';
  }

  static List<String> getSummaryKeys(DateTime date) {
    return [
      getDailyKey(date),
      getWeeklyKey(date),
      getMonthlyKey(date),
      getAllTimeKey(),
    ];
  }

  static int _getIsoWeekNumber(DateTime date) {
    int daysSinceJan1 = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((daysSinceJan1 + DateTime(date.year, 1, 1).weekday - 1) / 7)
            .floor() +
        1;
  }
}
