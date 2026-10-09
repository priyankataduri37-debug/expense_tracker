import '../../data/local/enums.dart';

DateTime nextOccurrence(
    DateTime current,
    RecurrenceFrequency frequency,
    DateTime anchor,
    ) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return DateTime(current.year, current.month, current.day + 1,
          current.hour, current.minute);
    case RecurrenceFrequency.weekly:
      return DateTime(current.year, current.month, current.day + 7,
          current.hour, current.minute);
    case RecurrenceFrequency.monthly:
      return _clamped(current.year, current.month + 1, anchor.day, current);
    case RecurrenceFrequency.yearly:
      return _clamped(current.year + 1, current.month, anchor.day, current);
  }
}

DateTime _clamped(int year, int month, int day, DateTime timeFrom) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day < lastDay ? day : lastDay, timeFrom.hour,
      timeFrom.minute);
}