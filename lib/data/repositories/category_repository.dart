import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/enums.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<CategoryRow>> watchAll() {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([
        (c) => OrderingTerm.asc(c.isCustom),
        (c) => OrderingTerm.asc(c.name),
      ]);

    return query.watch();
  }

  Future<void> createCustomCategory({
    required String userId,
    required String name,
    required TxType type,
    required String iconKey,
    required int colorValue,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final now = DateTime.now();

    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'category_${now.microsecondsSinceEpoch}',
            userId: userId,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: trimmedName,
            type: type,
            iconKey: iconKey,
            colorValue: Value(colorValue),
            isCustom: const Value(true),
          ),
        );
  }

  Future<void> archiveCategory(String id) async {
    final category =
        await (_db.select(_db.categories)
              ..where((c) => c.id.equals(id) & c.isCustom.equals(true))
              ..where((c) => c.deletedAt.isNull()))
            .getSingleOrNull();

    if (category == null) {
      throw StateError('Custom category not found.');
    }

    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
