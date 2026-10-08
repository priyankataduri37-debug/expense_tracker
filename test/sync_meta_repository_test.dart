import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/repositories/sync_meta_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncMetaRepository meta;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    meta = SyncMetaRepository(db);
  });
  tearDown(() => db.close());

  test('returns null before the first pull', () async {
    expect(await meta.getLastSyncMicros('u1'), isNull);
  });

  test('stores and overwrites the bookmark', () async {
    await meta.setLastSyncMicros('u1', 1791449992000000);
    expect(await meta.getLastSyncMicros('u1'), 1791449992000000);

    await meta.setLastSyncMicros('u1', 1791450000000000);
    expect(await meta.getLastSyncMicros('u1'), 1791450000000000);
  });

  test('each user has their own bookmark', () async {
    await meta.setLastSyncMicros('u1', 100);
    await meta.setLastSyncMicros('u2', 200);
    expect(await meta.getLastSyncMicros('u1'), 100);
    expect(await meta.getLastSyncMicros('u2'), 200);
  });

  test('clear makes the next pull start from scratch', () async {
    await meta.setLastSyncMicros('u1', 100);
    await meta.clear('u1');
    expect(await meta.getLastSyncMicros('u1'), isNull);
  });
}