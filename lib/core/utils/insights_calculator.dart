import 'budget_calculator.dart';

enum InsightKind { budget, weekChange, monthChange, topCategory, dailyAverage }

/// Used by the UI to pick an icon and colour.
enum InsightTone { good, info, warning }

class Insight {
  const Insight({
    required this.kind,
    required this.message,
    required this.tone,
  });

  final InsightKind kind;
  final String message;
  final InsightTone tone;
}

/// The only data the calculator needs about one expense. Keeping it this
/// small makes the function easy to test and free of database code.
class SpendEntry {
  const SpendEntry({
    required this.categoryId,
    required this.amountMinor,
    required this.occurredAt,
  });

  final String categoryId;
  final int amountMinor;
  final DateTime occurredAt;
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Sum of expenses with start <= occurredAt < end.
int _sumBetween(List<SpendEntry> list, DateTime start, DateTime end) {
  var total = 0;
  for (final e in list) {
    if (!e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end)) {
      total += e.amountMinor;
    }
  }
  return total;
}

/// Rounded percent change from [before] to [after]. Null if [before] is 0,
/// because a percentage of nothing is meaningless.
int? _percentChange(int before, int after) {
  if (before <= 0) return null;
  return ((after - before) * 100 / before).round();
}

/// Builds the insight sentences from real spending data.
///
/// [expenses] must contain EXPENSE transactions only, and should cover at
/// least from the start of last month up to [now].
/// [overallBudget] is optional; pass it to get the budget insight.
List<Insight> generateInsights({
  required List<SpendEntry> expenses,
  required DateTime now,
  required String Function(String categoryId) categoryName,
  required String Function(int minor) formatMoney,
  BudgetStatus? overallBudget,
}) {
  final insights = <Insight>[];
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  // ---- Budget: reuses the tested budget calculator for the wording ----
  if (overallBudget != null) {
    final text = overallBudget.message(
      monthName: _monthNames[now.month - 1],
      formatMoney: formatMoney,
    );
    if (text != null) {
      insights.add(Insight(
        kind: InsightKind.budget,
        message: text,
        tone: overallBudget.level.index >= BudgetLevel.reached75.index
            ? InsightTone.warning
            : InsightTone.info,
      ));
    }
  }

  // ---- This week vs last week (rolling 7 days, today included) ----
  final thisWeekStart = DateTime(now.year, now.month, now.day - 6);
  final lastWeekStart = DateTime(now.year, now.month, now.day - 13);
  final thisWeek = _sumBetween(expenses, thisWeekStart, tomorrow);
  final lastWeek = _sumBetween(expenses, lastWeekStart, thisWeekStart);
  final weekPct = _percentChange(lastWeek, thisWeek);
  if (weekPct != null && weekPct != 0) {
    insights.add(Insight(
      kind: InsightKind.weekChange,
      message: weekPct > 0
          ? 'You spent $weekPct% more this week than last week.'
          : 'You spent ${weekPct.abs()}% less this week than last week.',
      tone: weekPct > 0 ? InsightTone.warning : InsightTone.good,
    ));
  }

  // ---- This month vs last month ----
  // Compared over the SAME number of days, so on the 5th of the month we
  // do not compare 5 days of spending with a whole month.
  final monthStart = DateTime(now.year, now.month);
  final nextMonthStart = DateTime(now.year, now.month + 1);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final daysInLastMonth = DateTime(now.year, now.month, 0).day;
  final lastMonthCutoff = DateTime(
    lastMonthStart.year,
    lastMonthStart.month,
    (now.day < daysInLastMonth ? now.day : daysInLastMonth) + 1,
  );

  final thisMonthSoFar = _sumBetween(expenses, monthStart, tomorrow);
  final lastMonthSamePeriod =
  _sumBetween(expenses, lastMonthStart, lastMonthCutoff);
  final monthPct = _percentChange(lastMonthSamePeriod, thisMonthSoFar);
  if (monthPct != null && monthPct != 0) {
    insights.add(Insight(
      kind: InsightKind.monthChange,
      message: monthPct > 0
          ? 'Your spending increased by $monthPct% compared with last month.'
          : 'Your spending decreased by ${monthPct.abs()}% compared with last month.',
      tone: monthPct > 0 ? InsightTone.warning : InsightTone.good,
    ));
  }

  // ---- Highest expense category this month ----
  final byCategory = <String, int>{};
  for (final e in expenses) {
    if (!e.occurredAt.isBefore(monthStart) &&
        e.occurredAt.isBefore(nextMonthStart)) {
      byCategory.update(e.categoryId, (v) => v + e.amountMinor,
          ifAbsent: () => e.amountMinor);
    }
  }
  if (byCategory.isNotEmpty) {
    // Highest amount wins; on a tie the smaller id wins, so the result
    // never depends on list order.
    final top = byCategory.entries.reduce((a, b) {
      if (a.value != b.value) return a.value > b.value ? a : b;
      return a.key.compareTo(b.key) <= 0 ? a : b;
    });
    insights.add(Insight(
      kind: InsightKind.topCategory,
      message: '${categoryName(top.key)} is your highest expense category '
          'this month.',
      tone: InsightTone.info,
    ));
  }

  // ---- Average daily spending this month (days elapsed so far) ----
  if (thisMonthSoFar > 0) {
    insights.add(Insight(
      kind: InsightKind.dailyAverage,
      message: 'Your average daily spending this month is '
          '${formatMoney(thisMonthSoFar ~/ now.day)}.',
      tone: InsightTone.info,
    ));
  }

  return insights;
}