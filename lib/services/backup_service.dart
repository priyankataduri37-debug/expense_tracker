import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../data/local/database.dart';
import '../data/local/enums.dart';
import '../data/repositories/sync_meta_repository.dart';

class BackupService {
  BackupService(this._db, {required this._userId, required this._syncMeta});

  final AppDatabase _db;
  final String Function() _userId;
  final SyncMetaRepository _syncMeta;

  static const int currentVersion = 1;





  Future<String> createBackup() async {
    final uid = _userId();

    final transactions = await (_db.select(
      _db.transactions,
    )..where((t) => t.userId.equals(uid) & t.deletedAt.isNull())).get();

    final accounts = await (_db.select(
      _db.accounts,
    )..where((a) => a.userId.equals(uid) & a.deletedAt.isNull())).get();




    final categories =
        await (_db.select(_db.categories)..where(
              (c) =>
                  c.userId.equals(uid) &
                  c.isCustom.equals(true) &
                  c.deletedAt.isNull(),
            ))
            .get();

    final budgets = await (_db.select(
      _db.budgets,
    )..where((b) => b.userId.equals(uid) & b.deletedAt.isNull())).get();

    final goals = await (_db.select(
      _db.goals,
    )..where((g) => g.userId.equals(uid) & g.deletedAt.isNull())).get();

    final recurringRules = await (_db.select(
      _db.recurringRules,
    )..where((r) => r.userId.equals(uid) & r.deletedAt.isNull())).get();

    final data = <String, dynamic>{
      'app': 'expense_tracker',
      'version': currentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),

      'transactions': transactions.map(_transactionToJson).toList(),
      'accounts': accounts.map(_accountToJson).toList(),
      'categories': categories.map(_categoryToJson).toList(),
      'budgets': budgets.map(_budgetToJson).toList(),
      'goals': goals.map(_goalToJson).toList(),
      'recurringRules': recurringRules.map(_recurringRuleToJson).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }





  Future<String?> exportBackup() async {
    final jsonString = await createBackup();

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    final result = await FilePicker.saveFile(
      dialogTitle: 'Save Expense Tracker Backup',
      fileName: 'expense_tracker_backup_$timestamp.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonString),
    );

    return result?.toString();
  }





