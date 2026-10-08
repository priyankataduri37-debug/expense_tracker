import 'package:drift/drift.dart';
import 'enums.dart';

/// Columns shared by every table that syncs to the cloud.
mixin SyncColumns on Table {
  TextColumn get id => text()(); // UUID, generated on the device
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  /// JSON snapshot of this row as it was at the last successful sync.
  /// The sync engine compares it with the current row (and with the cloud
  /// row) to find which fields changed on which side -> field-level merge.
  TextColumn get baseJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRow')
@TableIndex(name: 'idx_tx_occurred', columns: {#occurredAt})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId})
@TableIndex(name: 'idx_tx_account', columns: {#accountId})
@TableIndex(name: 'idx_tx_sync', columns: {#syncStatus})
class Transactions extends Table with SyncColumns {
  IntColumn get amountMinor => integer()(); // 2500 = 25.00
  TextColumn get type => textEnum<TxType>()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get attachmentPath => text().nullable()();
  // Set when a recurring rule generated this transaction.
  TextColumn get recurringRuleId => text().nullable()();
}

@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();
  // Each account can have its own currency (multi-currency stretch goal).
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get iconKey => text()(); // maps to an Icon in the UI
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// One table for both budget kinds:
/// categoryId == null -> overall monthly budget
/// categoryId != null -> budget for that category
@DataClassName('BudgetRow')
class Budgets extends Table with SyncColumns {
  TextColumn get categoryId => text().nullable()();
  IntColumn get amountMinor => integer()();
}

@DataClassName('GoalRow')
class Goals extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();
  IntColumn get currentMinor => integer().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get iconKey => text().withDefault(const Constant('savings'))();
}

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table with SyncColumns {
  TextColumn get title => text()(); // "Netflix", "Rent"
  IntColumn get amountMinor => integer()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get categoryId => text()();
  TextColumn get accountId => text()();
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueAt => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Local-only key/value store (never synced), e.g. key 'lastSyncAt'.
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
