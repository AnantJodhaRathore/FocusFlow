class DurationFormatter {
  DurationFormatter._();

  static String minutesToShortText(int minutes) {
    if (minutes <= 0) return '0m';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';

    return '${hours}h ${remainingMinutes}m';
  }

  static String minutesToLongText(int minutes) {
    if (minutes <= 0) return '0 minutes';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return remainingMinutes == 1 ? '1 minute' : '$remainingMinutes minutes';
    }

    if (remainingMinutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    final hourText = hours == 1 ? '1 hour' : '$hours hours';
    final minuteText = remainingMinutes == 1
        ? '1 minute'
        : '$remainingMinutes minutes';

    return '$hourText $minuteText';
  }
}