  Future<BackupRestoreResult> pickAndRestore() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) {
      return const BackupRestoreResult.cancelled();
    }

    final bytes = await file.readAsBytes();
    final jsonString = utf8.decode(bytes);

    return restoreFromJson(jsonString);
  }





  Future<BackupRestoreResult> restoreFromJson(String jsonString) async {
    final data = _validateBackup(jsonString);

    final uid = _userId();
    final now = DateTime.now();

    final transactions = (data['transactions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final accounts = (data['accounts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final categories = (data['categories'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final budgets = (data['budgets'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final goals = (data['goals'] as List<dynamic>).cast<Map<String, dynamic>>();

    final recurringRules = (data['recurringRules'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    await _db.transaction(() async {






      await (_db.delete(
        _db.transactions,
      )..where((t) => t.userId.equals(uid))).go();

      await (_db.delete(_db.accounts)..where((a) => a.userId.equals(uid))).go();

      await (_db.delete(
        _db.categories,
      )..where((c) => c.userId.equals(uid) & c.isCustom.equals(true))).go();

      await (_db.delete(_db.budgets)..where((b) => b.userId.equals(uid))).go();

      await (_db.delete(_db.goals)..where((g) => g.userId.equals(uid))).go();

      await (_db.delete(
        _db.recurringRules,
      )..where((r) => r.userId.equals(uid))).go();








      for (final row in transactions) {
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.pendingCreate,
                amountMinor: _requiredInt(row, 'amountMinor'),
                type: _enum<TxType>(row, 'type', TxType.values),
                categoryId: _requiredString(row, 'categoryId'),
                accountId: _requiredString(row, 'accountId'),
                note: Value(_string(row, 'note') ?? ''),
                occurredAt: _date(row, 'occurredAt'),
                attachmentPath: Value(_string(row, 'attachmentPath')),
                recurringRuleId: Value(_string(row, 'recurringRuleId')),
              ),
            );
      }







      for (final row in accounts) {
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.synced,
                name: _requiredString(row, 'name'),
                type: _enum<AccountType>(row, 'type', AccountType.values),
                currencyCode: Value(_string(row, 'currencyCode') ?? 'INR'),
                openingBalanceMinor: Value(
                  _int(row, 'openingBalanceMinor') ?? 0,
                ),
                isArchived: Value(_bool(row, 'isArchived') ?? false),
              ),
            );
      }





      for (final row in categories) {
        await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.synced,
                name: _requiredString(row, 'name'),
                type: _enum<TxType>(row, 'type', TxType.values),
                iconKey: _requiredString(row, 'iconKey'),
                colorValue: Value(_int(row, 'colorValue')),
                isCustom: const Value(true),
                isArchived: Value(_bool(row, 'isArchived') ?? false),
              ),
            );
      }





      for (final row in budgets) {
        await _db
            .into(_db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.synced,
                categoryId: Value(_string(row, 'categoryId')),
                amountMinor: _requiredInt(row, 'amountMinor'),
              ),
            );
      }





      for (final row in goals) {
        await _db
            .into(_db.goals)
            .insert(
              GoalsCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.synced,
                name: _requiredString(row, 'name'),
                targetMinor: _requiredInt(row, 'targetMinor'),
                currentMinor: Value(_int(row, 'currentMinor') ?? 0),
                targetDate: Value(_dateNullable(row, 'targetDate')),
                iconKey: Value(_string(row, 'iconKey') ?? 'savings'),
              ),
            );
      }





      for (final row in recurringRules) {
        await _db
            .into(_db.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: _requiredString(row, 'id'),
                userId: uid,
                createdAt: _date(row, 'createdAt'),
                updatedAt: now,
                syncStatus: SyncStatus.synced,
                title: _requiredString(row, 'title'),
                amountMinor: _requiredInt(row, 'amountMinor'),
                type: _enum<TxType>(row, 'type', TxType.values),
                categoryId: _requiredString(row, 'categoryId'),
                accountId: _requiredString(row, 'accountId'),
                frequency: _enum<RecurrenceFrequency>(
                  row,
                  'frequency',
                  RecurrenceFrequency.values,
                ),
                startDate: _date(row, 'startDate'),
                nextDueAt: _date(row, 'nextDueAt'),
                endDate: Value(_dateNullable(row, 'endDate')),
                isActive: Value(_bool(row, 'isActive') ?? true),
                note: Value(_string(row, 'note') ?? ''),
              ),
            );
      }
    });



    await _syncMeta.clear(uid);

    return BackupRestoreResult.success(
      transactions: transactions.length,
      accounts: accounts.length,
      categories: categories.length,
      budgets: budgets.length,
      goals: goals.length,
      recurringRules: recurringRules.length,
    );
  }





  Map<String, dynamic> _validateBackup(String jsonString) {
    dynamic decoded;

    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const FormatException('The selected file is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup must contain a JSON object.');
    }

    if (decoded['app'] != 'expense_tracker') {
      throw const FormatException(
        'This file is not an Expense Tracker backup.',
      );
    }

    final version = decoded['version'];

    if (version is! int || version != currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }

    const requiredLists = [
      'transactions',
      'accounts',
      'categories',
      'budgets',
      'goals',
      'recurringRules',
    ];

    for (final key in requiredLists) {
      if (decoded[key] is! List) {
        throw FormatException('Backup is missing the "$key" section.');
      }
    }

    return decoded;
  }





  Map<String, dynamic> _transactionToJson(TransactionRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'amountMinor': row.amountMinor,
    'type': row.type.toString().split('.').last,
    'categoryId': row.categoryId,
    'accountId': row.accountId,
    'note': row.note,
    'occurredAt': row.occurredAt.toUtc().toIso8601String(),
    'attachmentPath': row.attachmentPath,
    'recurringRuleId': row.recurringRuleId,
  };

  Map<String, dynamic> _accountToJson(AccountRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'name': row.name,
    'type': row.type.toString().split('.').last,
    'currencyCode': row.currencyCode,
    'openingBalanceMinor': row.openingBalanceMinor,
    'isArchived': row.isArchived,
  };

  Map<String, dynamic> _categoryToJson(CategoryRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'name': row.name,
    'type': row.type.toString().split('.').last,
    'iconKey': row.iconKey,
    'colorValue': row.colorValue,
    'isCustom': true,
    'isArchived': row.isArchived,
  };

  Map<String, dynamic> _budgetToJson(BudgetRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'categoryId': row.categoryId,
    'amountMinor': row.amountMinor,
  };

  Map<String, dynamic> _goalToJson(GoalRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'name': row.name,
    'targetMinor': row.targetMinor,
    'currentMinor': row.currentMinor,
    'targetDate': row.targetDate?.toUtc().toIso8601String(),
    'iconKey': row.iconKey,
  };

  Map<String, dynamic> _recurringRuleToJson(RecurringRuleRow row) => {
    'id': row.id,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'title': row.title,
    'amountMinor': row.amountMinor,
    'type': row.type.toString().split('.').last,
    'categoryId': row.categoryId,
    'accountId': row.accountId,
    'frequency': row.frequency.toString().split('.').last,
    'startDate': row.startDate.toUtc().toIso8601String(),
    'nextDueAt': row.nextDueAt.toUtc().toIso8601String(),
    'endDate': row.endDate?.toUtc().toIso8601String(),
    'isActive': row.isActive,
    'note': row.note,
  };





  String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid "$key" in backup.');
    }

    return value;
  }

  String? _string(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) return null;

    if (value is! String) {
      throw FormatException('Invalid "$key" in backup.');
    }

    return value;
  }

  int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! int) {
      throw FormatException('Invalid "$key" in backup.');
    }

    return value;
  }

  int? _int(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) return null;

    if (value is! int) {
      throw FormatException('Invalid "$key" in backup.');
    }

    return value;
  }

  bool? _bool(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) return null;

    if (value is! bool) {
      throw FormatException('Invalid "$key" in backup.');
    }

    return value;
  }

  DateTime _date(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! String) {
      throw FormatException('Invalid "$key" in backup.');
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      throw FormatException('Invalid date in "$key".');
    }
  }

  DateTime? _dateNullable(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) return null;

    if (value is! String) {
      throw FormatException('Invalid "$key" in backup.');
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      throw FormatException('Invalid date in "$key".');
    }
  }

  T _enum<T>(Map<String, dynamic> row, String key, List<T> values) {
    final value = row[key];

    if (value is! String) {
      throw FormatException('Invalid "$key" in backup.');
    }

    for (final item in values) {
      final enumName = item.toString().split('.').last;

      if (enumName == value) {
        return item;
      }
    }

    throw FormatException('Unknown "$key" value: $value');
  }
}





class BackupRestoreResult {
  const BackupRestoreResult._({
    required this.wasCancelled,
    this.transactions = 0,
    this.accounts = 0,
    this.categories = 0,
    this.budgets = 0,
    this.goals = 0,
    this.recurringRules = 0,
  });

  const BackupRestoreResult.cancelled() : this._(wasCancelled: true);

  const BackupRestoreResult.success({
    required int transactions,
    required int accounts,
    required int categories,
    required int budgets,
    required int goals,
    required int recurringRules,
  }) : this._(
         wasCancelled: false,
         transactions: transactions,
         accounts: accounts,
         categories: categories,
         budgets: budgets,
         goals: goals,
         recurringRules: recurringRules,
       );

  final bool wasCancelled;
  final int transactions;
  final int accounts;
  final int categories;
  final int budgets;
  final int goals;
  final int recurringRules;

  int get total =>
      transactions + accounts + categories + budgets + goals + recurringRules;
}
