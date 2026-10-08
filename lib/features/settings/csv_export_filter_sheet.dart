import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local/enums.dart';
import '../../data/models/transaction_filter.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';

Future<TransactionFilter?> showCsvExportFilterSheet(BuildContext context) {
  return showModalBottomSheet<TransactionFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CsvExportFilterSheet(),
  );
}

class _CsvExportFilterSheet extends StatefulWidget {
  const _CsvExportFilterSheet();

  @override
  State<_CsvExportFilterSheet> createState() => _CsvExportFilterSheetState();
}

class _CsvExportFilterSheetState extends State<_CsvExportFilterSheet> {
  String _search = '';

  TxType? _type;

  String? _categoryId;
  String? _accountId;

  DateTime? _from;
  DateTime? _to;

  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  int? _toMinor(String value) {
    final text = value.trim().replaceAll(',', '');

    if (text.isEmpty) return null;

    final amount = double.tryParse(text);

    if (amount == null) return null;

    return (amount * 100).round();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }

  bool get _hasDateRange => _from != null && _to != null;

  bool get _isThisMonth {
    if (_from == null || _to == null) return false;

    final now = DateTime.now();

    final start = DateTime(now.year, now.month, 1);

    final end = DateTime(now.year, now.month + 1, 1);

    return _from == start && _to == end;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(
              start: _from!,
              end: _to!.subtract(const Duration(days: 1)),
            )
          : null,
    );

    if (picked == null) return;

    setState(() {
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);

      // End date is exclusive.
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day + 1);
    });
  }

  void _selectThisMonth() {
    final now = DateTime.now();

    setState(() {
      _from = DateTime(now.year, now.month, 1);

      _to = DateTime(now.year, now.month + 1, 1);
    });
  }

  void _clearDate() {
    setState(() {
      _from = null;
      _to = null;
    });
  }

  void _reset() {
    setState(() {
      _search = '';
      _type = null;
      _categoryId = null;
      _accountId = null;
      _from = null;
      _to = null;
      _minCtrl.clear();
      _maxCtrl.clear();
      _error = null;
    });
  }

  void _export() {
    final min = _toMinor(_minCtrl.text);
    final max = _toMinor(_maxCtrl.text);

    if ((_minCtrl.text.trim().isNotEmpty && min == null) ||
        (_maxCtrl.text.trim().isNotEmpty && max == null)) {
      setState(() {
        _error = 'Enter valid amounts.';
      });
      return;
    }

    if (min != null && max != null && min > max) {
      setState(() {
        _error = 'Minimum amount is higher than maximum.';
      });
      return;
    }

    final filter = TransactionFilter(
      search: _search.trim().isEmpty ? null : _search.trim(),
      type: _type,
      categoryId: _categoryId,
      accountId: _accountId,
      from: _from,
      to: _to,
      minMinor: min,
      maxMinor: max,
    );

    Navigator.pop(context, filter);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesProvider = context.watch<CategoryProvider>();

    final accounts = context.watch<AccountProvider>().active;

    final categories = [
      ...categoriesProvider.forType(TxType.expense),
      ...categoriesProvider.forType(TxType.income),
    ];

    final categoryIds = categories.map((c) => c.id).toSet();

    final accountIds = accounts.map((a) => a.id).toSet();

    if (!categoryIds.contains(_categoryId)) {
      _categoryId = null;
    }

    if (!accountIds.contains(_accountId)) {
      _accountId = null;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CSV Export Filters',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 6),

            Text(
              'Choose which transactions to export.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------
            // SEARCH
            // ------------------------------------------------------
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Note, category or amount',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _search = value;
              },
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // TYPE
            // ------------------------------------------------------
            Text('Type', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _type == null,
                  onSelected: (_) {
                    setState(() {
                      _type = null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _type == TxType.income,
                  onSelected: (_) {
                    setState(() {
                      _type = TxType.income;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: _type == TxType.expense,
                  onSelected: (_) {
                    setState(() {
                      _type = TxType.expense;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // DATE
            // ------------------------------------------------------
            Text('Date', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('This month'),
                  selected: _isThisMonth,
                  onSelected: (_) {
                    _selectThisMonth();
                  },
                ),
                InputChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _hasDateRange
                        ? '${_formatDate(_from!)} - '
                              '${_formatDate(_to!.subtract(const Duration(days: 1)))}'
                        : 'Date range',
                  ),
                  selected: _hasDateRange && !_isThisMonth,
                  onPressed: _pickDateRange,
                  onDeleted: _hasDateRange ? _clearDate : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // CATEGORY
            // ------------------------------------------------------
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                for (final category in categories)
                  DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(
                      '${category.name} • '
                      '${category.type == TxType.expense ? 'Expense' : 'Income'}',
                    ),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // ACCOUNT
            // ------------------------------------------------------
            DropdownButtonFormField<String?>(
              initialValue: _accountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Account',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All accounts'),
                ),
                for (final account in accounts)
                  DropdownMenuItem<String?>(
                    value: account.id,
                    child: Text(account.name),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _accountId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // AMOUNT
            // ------------------------------------------------------
            Text('Amount', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 20),

            // ------------------------------------------------------
            // BUTTONS
            // ------------------------------------------------------
            Row(
              children: [
                TextButton(onPressed: _reset, child: const Text('Reset')),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
