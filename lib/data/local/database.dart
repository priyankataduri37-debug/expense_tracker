import 'package:drift/drift.dart';

import 'enums.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Accounts,
    Categories,
    Budgets,
    Goals,
    RecurringRules,
    SyncMeta,
    Transfers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(transfers);
      }
    },
  );

  Future<void> _seedDefaults() async {
    final now = DateTime.now();

    CategoriesCompanion cat(String id, String name, TxType type, String icon) =>
        CategoriesCompanion.insert(
          id: id,
          userId: 'local',
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          name: name,
          type: type,
          iconKey: icon,
        );

    await batch((b) {
      b.insertAll(categories, [
        cat('exp_food', 'Food', TxType.expense, 'restaurant'),
        cat('exp_travel', 'Travel', TxType.expense, 'flight'),
        cat('exp_shopping', 'Shopping', TxType.expense, 'shopping_bag'),
        cat('exp_bills', 'Bills', TxType.expense, 'receipt_long'),
        cat('exp_rent', 'Rent', TxType.expense, 'home'),
        cat('exp_entertainment', 'Entertainment', TxType.expense, 'movie'),
        cat('exp_health', 'Health', TxType.expense, 'medical_services'),
        cat('exp_education', 'Education', TxType.expense, 'school'),
        cat(
          'exp_subscription',
          'Subscription',
          TxType.expense,
          'subscriptions',
        ),
        cat('exp_other', 'Other', TxType.expense, 'category'),
        cat('inc_salary', 'Salary', TxType.income, 'payments'),
        cat('inc_freelance', 'Freelance', TxType.income, 'laptop'),
        cat('inc_business', 'Business', TxType.income, 'storefront'),
        cat('inc_investment', 'Investment', TxType.income, 'trending_up'),
        cat('inc_gift', 'Gift', TxType.income, 'card_giftcard'),
        cat('inc_other', 'Other', TxType.income, 'category'),
      ]);

      b.insert(
        accounts,
        AccountsCompanion.insert(
          id: 'acc_cash',
          userId: 'local',
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          name: 'Cash',
          type: AccountType.cash,
        ),
      );
    });
  }
}
