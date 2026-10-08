import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/sync/transaction_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transactionToMap converts a row to a cloud map', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = TransactionRepository(db, userId: () => 'u1');

    await repo.add(
      amountMinor: 2500,
      type: TxType.expense,
      categoryId: 'exp_food',
      accountId: 'acc_cash',
      occurredAt: DateTime.utc(2026, 10, 8),
      note: 'Lunch',
    );

    final row = (await db.select(db.transactions).get()).single;
    final map = transactionToMap(row);

    expect(map['amountMinor'], 2500);
    expect(map['type'], 'expense');
    expect(map['userId'], 'u1');
    expect(map['deletedAt'], isNull);
    expect(map.containsKey('syncStatus'), isFalse);

    await db.close();
  });
}