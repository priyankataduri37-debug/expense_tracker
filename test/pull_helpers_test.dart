import 'dart:convert';

import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/sync/transaction_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> cloudDoc({int? deletedAt}) => {
  'id': 'c1',
  'userId': 'u1',
  'amountMinor': 5000,
  'type': 'income',
  'categoryId': 'inc_salary',
  'accountId': 'acc_cash',
  'note': 'Salary',
  'occurredAt': 1791400000000,
  'createdAt': 1791400000000,
  'updatedAt': 1791400000000,
  'deletedAt': deletedAt,
};

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  var now = DateTime(2026, 10, 8, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, userId: () => 'u1', clock: () => now);
  });
  tearDown(() => db.close());

  Future<String> addLocal() => repo.add(
    amountMinor: 2500,
    type: TxType.expense,
    categoryId: 'exp_food',
    accountId: 'acc_cash',
    occurredAt: DateTime(2026, 10, 8),
  );

  test('insertFromCloud adds a synced row with a base', () async {
    final doc = cloudDoc();
    await repo.insertFromCloud(doc, baseJson: jsonEncode(doc));

    final row = (await db.select(db.transactions).get()).single;
    expect(row.syncStatus, SyncStatus.synced);
    expect(row.amountMinor, 5000);
    expect(row.baseJson, isNotNull);
  });

  test('insertFromCloud ignores deleted documents', () async {
    final doc = cloudDoc(deletedAt: 1791400001000);
    await repo.insertFromCloud(doc, baseJson: jsonEncode(doc));
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('applyMerged with nothing to push marks the row synced', () async {
    final id = await addLocal();
    final row = (await repo.findById(id))!;
    final merged = transactionToMap(row)..['note'] = 'From cloud';

    final ok = await repo.applyMerged(merged,
        expectedLocalUpdatedAt: row.updatedAt,
        needsPush: false,
        baseJson: '{}');

    final after = (await repo.findById(id))!;
    expect(ok, isTrue);
    expect(after.note, 'From cloud');
    expect(after.syncStatus, SyncStatus.synced);
  });

  test('applyMerged with changes to upload keeps the row pending', () async {
    final id = await addLocal();
    final row = (await repo.findById(id))!;
    final merged = transactionToMap(row);

    await repo.applyMerged(merged,
        expectedLocalUpdatedAt: row.updatedAt,
        needsPush: true,
        baseJson: '{}');

    expect((await repo.findById(id))!.syncStatus, SyncStatus.pendingUpdate);
  });

  test('applyMerged skips the row if it was edited meanwhile', () async {
    final id = await addLocal();
    final row = (await repo.findById(id))!;
    final merged = transactionToMap(row)..['note'] = 'From cloud';

    now = now.add(const Duration(seconds: 5));
    await repo.update(id, note: 'My newer edit');

    final ok = await repo.applyMerged(merged,
        expectedLocalUpdatedAt: row.updatedAt,
        needsPush: false,
        baseJson: '{}');

    expect(ok, isFalse);
    expect((await repo.findById(id))!.note, 'My newer edit');
  });
}