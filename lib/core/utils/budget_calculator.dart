enum BudgetLevel { ok, reached50, reached75, reached90, reached100, over }

class BudgetStatus {
  const BudgetStatus._(this.budgetMinor, this.spentMinor);

  final int budgetMinor;
  final int spentMinor;

  int get remainingMinor =>
      budgetMinor > spentMinor ? budgetMinor - spentMinor : 0;

  int get overByMinor =>
      spentMinor > budgetMinor ? spentMinor - budgetMinor : 0;

  double get percentUsed => spentMinor * 100 / budgetMinor;

  int get wholePercent => spentMinor * 100 ~/ budgetMinor;

  double get progress => (spentMinor / budgetMinor).clamp(0.0, 1.0).toDouble();

  BudgetLevel get level {
    final used = spentMinor * 100;
    if (spentMinor > budgetMinor) return BudgetLevel.over;
    if (used >= budgetMinor * 100) return BudgetLevel.reached100;
    if (used >= budgetMinor * 90) return BudgetLevel.reached90;
    if (used >= budgetMinor * 75) return BudgetLevel.reached75;
    if (used >= budgetMinor * 50) return BudgetLevel.reached50;
    return BudgetLevel.ok;
  }

  String? message({
    required String monthName,
    required String Function(int minor) formatMoney,
    String? categoryName,
  }) {
    final subject = categoryName == null
        ? '$monthName budget'
        : '$monthName $categoryName budget';

    switch (level) {
      case BudgetLevel.ok:
        return null;
      case BudgetLevel.over:
        final what = categoryName == null ? 'Budget' : '$categoryName budget';
        return '$what exceeded by ${formatMoney(overByMinor)}.';
      case BudgetLevel.reached50:
      case BudgetLevel.reached75:
      case BudgetLevel.reached90:
      case BudgetLevel.reached100:
        return 'You have used $wholePercent% of your $subject.';
    }
  }
}

BudgetStatus calculateBudget({
  required int budgetMinor,
  required int spentMinor,
}) {
  if (budgetMinor <= 0) throw ArgumentError('Budget must be positive');
  if (spentMinor < 0) throw ArgumentError('Spent cannot be negative');
  return BudgetStatus._(budgetMinor, spentMinor);
}