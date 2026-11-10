/// When the next-morning check-in for a heated send is due (Extra 2).
class CheckinSchedule {
  CheckinSchedule._();

  /// Default check-in time: 9:00 local.
  static const int defaultMinutesOfDay = 9 * 60;

  /// Sends closer to the check-in time than this wait for the next day:
  /// a message sent at 8:30 is asked about tomorrow, not in 30 minutes.
  static const Duration minDelay = Duration(hours: 6);

  /// Check-ins older than this are dropped rather than asked.
  static const Duration expiresAfter = Duration(days: 3);

  /// The first local check-in time ([minutesOfDay] after midnight) at least
  /// [minDelay] after [sentAtLocal].
  static DateTime dueAt(DateTime sentAtLocal, int minutesOfDay) {
    final earliest = sentAtLocal.add(minDelay);
    var due = DateTime(
      sentAtLocal.year,
      sentAtLocal.month,
      sentAtLocal.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
    while (due.isBefore(earliest)) {
      due = DateTime(due.year, due.month, due.day + 1, due.hour, due.minute);
    }
    return due;
  }

  /// Whether a check-in for a send at [sentAtLocal] should show at [nowLocal].
  static bool isDue(DateTime sentAtLocal, int minutesOfDay, DateTime nowLocal) {
    final due = dueAt(sentAtLocal, minutesOfDay);
    return !nowLocal.isBefore(due) && nowLocal.isBefore(due.add(expiresAfter));
  }
}
