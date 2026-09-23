/// Small date helpers used across the app.
class DateUtilsX {
  DateUtilsX._();

  static DateTime monthStart(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime monthEnd(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  static DateTime addMonths(DateTime date, int months) =>
      DateTime(date.year, date.month + months, 1);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Normalises a date to midnight so day comparisons are stable.
  static DateTime dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// The last [count] months ending at [end] (inclusive), oldest first.
  static List<DateTime> trailingMonths(DateTime end, int count) {
    final months = <DateTime>[];
    for (var i = count - 1; i >= 0; i--) {
      months.add(addMonths(monthStart(end), -i));
    }
    return months;
  }
}
