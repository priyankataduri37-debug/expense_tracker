import 'package:drift/drift.dart';

import '../local/database.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<AccountRow>> watchAll() {
    final query = _db.select(_db.accounts)
      ..where((a) => a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]);
    return query.watch();
  }
}
