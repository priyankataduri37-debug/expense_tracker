import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/enums.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<AccountRow>> watchAll() {
    final query = _db.select(_db.accounts)
      ..where((a) => a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]);

    return query.watch();
  }

  Future<List<AccountBalance>> getAccountsWithBalances({
    required String userId,
  }) async {
    final accounts =
        await (_db.select(_db.accounts)
              ..where(
                (a) =>
                    a.userId.equals(userId) &
                    a.deletedAt.isNull() &
                    a.isArchived.equals(false),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
            .get();

    final transactions = await (_db.select(
      _db.transactions,
    )..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();

    final transfers = await (_db.select(
      _db.transfers,
    )..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())).get();

    return accounts.map((account) {
      var balance = account.openingBalanceMinor;

      for (final tx in transactions) {
        if (tx.accountId != account.id) continue;

        if (tx.type == TxType.income) {
          balance += tx.amountMinor;
        } else {
          balance -= tx.amountMinor;
        }
      }

      for (final transfer in transfers) {
        if (transfer.fromAccountId == account.id) {
          balance -= transfer.amountMinor;
        }

        if (transfer.toAccountId == account.id) {
          balance += transfer.amountMinor;
        }
      }

      return AccountBalance(account: account, balanceMinor: balance);
    }).toList();
  }

  Future<Map<String, int>> getCombinedBalances({required String userId}) async {
    final accounts = await getAccountsWithBalances(userId: userId);
    final totals = <String, int>{};

    for (final item in accounts) {
      totals.update(
        item.account.currencyCode,
        (balance) => balance + item.balanceMinor,
        ifAbsent: () => item.balanceMinor,
      );
    }

    return totals;
  }

  Future<void> createAccount({
    required String userId,
    required String name,
    required AccountType type,
    required String currencyCode,
    required int openingBalanceMinor,
  }) async {
    final now = DateTime.now();

    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: '${now.microsecondsSinceEpoch}',
            userId: userId,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: name.trim(),
            type: type,
            currencyCode: Value(currencyCode.toUpperCase()),
            openingBalanceMinor: Value(openingBalanceMinor),
          ),
        );
  }
}

class AccountBalance {
  const AccountBalance({required this.account, required this.balanceMinor});

  final AccountRow account;
  final int balanceMinor;
}
