import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/local/enums.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repo) {
    _sub = _repo.watchAll().listen((rows) {
      _all = rows;
      _byId = {for (final c in rows) c.id: c};
      notifyListeners();
    });
  }

  final CategoryRepository _repo;
  StreamSubscription<List<CategoryRow>>? _sub;

  List<CategoryRow> _all = [];
  Map<String, CategoryRow> _byId = {};

  /// Active (not archived) categories of one type, for pickers.
  List<CategoryRow> forType(TxType type) =>
      _all.where((c) => c.type == type && !c.isArchived).toList();

  CategoryRow? byId(String id) => _byId[id];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
