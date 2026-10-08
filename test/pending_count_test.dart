import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pending count rises on add, drops after sync, ignores other users',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = TransactionRepository(db, userId: () => 'u1');
      final other = TransactionRepository(db, userId: () => 'u2');

      Future<String> add(TransactionRepository r) => r.add(
        amountMinor: 1000,
        type: TxType.expense,
        categoryId: 'exp_food',
        accountId: 'acc_cash',
        occurredAt: DateTime(2026, 10, 8),
      );

      final id = await add(repo);
      await add(other);
      expect(await repo.watchPendingCount().first, 1);

      final row = (await repo.pendingRows()).single;
      await repo.markSynced(
        id,
        expectedUpdatedAt: row.updatedAt,
        baseJson: '{}',
      );
      expect(await repo.watchPendingCount().first, 0);

      await db.close();
    },
  );
}
