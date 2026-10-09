import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/enums.dart';

class GoalRepository {
  GoalRepository(this._db, {required this.userId});

  final AppDatabase _db;
  final String Function() userId;

  Stream<List<GoalRow>> watchGoals() {
    final query = _db.select(_db.goals)
      ..where((g) => g.userId.equals(userId()) & g.deletedAt.isNull())
      ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]);

    return query.watch();
  }

  Future<void> createGoal({
    required String name,
    required int targetMinor,
    DateTime? targetDate,
    String iconKey = 'savings',
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Goal name cannot be empty.');
    }
    if (targetMinor <= 0) {
      throw ArgumentError('Target amount must be greater than zero.');
    }

    final now = DateTime.now();

    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            id: 'goal_${now.microsecondsSinceEpoch}',
            userId: userId(),
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: trimmedName,
            targetMinor: targetMinor,
            targetDate: Value(targetDate),
            iconKey: Value(iconKey),
          ),
        );
  }

  Future<void> updateSavedAmount({
    required String goalId,
    required int currentMinor,
  }) async {
    if (currentMinor < 0) {
      throw ArgumentError('Saved amount cannot be negative.');
    }

    final changed =
        await (_db.update(_db.goals)..where(
              (g) =>
                  g.id.equals(goalId) &
                  g.userId.equals(userId()) &
                  g.deletedAt.isNull(),
            ))
            .write(
              GoalsCompanion(
                currentMinor: Value(currentMinor),
                updatedAt: Value(DateTime.now()),
                syncStatus: const Value(SyncStatus.synced),
              ),
            );

    if (changed == 0) {
      throw StateError('Savings goal not found.');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    await (_db.update(_db.goals)..where(
          (g) =>
              g.id.equals(goalId) &
              g.userId.equals(userId()) &
              g.deletedAt.isNull(),
        ))
        .write(
          GoalsCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value(SyncStatus.synced),
          ),
        );
  }
}
