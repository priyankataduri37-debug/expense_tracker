import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/local/enums.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._repo) {
    _subscribe();
  }

  final TransactionRepository _repo;
  StreamSubscription<List<TransactionRow>>? _sub;

  List<TransactionRow> _items = [];
  bool _loading = true;
  String? _error;

  List<TransactionRow> get items => _items;
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

  Future<void> add({
    required int amountMinor,
    required TxType type,
    required String categoryId,
    required String accountId,
    required DateTime occurredAt,
    String note = '',
  }) => _repo.add(
    amountMinor: amountMinor,
    type: type,
    categoryId: categoryId,
    accountId: accountId,
    occurredAt: occurredAt,
    note: note,
  );

  Future<void> update(
    String id, {
    int? amountMinor,
    TxType? type,
    String? categoryId,
    String? accountId,
    DateTime? occurredAt,
    String? note,
  }) => _repo.update(
    id,
    amountMinor: amountMinor,
    type: type,
    categoryId: categoryId,
    accountId: accountId,
    occurredAt: occurredAt,
    note: note,
  );

  Future<void> delete(String id) async {
    // Dismissible needs the item gone from the list immediately.
    _items = _items.where((t) => t.id != id).toList();
    notifyListeners();
    await _repo.delete(id);
  }

  Future<void> restore(String id) => _repo.restore(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
