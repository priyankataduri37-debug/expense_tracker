import 'package:drift/drift.dart';

import '../local/database.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// All non-deleted categories (archived ones included, so old
  /// transactions can still show their category). Built-ins first.
  Stream<List<CategoryRow>> watchAll() {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([
        (c) => OrderingTerm.asc(c.isCustom),
        (c) => OrderingTerm.asc(c.name),
      ]);
    return query.watch();
  }
}
