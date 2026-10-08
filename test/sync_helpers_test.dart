import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  var now = DateTime(2026, 10, 8, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, userId: () => 'u1', clock: () => now);
  });
  tearDown(() => db.close());

  Future<String> addRow(TransactionRepository r) => r.add(
    amountMinor: 2500,
    type: TxType.expense,
    categoryId: 'exp_food',
    accountId: 'acc_cash',
    occurredAt: now,
  );

  test('pendingRows only returns pending rows of the current user', () async {
    final id = await addRow(repo);
    await addRow(TransactionRepository(db, userId: () => 'u2'));

    expect(await repo.pendingRows(), hasLength(1));

    final row = (await repo.pendingRows()).single;
    await repo.markSynced(id,
        expectedUpdatedAt: row.updatedAt, baseJson: '{}');
    expect(await repo.pendingRows(), isEmpty);
  });

  test('markSynced is skipped if the row was edited during upload', () async {
    final id = await addRow(repo);
    final uploaded = (await repo.pendingRows()).single;

    now = now.add(const Duration(seconds: 5));
    await repo.update(id, note: 'edited while uploading');

    final applied = await repo.markSynced(id,
        expectedUpdatedAt: uploaded.updatedAt, baseJson: '{"v":1}');

    expect(applied, isFalse);
    final row = (await repo.pendingRows()).single;
    expect(row.syncStatus, isNot(SyncStatus.synced));
    expect(row.baseJson, '{"v":1}');
  });

  test('markFailed keeps the row in the pending list', () async {
    final id = await addRow(repo);
    await repo.markFailed(id);
    final row = (await repo.pendingRows()).single;
    expect(row.syncStatus, SyncStatus.failed);
  });

  test('purge removes the row completely', () async {
    final id = await addRow(repo);
    await repo.purge(id);
    expect(await repo.pendingRows(), isEmpty);
  });
}