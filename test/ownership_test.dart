import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/local/ownership.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('claimLocalRows moves local rows to the new user', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = TransactionRepository(db, userId: () => 'local');

    await repo.add(
      amountMinor: 2500,
      type: TxType.expense,
      categoryId: 'exp_food',
      accountId: 'acc_cash',
      occurredAt: DateTime(2026, 10, 8),
    );

    await LocalOwnership(db).claimLocalRows('user123');

    final rows = await db.select(db.transactions).get();
    expect(rows.single.userId, 'user123');

    await db.close();
  });
}
