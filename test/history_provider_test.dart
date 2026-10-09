import 'package:drift/native.dart';
import 'package:expense_tracker/data/local/database.dart';
import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/models/transaction_filter.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/providers/history_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late HistoryProvider p;

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 80));

  List<String> notes() => p.items.map((r) => r.note).toList();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db, userId: () => 'u1');

    for (var i = 0; i < 5; i++) {
      await repo.add(
        amountMinor: 1000 + i,
        type: i.isEven ? TxType.expense : TxType.income,
        categoryId: 'exp_food',
        accountId: 'acc_cash',
        occurredAt: DateTime(2026, 10, 1 + i),
        note: 'tx$i',
      );
    }
    p = HistoryProvider(repo, pageSize: 2);
    await settle();
  });

  tearDown(() async {
    p.dispose();
    await db.close();
  });

  test('loads only the first page, newest first', () {
    expect(notes(), ['tx4', 'tx3']);
    expect(p.hasMore, isTrue);
    expect(p.isLoading, isFalse);
  });

  test('loadMore adds pages until the end', () async {
    p.loadMore();
    await settle();
    expect(p.items, hasLength(4));

    p.loadMore();
    await settle();
    expect(p.items, hasLength(5));
    expect(p.hasMore, isFalse);
  });

  test('a new filter filters and starts again from the first page', () async {
    p.setFilter(const TransactionFilter(type: TxType.income));
    await settle();
    expect(notes(), ['tx3', 'tx1']);
  });

  test('changing the filter after scrolling resets the page size', () async {
    p.loadMore();
    await settle();
    expect(p.items, hasLength(4));

    p.setFilter(const TransactionFilter(type: TxType.expense));
    await settle();
    expect(p.items, hasLength(2));
  });

  test('clearFilters brings everything back', () async {
    p.setFilter(const TransactionFilter(type: TxType.income));
    await settle();
    p.clearFilters();
    await settle();
    expect(p.filter.isActive, isFalse);
    expect(notes(), ['tx4', 'tx3']);
  });

  test('delete hides the row immediately, restore brings it back', () async {
    final id = p.items.first.id;
    final future = p.delete(id);
    expect(p.items.any((r) => r.id == id), isFalse);
    await future;
    await settle();
    expect(notes(), ['tx3', 'tx2']);

    await p.restore(id);
    await settle();
    expect(notes().first, 'tx4');
  });
}
