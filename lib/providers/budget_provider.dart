import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/budget_calculator.dart';
import '../data/local/database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/transaction_repository.dart';

/// Combines the saved budgets with this month's spending and exposes
/// ready-made [BudgetStatus] objects, so widgets contain no budget logic.
class BudgetProvider extends ChangeNotifier {
  BudgetProvider(this._budgets, this._transactions) {
    _budgetSub = _budgets.watchAll().listen((rows) {
      _rows = rows;
      _gotBudgets = true;
      _recalculate();
    }, onError: _onError);

    _spendSub = _transactions.watchMonthlyExpenseByCategory().listen((spent) {
      _spent = spent;
      _gotSpending = true;
      _recalculate();
    }, onError: _onError);
  }

  final BudgetRepository _budgets;
  final TransactionRepository _transactions;
  StreamSubscription<List<BudgetRow>>? _budgetSub;
  StreamSubscription<Map<String, int>>? _spendSub;

  List<BudgetRow> _rows = [];
  Map<String, int> _spent = {};
  bool _gotBudgets = false;
  bool _gotSpending = false;
  String? _error;

  BudgetStatus? _overall;
  Map<String, BudgetStatus> _byCategory = {};
  int _totalSpentMinor = 0;

  /// True until both streams have delivered their first value.
  bool get isLoading => !(_gotBudgets && _gotSpending);
  String? get error => _error;

  /// Overall monthly budget status, or null if no overall budget is set.
  BudgetStatus? get overall => _overall;

  /// Status per category id, only for categories that have a budget.
  Map<String, BudgetStatus> get byCategory => _byCategory;

  /// Everything spent this month (all categories).
  int get totalSpentMinor => _totalSpentMinor;

  /// The saved budget amount (minor units) for a category, or the overall
  /// budget when [categoryId] is null. Null if none is set.
  int? budgetFor(String? categoryId) {
    for (final r in _rows) {
      if (r.categoryId == categoryId) return r.amountMinor;
    }
    return null;
  }

  Future<void> setBudget({String? categoryId, required int amountMinor}) =>
      _budgets.set(categoryId: categoryId, amountMinor: amountMinor);

  Future<void> clearBudget({String? categoryId}) =>
      _budgets.clear(categoryId: categoryId);

  void _recalculate() {
    if (isLoading) return;

    _totalSpentMinor = _spent.values.fold<int>(0, (a, b) => a + b);

    BudgetStatus? overall;
    final byCategory = <String, BudgetStatus>{};

    for (final r in _rows) {
      final categoryId = r.categoryId;
      if (categoryId == null) {
        overall = calculateBudget(
          budgetMinor: r.amountMinor,
          spentMinor: _totalSpentMinor,
        );
      } else {
        byCategory[categoryId] = calculateBudget(
          budgetMinor: r.amountMinor,
          spentMinor: _spent[categoryId] ?? 0,
        );
      }
    }

    _overall = overall;
    _byCategory = byCategory;
    _error = null;
    notifyListeners();
  }

  void _onError(Object e) {
    _error = e.toString();
    notifyListeners();
  }

  @override
  void dispose() {
    _budgetSub?.cancel();
    _spendSub?.cancel();
    super.dispose();
  }
}
