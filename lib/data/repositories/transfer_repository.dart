import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../local/enums.dart';

class TransferRepository {
  TransferRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<String> createTransfer({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required int amountMinor,
    DateTime? transferredAt,
    String note = '',
    String? goalId,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError('Transfer amount must be positive.');
    }

    if (fromAccountId == toAccountId) {
      throw ArgumentError('Source and destination accounts must differ.');
    }

    final uid = userId;

    return _db.transaction(() async {
      final source =
          await (_db.select(_db.accounts)..where(
                (a) =>
                    a.id.equals(fromAccountId) &
                    a.userId.equals(uid) &
                    a.deletedAt.isNull() &
                    a.isArchived.equals(false),
              ))
              .getSingleOrNull();

      final destination =
          await (_db.select(_db.accounts)..where(
                (a) =>
                    a.id.equals(toAccountId) &
                    a.userId.equals(uid) &
                    a.deletedAt.isNull() &
                    a.isArchived.equals(false),
              ))
              .getSingleOrNull();

      if (source == null || destination == null) {
        throw StateError('Source or destination account not found.');
      }

      if (source.currencyCode != destination.currencyCode) {
        throw ArgumentError(
          'Transfers between different currencies are not supported.',
        );
      }

      if (goalId != null) {
        final goal =
            await (_db.select(_db.goals)..where(
                  (g) =>
                      g.id.equals(goalId) &
                      g.userId.equals(uid) &
                      g.deletedAt.isNull(),
                ))
                .getSingleOrNull();

        if (goal == null) {
          throw StateError('Savings goal not found.');
        }

        await (_db.update(_db.goals)..where(
              (g) =>
                  g.id.equals(goalId) &
                  g.userId.equals(uid) &
                  g.deletedAt.isNull(),
            ))
            .write(
              GoalsCompanion(
                currentMinor: Value(goal.currentMinor + amountMinor),
                updatedAt: Value(DateTime.now()),
                syncStatus: const Value(SyncStatus.synced),
              ),
            );
      }

      final now = DateTime.now();

      final transferId = _uuid.v4();

      await _db
          .into(_db.transfers)
          .insert(
            TransfersCompanion.insert(
              id: transferId,
              userId: uid,
              createdAt: now,
              updatedAt: now,
              deletedAt: const Value(null),
              syncStatus: SyncStatus.synced,
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              amountMinor: amountMinor,
              transferredAt: transferredAt ?? now,
              note: Value(note.trim()),
              goalId: Value(goalId),
            ),
          );

      return transferId;
    });
  }
}
