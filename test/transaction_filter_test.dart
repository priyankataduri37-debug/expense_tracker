import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/models/transaction_filter.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, userId: () => 'u1');

    Future<void> add(
      int amount,
      TxType type,
      String cat,
      DateTime date,
      String note,
    ) => repo.add(
      amountMinor: amount,
      type: type,
      categoryId: cat,
      accountId: 'acc_cash',
      occurredAt: date,
      note: note,
    );

    await add(2500, TxType.expense, 'exp_food', DateTime(2026, 10, 5), 'Lunch');
    await add(1000, TxType.expense, 'exp_travel', DateTime(2026, 10, 6), 'Bus');
    await add(50000, TxType.income, 'inc_salary', DateTime(2026, 10, 7), 'Pay');
    await add(700, TxType.expense, 'exp_food', DateTime(2026, 9, 20), 'Old');
  });
  tearDown(() => db.close());

  Future<List<TransactionRow>> run(TransactionFilter f, {int limit = 50}) =>
      repo.watchFiltered(f, limit: limit).first;

  test('no filter returns everything, newest first', () async {
    final rows = await run(TransactionFilter.none);
    expect(rows, hasLength(4));
    expect(rows.first.note, 'Pay');
  });

  test('Expense + Food + This Month combine', () async {
    final rows = await run(
      TransactionFilter(
        type: TxType.expense,
        categoryId: 'exp_food',
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 11, 1),
      ),
    );
    expect(rows.map((r) => r.note), ['Lunch']);
  });

  test('amount range', () async {
    final rows = await run(
      const TransactionFilter(minMinor: 1000, maxMinor: 2500),
    );
    expect(rows.map((r) => r.note).toSet(), {'Lunch', 'Bus'});
  });

  test('search by note, amount and category name', () async {
    expect(
      (await run(const TransactionFilter(search: 'lunch'))).single.note,
      'Lunch',
    );
    expect(
      (await run(const TransactionFilter(search: '10'))).single.note,
      'Bus',
    );
    final byCategory = await run(const TransactionFilter(search: 'food'));
    expect(byCategory.map((r) => r.note).toSet(), {'Lunch', 'Old'});
  });

  test('limit only loads that many rows', () async {
    expect(await run(TransactionFilter.none, limit: 2), hasLength(2));
  });

  test('deleted rows and other users are excluded', () async {
    final first = (await run(TransactionFilter.none)).first;
    await repo.delete(first.id);
    expect(await run(TransactionFilter.none), hasLength(3));

    final other = TransactionRepository(db, userId: () => 'u2');
    expect(
      await other.watchFiltered(TransactionFilter.none, limit: 50).first,
      isEmpty,
    );
  });

  test('copyWith can set and clear a field', () {
    final f = TransactionFilter.none.copyWith(type: TxType.income);
    expect(f.type, TxType.income);
    expect(f.isActive, isTrue);
    expect(f.copyWith(type: null).isActive, isFalse);
  });
}
