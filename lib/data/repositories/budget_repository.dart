import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/enums.dart';

class BudgetRepository {
  BudgetRepository(
    this._db, {
    required this._userId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final String Function() _userId;
  final DateTime Function() _clock;
  final _uuid = const Uuid();

  Expression<bool> _forCategory($BudgetsTable b, String? categoryId) =>
      categoryId == null
      ? b.categoryId.isNull()
      : b.categoryId.equals(categoryId);

  Stream<List<BudgetRow>> watchAll() => (_db.select(
    _db.budgets,
  )..where((b) => b.deletedAt.isNull() & b.userId.equals(_userId()))).watch();

  Future<void> set({String? categoryId, required int amountMinor}) async {
    if (amountMinor <= 0) throw ArgumentError('Budget must be positive');
    final now = _clock();

    await _db.transaction(() async {
      final found =
          await (_db.select(_db.budgets)
                ..where(
                  (b) =>
                      _forCategory(b, categoryId) & b.userId.equals(_userId()),
                )
                ..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])
                ..limit(1))
              .get();

      if (found.isEmpty) {
        await _db
            .into(_db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: _uuid.v4(),
                userId: _userId(),
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.pendingCreate,
                categoryId: Value(categoryId),
                amountMinor: amountMinor,
              ),
            );
        return;
      }

      final row = found.first;
      final status = row.baseJson == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate;

      await (_db.update(_db.budgets)..where((b) => b.id.equals(row.id))).write(
        BudgetsCompanion(
          amountMinor: Value(amountMinor),
          deletedAt: const Value<DateTime?>(
            null,
          ),
          updatedAt: Value(now),
          syncStatus: Value(status),
        ),
      );
    });
  }


  Future<void> clear({String? categoryId}) {
    final now = _clock();
    return (_db.update(_db.budgets)..where(
          (b) =>
              _forCategory(b, categoryId) &
              b.userId.equals(_userId()) &
              b.deletedAt.isNull(),
        ))
        .write(
          BudgetsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pendingDelete),
          ),
        );
  }
}
