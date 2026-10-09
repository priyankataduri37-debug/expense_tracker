import 'package:expense_tracker/core/utils/recurrence.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily moves one day and keeps the time', () {
    final next = nextOccurrence(DateTime(2026, 7, 15, 9, 30),
        RecurrenceFrequency.daily, DateTime(2026, 7, 15, 9, 30));
    expect(next, DateTime(2026, 7, 16, 9, 30));
  });

  test('weekly moves seven days, across a month end', () {
    final next = nextOccurrence(DateTime(2026, 7, 28),
        RecurrenceFrequency.weekly, DateTime(2026, 7, 28));
    expect(next, DateTime(2026, 8, 4));
  });

  test('monthly keeps the start day and does not drift after a short month', () {
    final anchor = DateTime(2026, 1, 31);

    final feb = nextOccurrence(anchor, RecurrenceFrequency.monthly, anchor);
    expect(feb, DateTime(2026, 2, 28));

    final mar = nextOccurrence(feb, RecurrenceFrequency.monthly, anchor);
    expect(mar, DateTime(2026, 3, 31));
  });

  test('monthly rolls over from December to January', () {
    final anchor = DateTime(2026, 12, 15);
    final next = nextOccurrence(anchor, RecurrenceFrequency.monthly, anchor);
    expect(next, DateTime(2027, 1, 15));
  });

  test('yearly handles 29 February', () {
    final anchor = DateTime(2024, 2, 29);

    final y2025 = nextOccurrence(anchor, RecurrenceFrequency.yearly, anchor);
    expect(y2025, DateTime(2025, 2, 28));

    final y2028 = nextOccurrence(
        DateTime(2027, 2, 28), RecurrenceFrequency.yearly, anchor);
    expect(y2028, DateTime(2028, 2, 29));
  });
}