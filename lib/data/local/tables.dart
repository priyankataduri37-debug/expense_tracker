import 'package:drift/drift.dart';
import 'enums.dart';

mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

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
  TextColumn get recurringRuleId => text().nullable()();
}

@DataClassName('AccountRow')
class Accounts extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => textEnum<TxType>()();
  TextColumn get iconKey => text()();
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

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
  TextColumn get title => text()();
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

@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('TransferRow')
class Transfers extends Table with SyncColumns {
  TextColumn get fromAccountId => text()();
  TextColumn get toAccountId => text()();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get transferredAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get goalId => text().nullable()();
}