import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../data/local/database.dart';
import '../data/local/enums.dart';
import '../data/models/transaction_filter.dart';

class CsvExportService {
  CsvExportService(this._db, {required this._userId});

  final AppDatabase _db;
  final String Function() _userId;

  Future<String?> exportTransactions({
    TransactionFilter filter = TransactionFilter.none,
  }) async {
    final uid = _userId();

    // ------------------------------------------------------------
    // Build database query using the selected filters.
    // ------------------------------------------------------------

    final query = _db.select(_db.transactions)
      ..where((t) {
        Expression<bool> condition =
            t.userId.equals(uid) & t.deletedAt.isNull();

        // Income / Expense
        if (filter.type != null) {
          condition = condition & t.type.equalsValue(filter.type!);
        }

        // Category
        if (filter.categoryId != null) {
          condition = condition & t.categoryId.equals(filter.categoryId!);
        }

        // Account
        if (filter.accountId != null) {
          condition = condition & t.accountId.equals(filter.accountId!);
        }

        // Minimum amount
        if (filter.minMinor != null) {
          condition =
              condition & t.amountMinor.isBiggerOrEqualValue(filter.minMinor!);
        }

        // Maximum amount
        if (filter.maxMinor != null) {
          condition =
              condition & t.amountMinor.isSmallerOrEqualValue(filter.maxMinor!);
        }

        // Date from
        if (filter.from != null) {
          condition =
              condition & t.occurredAt.isBiggerOrEqualValue(filter.from!);
        }

        // Date to is EXCLUSIVE in TransactionFilter.
        if (filter.to != null) {
          condition = condition & t.occurredAt.isSmallerThanValue(filter.to!);
        }

        return condition;
      })
      ..orderBy([
        (t) => OrderingTerm.asc(t.occurredAt),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    var transactions = await query.get();

    // ------------------------------------------------------------
    // Load categories.
    // Default categories are owned by "local".
    // Custom categories belong to the signed-in user.
    // ------------------------------------------------------------

    final categories =
        await (_db.select(_db.categories)..where(
              (c) =>
                  (c.userId.equals(uid) | c.userId.equals('local')) &
                  c.deletedAt.isNull(),
            ))
            .get();

    final categoryNames = <String, String>{
      for (final category in categories) category.id: category.name,
    };

    // ------------------------------------------------------------
    // Load accounts.
    // ------------------------------------------------------------

    final accounts = await (_db.select(
      _db.accounts,
    )..where((a) => a.userId.equals(uid) & a.deletedAt.isNull())).get();

    final accountNames = <String, String>{
      for (final account in accounts) account.id: account.name,
    };

    // ------------------------------------------------------------
    // Search filter.
    //
    // History supports searching note, category or amount.
    // The other filters above are handled directly by SQLite.
    // ------------------------------------------------------------

    final search = filter.search?.trim().toLowerCase();

    if (search != null && search.isNotEmpty) {
      transactions = transactions.where((transaction) {
        final note = transaction.note.toLowerCase();

        final category = (categoryNames[transaction.categoryId] ?? '')
            .toLowerCase();

        final amount = _formatAmount(transaction.amountMinor);

        return note.contains(search) ||
            category.contains(search) ||
            amount.contains(search);
      }).toList();
    }

    // ------------------------------------------------------------
    // Build CSV.
    // ------------------------------------------------------------

    final buffer = StringBuffer();

    buffer.writeln('Date,Type,Category,Account,Amount,Note');

    for (final transaction in transactions) {
      final date = _formatDate(transaction.occurredAt);

      final type = transaction.type == TxType.expense ? 'Expense' : 'Income';

      final category = categoryNames[transaction.categoryId] ?? 'Unknown';

      final account = accountNames[transaction.accountId] ?? 'Unknown';

      final amount = _formatAmount(transaction.amountMinor);

      final note = _escapeCsv(transaction.note);

      buffer.writeln(
        '$date,'
        '$type,'
        '${_escapeCsv(category)},'
        '${_escapeCsv(account)},'
        '$amount,'
        '$note',
      );
    }

    // ------------------------------------------------------------
    // Save file.
    // ------------------------------------------------------------

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    final result = await FilePicker.saveFile(
      dialogTitle: 'Export Transactions CSV',
      fileName: 'expense_transactions_$timestamp.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: utf8.encode(buffer.toString()),
    );

    return result?.toString();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatAmount(int amountMinor) {
    return (amountMinor / 100).toStringAsFixed(2);
  }

  String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }

    return value;
  }
}
