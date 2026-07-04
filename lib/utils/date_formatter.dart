class DateFormatter {
  DateFormatter._();

  static String yyyyMmDd(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static String ddMmYyyy(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }

  static String time24(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  static String dateTimeShort(DateTime dateTime) {
    return '${ddMmYyyy(dateTime)} ${time24(dateTime)}';
  }
}
