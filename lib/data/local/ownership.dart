import 'package:drift/drift.dart';

import 'database.dart';

/// Moves rows created before login ('local') over to the logged-in user.
class LocalOwnership {
  LocalOwnership(this._db);

  final AppDatabase _db;
  static const localUserId = 'local';

  Future<void> claimLocalRows(String uid) async {
    if (uid == localUserId) return;

    // One database transaction: either everything moves or nothing does.
    await _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((t) => t.userId.equals(localUserId)))
          .write(TransactionsCompanion(userId: Value(uid)));

      await (_db.update(_db.accounts)
            ..where((t) => t.userId.equals(localUserId)))
          .write(AccountsCompanion(userId: Value(uid)));

      await (_db.update(_db.budgets)
            ..where((t) => t.userId.equals(localUserId)))
          .write(BudgetsCompanion(userId: Value(uid)));

      await (_db.update(_db.goals)..where((t) => t.userId.equals(localUserId)))
          .write(GoalsCompanion(userId: Value(uid)));

      await (_db.update(_db.recurringRules)
            ..where((t) => t.userId.equals(localUserId)))
          .write(RecurringRulesCompanion(userId: Value(uid)));

      // Only custom categories. Default ones stay 'local' and are never uploaded.
      await (_db.update(_db.categories)..where(
            (t) => t.userId.equals(localUserId) & t.isCustom.equals(true),
          ))
          .write(CategoriesCompanion(userId: Value(uid)));
    });
  }
}
