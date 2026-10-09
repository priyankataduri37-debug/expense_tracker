import 'package:expense_tracker/core/utils/budget_calculator.dart';
import 'package:expense_tracker/core/utils/insights_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 15, 12);

  String fmt(int minor) => 'M$minor';

  final names = {'exp_food': 'Food', 'exp_travel': 'Travel'};
  String name(String id) => names[id] ?? id;

  SpendEntry spend(String category, int minor, DateTime when) => SpendEntry(
    categoryId: category,
    amountMinor: minor,
    occurredAt: when,
  );

  List<Insight> run(List<SpendEntry> expenses, {BudgetStatus? budget}) =>
      generateInsights(
        expenses: expenses,
        now: now,
        categoryName: name,
        formatMoney: fmt,
        overallBudget: budget,
      );

  Insight? find(List<Insight> list, InsightKind kind) {
    for (final i in list) {
      if (i.kind == kind) return i;
    }
    return null;
  }

  test('no spending gives no insights', () {
    expect(run([]), isEmpty);
  });

  group('week vs last week', () {
    test('spending more is reported as a percentage increase', () {
      final result = run([
        spend('exp_food', 1000, DateTime(2026, 7, 3)),
        spend('exp_food', 1200, DateTime(2026, 7, 10)),
      ]);

      final insight = find(result, InsightKind.weekChange)!;
      expect(insight.message, 'You spent 20% more this week than last week.');
      expect(insight.tone, InsightTone.warning);
    });

    test('spending less is reported as a percentage decrease', () {
      final result = run([
        spend('exp_food', 1000, DateTime(2026, 7, 3)),
        spend('exp_food', 880, DateTime(2026, 7, 10)),
      ]);

      final insight = find(result, InsightKind.weekChange)!;
      expect(insight.message, 'You spent 12% less this week than last week.');
      expect(insight.tone, InsightTone.good);
    });

    test('is skipped when last week had no spending', () {
      final result = run([spend('exp_food', 500, DateTime(2026, 7, 10))]);

      expect(find(result, InsightKind.weekChange), isNull);
    });
  });

  group('this month vs last month', () {
    test('only compares the same number of days', () {
      final result = run([
        spend('exp_food', 1200, DateTime(2026, 7, 5)),
        spend('exp_food', 1000, DateTime(2026, 6, 5)),
        spend('exp_food', 9000, DateTime(2026, 6, 25)),
      ]);

      final insight = find(result, InsightKind.monthChange)!;
      expect(insight.message,
          'Your spending increased by 20% compared with last month.');
      expect(insight.tone, InsightTone.warning);
    });

    test('spending less is reported as a decrease', () {
      final result = run([
        spend('exp_food', 880, DateTime(2026, 7, 5)),
        spend('exp_food', 1000, DateTime(2026, 6, 5)),
      ]);

      final insight = find(result, InsightKind.monthChange)!;
      expect(insight.message,
          'Your spending decreased by 12% compared with last month.');
      expect(insight.tone, InsightTone.good);
    });
  });

  group('highest expense category', () {
    test('picks the category with the largest total this month', () {
      final result = run([
        spend('exp_food', 500, DateTime(2026, 7, 3)),
        spend('exp_travel', 300, DateTime(2026, 7, 5)),
        spend('exp_food', 200, DateTime(2026, 7, 6)),
      ]);

      expect(
        find(result, InsightKind.topCategory)!.message,
        'Food is your highest expense category this month.',
      );
    });

    test('a tie gives the same answer whatever the order', () {
      final a = spend('exp_a', 100, DateTime(2026, 7, 3));
      final b = spend('exp_b', 100, DateTime(2026, 7, 4));

      final first = find(run([a, b]), InsightKind.topCategory)!.message;
      final second = find(run([b, a]), InsightKind.topCategory)!.message;

      expect(first, second);
      expect(first, 'exp_a is your highest expense category this month.');
    });

    test('spending from last month is not counted', () {
      final result = run([spend('exp_food', 5000, DateTime(2026, 6, 20))]);

      expect(find(result, InsightKind.topCategory), isNull);
    });
  });

  test('average daily spending is the month total divided by days elapsed', () {
    final result = run([
      spend('exp_food', 3000, DateTime(2026, 7, 2)),
      spend('exp_food', 1500, DateTime(2026, 7, 10)),
    ]);

    expect(
      find(result, InsightKind.dailyAverage)!.message,
      'Your average daily spending this month is M300.',
    );
  });

  group('budget insight', () {
    test('75% used gives a warning', () {
      final result = run(
        [],
        budget: calculateBudget(budgetMinor: 10000, spentMinor: 7500),
      );

      final insight = result.first;
      expect(insight.kind, InsightKind.budget);
      expect(insight.message, 'You have used 75% of your July budget.');
      expect(insight.tone, InsightTone.warning);
    });

    test('50% used is only informational', () {
      final result = run(
        [],
        budget: calculateBudget(budgetMinor: 10000, spentMinor: 5000),
      );

      expect(result.first.tone, InsightTone.info);
    });

    test('going over budget says by how much', () {
      final result = run(
        [],
        budget: calculateBudget(budgetMinor: 10000, spentMinor: 12500),
      );

      expect(result.first.message, 'Budget exceeded by M2500.');
    });

    test('well within budget gives no budget insight', () {
      final result = run(
        [],
        budget: calculateBudget(budgetMinor: 10000, spentMinor: 1000),
      );

      expect(find(result, InsightKind.budget), isNull);
    });
  });
}