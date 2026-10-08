import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/repositories/transaction_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repo) {
    _totalsSub = _repo.watchTotals().listen((t) {
      _totals = t;
      _loading = false;
      notifyListeners();
    });
    _recentSub = _repo.watchRecent(10).listen((rows) {
      _recent = rows;
      notifyListeners();
    });
  }

  final TransactionRepository _repo;
  StreamSubscription<TransactionTotals>? _totalsSub;
  StreamSubscription<List<TransactionRow>>? _recentSub;

  TransactionTotals _totals = const TransactionTotals(income: 0, expense: 0);
  List<TransactionRow> _recent = [];
  bool _loading = true;

  bool get isLoading => _loading;
  int get incomeMinor => _totals.income;
  int get expenseMinor => _totals.expense;
  int get balanceMinor => _totals.balance; // income - expenses
  List<TransactionRow> get recent => _recent;

  @override
  void dispose() {
    _totalsSub?.cancel();
    _recentSub?.cancel();
    super.dispose();
  }
}