import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/enums.dart';
import '../models/transaction_filter.dart';

class TransactionTotals {
  const TransactionTotals({required this.income, required this.expense});

  final int income;
  final int expense;
  int get balance => income - expense;
}

class TransactionRepository {
  TransactionRepository(
    this._db, {
    required this._userId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final String Function() _userId;
  final DateTime Function() _clock;
  final _uuid = const Uuid();

  Future<TransactionRow?> _find(String id) => (_db.select(
    _db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<TransactionRow>> watchAll() {
    final query = _db.select(_db.transactions)
      ..where((t) => t.deletedAt.isNull() & t.userId.equals(_userId()))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return query.watch();
  }


  Stream<List<TransactionRow>> watchFiltered(
    TransactionFilter f, {
    required int limit,
  }) {
    final t = _db.transactions;

    Expression<bool> cond = t.deletedAt.isNull() & t.userId.equals(_userId());

    if (f.type != null) cond = cond & t.type.equalsValue(f.type!);
    if (f.categoryId != null) cond = cond & t.categoryId.equals(f.categoryId!);
    if (f.accountId != null) cond = cond & t.accountId.equals(f.accountId!);
    if (f.from != null) {
      cond = cond & t.occurredAt.isBiggerOrEqualValue(f.from!);
    }
    if (f.to != null) cond = cond & t.occurredAt.isSmallerThanValue(f.to!);
    if (f.minMinor != null) {
      cond = cond & t.amountMinor.isBiggerOrEqualValue(f.minMinor!);
    }
    if (f.maxMinor != null) {
      cond = cond & t.amountMinor.isSmallerOrEqualValue(f.maxMinor!);
    }

    final q = f.search?.trim() ?? '';
    if (q.isNotEmpty) {
      final like = '%$q%';
      final matchingCategories = _db.selectOnly(_db.categories)
        ..addColumns([_db.categories.id])
        ..where(_db.categories.name.like(like));
      final minor = _searchAmountMinor(q);
      final Expression<bool> amountMatch = minor == null
          ? const Constant(false)
          : t.amountMinor.equals(minor);

      cond =
          cond &
          (t.note.like(like) |
              t.categoryId.isInQuery(matchingCategories) |
              amountMatch);
    }

    final query = _db.select(t)
      ..where((_) => cond)
      ..orderBy([
        (r) => OrderingTerm.desc(r.occurredAt),
        (r) => OrderingTerm.desc(r.createdAt),
      ])
      ..limit(limit);
    return query.watch();
  }

  Stream<List<TransactionRow>> watchRecent(int limit) {
    final query = _db.select(_db.transactions)
      ..where((t) => t.deletedAt.isNull() & t.userId.equals(_userId()))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    return query.watch();
  }

  Stream<TransactionTotals> watchTotals() {
    final t = _db.transactions;
    final income = t.amountMinor.sum(filter: t.type.equalsValue(TxType.income));
    final expense = t.amountMinor.sum(
      filter: t.type.equalsValue(TxType.expense),
    );
    final query = _db.selectOnly(t)
      ..addColumns([income, expense])
      ..where(t.deletedAt.isNull() & t.userId.equals(_userId()));
    return query.watchSingle().map(
      (row) => TransactionTotals(
        income: row.read(income) ?? 0,
        expense: row.read(expense) ?? 0,
      ),
    );
  }

  Stream<Map<String, int>> watchMonthlyExpenseByCategory() {
    final t = _db.transactions;
    final now = _clock();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);

    final total = t.amountMinor.sum();
    final query = _db.selectOnly(t)
      ..addColumns([t.categoryId, total])
      ..where(
        t.deletedAt.isNull() &
            t.userId.equals(_userId()) &
            t.type.equalsValue(TxType.expense) &
            t.occurredAt.isBiggerOrEqualValue(start) &
            t.occurredAt.isSmallerThanValue(end),
      )
      ..groupBy([t.categoryId]);

    return query.watch().map(
      (rows) => {
        for (final r in rows) r.read(t.categoryId)!: r.read(total) ?? 0,
      },
    );
  }

  Future<String> add({
    required int amountMinor,
    required TxType type,
    required String categoryId,
    required String accountId,
    required DateTime occurredAt,
    String note = '',
    String? recurringRuleId,
  }) async {
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive');
    final id = _uuid.v4();
    final now = _clock();
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            userId: _userId(),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            amountMinor: amountMinor,
            type: type,
            categoryId: categoryId,
            accountId: accountId,
            occurredAt: occurredAt,
            note: Value(note),
            recurringRuleId: Value(recurringRuleId),
          ),
        );
    return id;
  }

  Future<void> update(
    String id, {
    int? amountMinor,
    TxType? type,
    String? categoryId,
    String? accountId,
    DateTime? occurredAt,
    String? note,
  }) async {
    if (amountMinor != null && amountMinor <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    final row = await _find(id);
    if (row == null || row.deletedAt != null) {
      throw StateError('Transaction not found');
    }
    final status = row.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amountMinor: Value.absentIfNull(amountMinor),
        type: Value.absentIfNull(type),
        categoryId: Value.absentIfNull(categoryId),
        accountId: Value.absentIfNull(accountId),
        occurredAt: Value.absentIfNull(occurredAt),
        note: Value.absentIfNull(note),
        updatedAt: Value(_clock()),
        syncStatus: Value(status),
      ),
    );
  }

