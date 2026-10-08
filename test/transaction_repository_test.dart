import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  final now = DateTime(2026, 10, 7, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, userId: () => 'u1', clock: () => now);
  });

  tearDown(() => db.close());

  Future<String> addLunch() => repo.add(
    amountMinor: 2500,
    type: TxType.expense,
    categoryId: 'food',
    accountId: 'cash',
    occurredAt: now,
    note: 'Lunch',
  );

  test('adds up this month expenses per category', () async {
    final repo = TransactionRepository(
      db,
      userId: () => 'u1',
      clock: () => DateTime(2026, 7, 15), // fixed "today"
    );

    Future<void> addExpense(String cat, int minor, DateTime when) => repo.add(
      amountMinor: minor,
      type: TxType.expense,
      categoryId: cat,
      accountId: 'acc_cash', // seeded, don't insert it again
      occurredAt: when,
    );

    await addExpense('exp_food', 1000, DateTime(2026, 7, 2));
    await addExpense('exp_food', 500, DateTime(2026, 7, 10));
    await addExpense('exp_travel', 300, DateTime(2026, 7, 20));
    await addExpense(
      'exp_food',
      700,
      DateTime(2026, 6, 30),
    ); // last month: ignored

    final result = await repo.watchMonthlyExpenseByCategory().first;

    expect(result, {'exp_food': 1500, 'exp_travel': 300});
  });

  test('add saves locally as pendingCreate', () async {
    await addLunch();
    final rows = await repo.watchAll().first;
    expect(rows.length, 1);
    expect(rows.first.syncStatus, SyncStatus.pendingCreate);
    expect(rows.first.userId, 'u1');
  });

  test('editing an unsynced row stays pendingCreate', () async {
    final id = await addLunch();
    await repo.update(id, amountMinor: 3000);
    final row = (await repo.watchAll().first).first;
    expect(row.amountMinor, 3000);
    expect(row.syncStatus, SyncStatus.pendingCreate);
  });

  test('delete hides the row, restore brings it back', () async {
    final id = await addLunch();
    await repo.delete(id);
    expect(await repo.watchAll().first, isEmpty);

    await repo.restore(id);
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('rejects zero or negative amounts', () async {
    expect(
      () => repo.add(
        amountMinor: 0,
        type: TxType.expense,
        categoryId: 'food',
        accountId: 'cash',
        occurredAt: now,
      ),
      throwsArgumentError,
    );
  });
}
