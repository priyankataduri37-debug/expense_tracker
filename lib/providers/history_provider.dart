import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/models/transaction_filter.dart';
import '../data/repositories/transaction_repository.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repo, {this.pageSize = 30}) : _limit = pageSize {
    _subscribe();
  }

  final TransactionRepository _repo;
  final int pageSize;

  int _limit;
  TransactionFilter _filter = TransactionFilter.none;
  StreamSubscription<List<TransactionRow>>? _sub;
  Timer? _searchDebounce;

  List<TransactionRow> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  List<TransactionRow> get items => _items;
  TransactionFilter get filter => _filter;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  String? get error => _error;

  /// If we got a full page back, there may be more rows behind it.
  bool get hasMore => _items.length >= _limit;

  void _subscribe() {
    _sub?.cancel();
    // The old list stays on screen until the new one arrives (no flicker).
    _sub = _repo.watchFiltered(_filter, limit: _limit).listen(
          (rows) {
        _items = rows;
        _loading = false;
        _loadingMore = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
        notifyListeners();
      },
    );
  }

  /// A new filter always starts again from the first page.
  void setFilter(TransactionFilter f) {
    _filter = f;
    _limit = pageSize;
    notifyListeners();
    _subscribe();
  }

  void clearFilters() => setFilter(TransactionFilter.none);

  /// Waits 300 ms after the last keystroke so we don't query on every letter.
  void setSearch(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final t = text.trim();
      setFilter(_filter.copyWith(search: t.isEmpty ? null : t));
    });
  }

  /// Called when the list is scrolled near the bottom.
  void loadMore() {
    if (!hasMore || _loadingMore || _loading) return;
    _loadingMore = true;
    _limit += pageSize;
    notifyListeners();
    _subscribe();
  }

  Future<void> delete(String id) async {
    // Remove it right away so the swipe animation finishes cleanly.
    _items = _items.where((t) => t.id != id).toList();
    notifyListeners();
    await _repo.delete(id);
  }

  Future<void> restore(String id) => _repo.restore(id);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}