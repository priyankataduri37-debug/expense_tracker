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

  List<CategoryRow> forType(TxType type) =>
      _all.where((c) => c.type == type && !c.isArchived).toList();

  List<CategoryRow> get customCategories =>
      _all.where((c) => c.isCustom && !c.isArchived).toList();

  CategoryRow? byId(String id) => _byId[id];

  Future<void> createCustomCategory({
    required String userId,
    required String name,
    required TxType type,
    required String iconKey,
    required int colorValue,
  }) {
    return _repo.createCustomCategory(
      userId: userId,
      name: name,
      type: type,
      iconKey: iconKey,
      colorValue: colorValue,
    );
  }

  Future<void> archiveCategory(String id) {
    return _repo.archiveCategory(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
