import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/local/enums.dart';
import '../data/repositories/recurring_repository.dart';

class RecurringProvider extends ChangeNotifier {
  RecurringProvider(this._repo) {
    _subscribe();
    _generateDue();
  }

  final RecurringRepository _repo;

  StreamSubscription<List<RecurringRuleRow>>? _sub;

  List<RecurringRuleRow> _items = [];
  bool _loading = true;
  String? _error;

  List<RecurringRuleRow> get items => _items;

  bool get isLoading => _loading;

  String? get error => _error;

  void _subscribe() {
    _sub = _repo.watchAll().listen(
          (rows) {
        _items = rows;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _generateDue() async {
    try {
      await _repo.generateDue();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> add({
    required String title,
    required int amountMinor,
    required TxType type,
    required String categoryId,
    required String accountId,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) =>
      _repo.add(
        title: title,
        amountMinor: amountMinor,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      );

  Future<void> setActive(String id, bool active) =>
      _repo.setActive(id, active);

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> generateDue() async {
    try {
      await _repo.generateDue();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}