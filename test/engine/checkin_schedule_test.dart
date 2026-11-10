import 'package:cooloff/engine/checkin_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nine = CheckinSchedule.defaultMinutesOfDay;

  test('an evening send is asked about the next morning', () {
    final due = CheckinSchedule.dueAt(DateTime(2026, 11, 9, 21, 15), nine);
    expect(due, DateTime(2026, 11, 10, 9));
  });

  test('a send just before the check-in time waits for the next day', () {
    final due = CheckinSchedule.dueAt(DateTime(2026, 11, 9, 8, 30), nine);
    expect(due, DateTime(2026, 11, 10, 9));
  });

  test('a send in the early hours is asked the same morning', () {
    final due = CheckinSchedule.dueAt(DateTime(2026, 11, 9, 1), nine);
    expect(due, DateTime(2026, 11, 9, 9));
  });

  test('crosses month ends', () {
    final due = CheckinSchedule.dueAt(DateTime(2026, 11, 30, 22), nine);
    expect(due, DateTime(2026, 12, 1, 9));
  });

  test('is due from the check-in time until it expires', () {
    final sent = DateTime(2026, 11, 9, 21);
    expect(
      CheckinSchedule.isDue(sent, nine, DateTime(2026, 11, 10, 8, 59)),
      isFalse,
    );
    expect(
      CheckinSchedule.isDue(sent, nine, DateTime(2026, 11, 10, 9)),
      isTrue,
    );
    expect(
      CheckinSchedule.isDue(sent, nine, DateTime(2026, 11, 13, 9)),
      isFalse,
    );
  });
}
