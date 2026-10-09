import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/enums.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._db, {required this._userId});

  final AppDatabase _db;
  final String Function() _userId;

  Future<List<TransactionRow>> getTransactions({
    required DateTime start,
    required DateTime end,
  }) {
    final query = _db.select(_db.transactions)
      ..where(
        (t) =>
            t.userId.equals(_userId()) &
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(start) &
            t.occurredAt.isSmallerThanValue(end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]);

    return query.get();
  }

  Future<Map<String, String>> getCategoryNames() async {
    final rows = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull())).get();

    return {for (final row in rows) row.id: row.name};
  }

  Future<AnalyticsSummary> getSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final transactions = await getTransactions(start: start, end: end);

    var income = 0;
    var expense = 0;

    final categoryExpenses = <String, int>{};

    for (final transaction in transactions) {
      if (transaction.type == TxType.income) {
        income += transaction.amountMinor;
      } else {
        expense += transaction.amountMinor;

        categoryExpenses.update(
          transaction.categoryId,
          (value) => value + transaction.amountMinor,
          ifAbsent: () => transaction.amountMinor,
        );
      }
    }

    return AnalyticsSummary(
      incomeMinor: income,
      expenseMinor: expense,
      categoryExpenses: categoryExpenses,
      transactionCount: transactions.length,
      transactions: transactions,
    );
  }
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.categoryExpenses,
    required this.transactionCount,
    required this.transactions,
  });

  final int incomeMinor;
  final int expenseMinor;
  final Map<String, int> categoryExpenses;
  final int transactionCount;
  final List<TransactionRow> transactions;

  int get netSavings => incomeMinor - expenseMinor;

  double get savingsRate {
    if (incomeMinor == 0) return 0;

    return netSavings / incomeMinor;
  }

  int get highestCategoryExpense {
    if (categoryExpenses.isEmpty) return 0;

    return categoryExpenses.values.reduce((a, b) => a > b ? a : b);
  }

  String? get highestExpenseCategoryId {
    if (categoryExpenses.isEmpty) return null;

    return categoryExpenses.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}
