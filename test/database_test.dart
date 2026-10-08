import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insert and read a transaction', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 10, 7);

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'abc',
            userId: 'local',
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            amountMinor: 2500,
            type: TxType.expense,
            categoryId: 'food',
            accountId: 'cash',
            occurredAt: now,
          ),
        );

    final rows = await db.select(db.transactions).get();
    expect(rows.length, 1);
    expect(rows.first.amountMinor, 2500);

    await db.close();
  });
}
