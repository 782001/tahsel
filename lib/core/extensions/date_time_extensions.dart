import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Formats the DateTime as a string using the provided [pattern].
  /// Example: DateTime.now().format('yyyy-MM-dd') // 2024-05-20
  String format(String pattern) {
    return DateFormat(pattern).format(this);
  }

  /// Formats the date as dd/MM/yyyy.
  /// Example: DateTime.now().toShortDate() // 20/05/2024
  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Checks if the DateTime is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if the DateTime is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Returns true if the DateTime is in the future.
  bool get isFuture => isAfter(DateTime.now());
  
  /// Returns true if the DateTime is in the past.
  bool get isPast => isBefore(DateTime.now());
}