  Future<void> delete(String id) async {
    final row = await _find(id);
    if (row == null || row.deletedAt != null) return;
    final now = _clock();
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pendingDelete),
      ),
    );
  }

  Future<void> restore(String id) async {
    final row = await _find(id);
    if (row == null || row.deletedAt == null) return;
    final status = row.baseJson == null
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: const Value<DateTime?>(null),
        updatedAt: Value(_clock()),
        syncStatus: Value(status),
      ),
    );
  }


  Future<List<TransactionRow>> pendingRows() =>
      (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.userId.equals(_userId()) &
                  t.syncStatus.isInValues([
                    SyncStatus.pendingCreate,
                    SyncStatus.pendingUpdate,
                    SyncStatus.pendingDelete,
                    SyncStatus.failed,
                  ]),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
          .get();


  Future<bool> markSynced(
    String id, {
    required DateTime expectedUpdatedAt,
    required String baseJson,
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(baseJson: Value(baseJson)),
      );

      final changed =
          await (_db.update(_db.transactions)..where(
                (t) => t.id.equals(id) & t.updatedAt.equals(expectedUpdatedAt),
              ))
              .write(
                const TransactionsCompanion(
                  syncStatus: Value(SyncStatus.synced),
                ),
              );
      return changed > 0;
    });
  }

  Future<void> markFailed(String id) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        const TransactionsCompanion(syncStatus: Value(SyncStatus.failed)),
      );

  Stream<int> watchPendingCount() {
    final t = _db.transactions;
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(
        t.userId.equals(_userId()) &
            t.syncStatus.isInValues([
              SyncStatus.pendingCreate,
              SyncStatus.pendingUpdate,
              SyncStatus.pendingDelete,
              SyncStatus.failed,
            ]),
      );
    return query.map((r) => r.read(count) ?? 0).watchSingle();
  }

  Future<void> purge(String id) =>
      (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  Future<TransactionRow?> findById(String id) => _find(id);


  Future<void> insertFromCloud(
    Map<String, dynamic> m, {
    required String baseJson,
  }) async {
    if (m['deletedAt'] != null) return;
    await _db
        .into(_db.transactions)
        .insertOnConflictUpdate(
          TransactionsCompanion.insert(
            id: m['id'] as String,
            userId: _userId(),
            createdAt: _fromMs(m['createdAt'] as int),
            updatedAt: _fromMs(m['updatedAt'] as int),
            syncStatus: SyncStatus.synced,
            baseJson: Value(baseJson),
            amountMinor: m['amountMinor'] as int,
            type: TxType.values.byName(m['type'] as String),
            categoryId: m['categoryId'] as String,
            accountId: m['accountId'] as String,
            occurredAt: _fromMs(m['occurredAt'] as int),
            note: Value(m['note'] as String),
          ),
        );
  }


  Future<bool> applyMerged(
    Map<String, dynamic> merged, {
    required DateTime expectedLocalUpdatedAt,
    required bool needsPush,
    required String baseJson,
  }) {
    final id = merged['id'] as String;
    final deletedMs = merged['deletedAt'] as int?;

    return _db.transaction(() async {
      final row = await _find(id);
      if (row == null || row.updatedAt != expectedLocalUpdatedAt) return false;

      final status = !needsPush
          ? SyncStatus.synced
          : (deletedMs != null
                ? SyncStatus.pendingDelete
                : SyncStatus.pendingUpdate);

      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          amountMinor: Value(merged['amountMinor'] as int),
          type: Value(TxType.values.byName(merged['type'] as String)),
          categoryId: Value(merged['categoryId'] as String),
          accountId: Value(merged['accountId'] as String),
          note: Value(merged['note'] as String),
          occurredAt: Value(_fromMs(merged['occurredAt'] as int)),
          deletedAt: Value(deletedMs == null ? null : _fromMs(deletedMs)),
          updatedAt: Value(_fromMs(merged['updatedAt'] as int)),
          syncStatus: Value(status),
          baseJson: Value(baseJson),
        ),
      );
      return true;
    });
  }
}

DateTime _fromMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

int? _searchAmountMinor(String s) {
  final v = double.tryParse(s.replaceAll(',', ''));
  return v == null ? null : (v * 100).round();
}
