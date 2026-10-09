import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/recurrence.dart';
import '../local/database.dart';
import '../local/enums.dart';
import 'transaction_repository.dart';

class RecurringRepository {
  RecurringRepository(
      this._db,
      this._transactions, {
        required this._userId,
        DateTime Function()? clock,
      }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final String Function() _userId;
  final DateTime Function() _clock;
  final _uuid = const Uuid();

  Stream<List<RecurringRuleRow>> watchAll() => (_db.select(_db.recurringRules)
    ..where((r) => r.deletedAt.isNull() & r.userId.equals(_userId()))
    ..orderBy([(r) => OrderingTerm.asc(r.nextDueAt)]))
      .watch();

  Future<void> add({
    required String title,
    required int amountMinor,
    required TxType type,
    required String categoryId,
    required String accountId,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Title is required');
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive');
    final now = _clock();
    await _db.into(_db.recurringRules).insert(
      RecurringRulesCompanion.insert(
        id: _uuid.v4(),
        userId: _userId(),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
        title: title.trim(),
        amountMinor: amountMinor,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        frequency: frequency,
        startDate: startDate,
        nextDueAt: startDate,
        endDate: Value(endDate),
      ),
    );
  }

  Future<void> setActive(String id, bool active) =>
      (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
        RecurringRulesCompanion(
          isActive: Value(active),
          updatedAt: Value(_clock()),
        ),
      );

  Future<void> delete(String id) {
    final now = _clock();
    return (_db.update(_db.recurringRules)..where((r) => r.id.equals(id)))
        .write(
      RecurringRulesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pendingDelete),
      ),
    );
  }

  Future<int> generateDue() {
    return _db.transaction(() async {
      final now = _clock();
      final rules = await (_db.select(_db.recurringRules)
        ..where((r) =>
        r.userId.equals(_userId()) &
        r.deletedAt.isNull() &
        r.isActive.equals(true) &
        r.nextDueAt.isSmallerOrEqualValue(now)))
          .get();

      var created = 0;
      for (final rule in rules) {
        var due = rule.nextDueAt;
        var guard = 0;
        while (!due.isAfter(now) && guard < 400) {
          final end = rule.endDate;
          if (end != null && due.isAfter(end)) break;

          await _transactions.add(
            amountMinor: rule.amountMinor,
            type: rule.type,
            categoryId: rule.categoryId,
            accountId: rule.accountId,
            occurredAt: due,
            note: rule.note.isEmpty ? rule.title : rule.note,
            recurringRuleId: rule.id,
          );
          created++;
          due = nextOccurrence(due, rule.frequency, rule.startDate);
          guard++;
        }

        final end = rule.endDate;
        final finished = end != null && due.isAfter(end);
        await (_db.update(_db.recurringRules)
          ..where((r) => r.id.equals(rule.id)))
            .write(
          RecurringRulesCompanion(
            nextDueAt: Value(due),
            isActive: Value(!finished),
            updatedAt: Value(now),
            syncStatus: Value(rule.baseJson == null
                ? SyncStatus.pendingCreate
                : SyncStatus.pendingUpdate),
          ),
        );
      }
      return created;
    });
  }
}