import 'package:expense_tracker/core/utils/budget_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

String money(int minor) => '₹${(minor / 100).toStringAsFixed(2)}';

BudgetStatus calc(int budget, int spent) =>
    calculateBudget(budgetMinor: budget, spentMinor: spent);

void main() {
  test('the example from the task: 2000 budget, 1450 spent', () {
    final s = calc(200000, 145000);
    expect(s.remainingMinor, 55000);
    expect(s.percentUsed, 72.5);
    expect(s.wholePercent, 72);
    expect(s.level, BudgetLevel.reached50);
    expect(s.progress, closeTo(0.725, 0.0001));
  });

  test('nothing spent is ok with no message', () {
    final s = calc(100000, 0);
    expect(s.level, BudgetLevel.ok);
    expect(s.percentUsed, 0);
    expect(s.message(monthName: 'October', formatMoney: money), isNull);
  });

  test('levels switch exactly at 50, 75, 90 and 100 percent', () {
    expect(calc(10000, 4999).level, BudgetLevel.ok);
    expect(calc(10000, 5000).level, BudgetLevel.reached50);
    expect(calc(10000, 7499).level, BudgetLevel.reached50);
    expect(calc(10000, 7500).level, BudgetLevel.reached75);
    expect(calc(10000, 8999).level, BudgetLevel.reached75);
    expect(calc(10000, 9000).level, BudgetLevel.reached90);
    expect(calc(10000, 9999).level, BudgetLevel.reached90);
    expect(calc(10000, 10000).level, BudgetLevel.reached100);
    expect(calc(10000, 10001).level, BudgetLevel.over);
  });

  test('exactly 100 percent: nothing left, but not over', () {
    final s = calc(10000, 10000);
    expect(s.remainingMinor, 0);
    expect(s.overByMinor, 0);
    expect(s.progress, 1.0);
  });

  test('over budget: remaining stays 0 and overBy is reported', () {
    final s = calc(200000, 212500);
    expect(s.level, BudgetLevel.over);
    expect(s.remainingMinor, 0);
    expect(s.overByMinor, 12500);
    expect(s.progress, 1.0);
  });

  test('99.9 percent never reads as 100', () {
    final s = calc(100000, 99900);
    expect(s.wholePercent, 99);
    expect(s.level, BudgetLevel.reached90);
  });

  test('warning messages match the task examples', () {
    expect(
      calc(10000, 9000).message(monthName: 'July', formatMoney: money),
      'You have used 90% of your July budget.',
    );
    expect(
      calc(200000, 212500).message(monthName: 'July', formatMoney: money),
      'Budget exceeded by ₹125.00.',
    );
  });

  test('category budgets name the category', () {
    expect(
      calc(
        40000,
        30000,
      ).message(monthName: 'October', categoryName: 'Food', formatMoney: money),
      'You have used 75% of your October Food budget.',
    );
    expect(
      calc(
        40000,
        45000,
      ).message(monthName: 'October', categoryName: 'Food', formatMoney: money),
      'Food budget exceeded by ₹50.00.',
    );
  });

  test('invalid input is rejected', () {
    expect(() => calc(0, 100), throwsArgumentError);
    expect(() => calc(-5, 100), throwsArgumentError);
    expect(() => calc(1000, -1), throwsArgumentError);
  });
}
