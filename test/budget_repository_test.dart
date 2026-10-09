import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BudgetRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BudgetRepository(db, userId: () => 'u1');
  });
  tearDown(() => db.close());

  Future<List<BudgetRow>> active() => repo.watchAll().first;

  test('set creates the overall budget as pendingCreate', () async {
    await repo.set(amountMinor: 200000);
    final rows = await active();
    expect(rows, hasLength(1));
    expect(rows.single.categoryId, isNull);
    expect(rows.single.amountMinor, 200000);
    expect(rows.single.syncStatus, SyncStatus.pendingCreate);
  });

  test('setting twice updates the same row (no duplicate)', () async {
    await repo.set(amountMinor: 200000);
    await repo.set(amountMinor: 250000);
    final rows = await active();
    expect(rows, hasLength(1));
    expect(rows.single.amountMinor, 250000);
  });

  test('a category budget is separate from the overall budget', () async {
    await repo.set(amountMinor: 200000);
    await repo.set(categoryId: 'exp_food', amountMinor: 40000);
    final rows = await active();
    expect(rows, hasLength(2));
    expect(
      rows.where((r) => r.categoryId == 'exp_food').single.amountMinor,
      40000,
    );
  });

  test('clear removes only that budget', () async {
    await repo.set(amountMinor: 200000);
    await repo.set(categoryId: 'exp_food', amountMinor: 40000);
    await repo.clear(categoryId: 'exp_food');
    final rows = await active();
    expect(rows, hasLength(1));
    expect(rows.single.categoryId, isNull);
  });

  test('setting after clear revives the same row', () async {
    await repo.set(amountMinor: 200000);
    await repo.clear();
    expect(await active(), isEmpty);

    await repo.set(amountMinor: 300000);
    expect(await active(), hasLength(1));
    expect(await db.select(db.budgets).get(), hasLength(1));
  });

  test('budgets are private to each user', () async {
    await repo.set(amountMinor: 200000);
    final other = BudgetRepository(db, userId: () => 'u2');
    expect(await other.watchAll().first, isEmpty);
  });

  test('rejects zero or negative budgets', () async {
    expect(() => repo.set(amountMinor: 0), throwsArgumentError);
  });
}
