import 'package:drift/drift.dart';

import '../data/local/database.dart';
import '../data/repositories/sync_meta_repository.dart';

class LocalDataResetService {
  LocalDataResetService(this._db, {required this._syncMeta});

  final AppDatabase _db;
  final SyncMetaRepository _syncMeta;

  Future<void> resetForUser(String uid) async {
    if (uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.userId.equals(uid))).go();

      await (_db.delete(_db.accounts)..where((a) => a.userId.equals(uid))).go();

      await (_db.delete(_db.budgets)..where((b) => b.userId.equals(uid))).go();

      await (_db.delete(_db.goals)..where((g) => g.userId.equals(uid))).go();

      await (_db.delete(
        _db.recurringRules,
      )..where((r) => r.userId.equals(uid))).go();

      await (_db.delete(_db.categories)..where(
            (c) =>
                Expression.and([c.userId.equals(uid), c.isCustom.equals(true)]),
          ))
          .go();

      await _syncMeta.clear(uid);
    });
  }
}
