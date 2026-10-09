import '../local/database.dart';

class SyncMetaRepository {
  SyncMetaRepository(this._db);

  final AppDatabase _db;

  String _key(String uid) => 'lastSyncAt:$uid';


  Future<int?> getLastSyncMicros(String uid) async {
    final row = await (_db.select(
      _db.syncMeta,
    )..where((t) => t.key.equals(_key(uid)))).getSingleOrNull();
    return row == null ? null : int.tryParse(row.value);
  }

  Future<void> setLastSyncMicros(String uid, int micros) => _db
      .into(_db.syncMeta)
      .insertOnConflictUpdate(
        SyncMetaCompanion.insert(key: _key(uid), value: micros.toString()),
      );

  Future<void> clear(String uid) =>
      (_db.delete(_db.syncMeta)..where((t) => t.key.equals(_key(uid)))).go();
}
