import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/history_provider.dart';

Future<void> showHistoryFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _categoryId;
  String? _accountId;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();

    final f = context.read<HistoryProvider>().filter;
    _categoryId = f.categoryId;
    _accountId = f.accountId;
    _minCtrl.text = _toText(f.minMinor);
    _maxCtrl.text = _toText(f.maxMinor);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }


  String _toText(int? minor) {
    if (minor == null) return '';
    return minor % 100 == 0
        ? '${minor ~/ 100}'
        : (minor / 100).toStringAsFixed(2);
  }

  int? _toMinor(String s) {
    final v = double.tryParse(s.trim().replaceAll(',', ''));
    return v == null ? null : (v * 100).round();
  }

  void _apply() {
    final min = _toMinor(_minCtrl.text);
    final max = _toMinor(_maxCtrl.text);

    if ((_minCtrl.text.trim().isNotEmpty && min == null) ||
        (_maxCtrl.text.trim().isNotEmpty && max == null)) {
      setState(() => _error = 'Enter valid amounts');
      return;
    }
    if (min != null && max != null && min > max) {
      setState(() => _error = 'Minimum is higher than maximum');
      return;
    }

    final h = context.read<HistoryProvider>();
    h.setFilter(
      h.filter.copyWith(
        categoryId: _categoryId,
        accountId: _accountId,
        minMinor: min,
        maxMinor: max,
      ),
    );
    Navigator.pop(context);
  }

  void _reset() {
    final h = context.read<HistoryProvider>();
    h.setFilter(
      h.filter.copyWith(
        categoryId: null,
        accountId: null,
        minMinor: null,
        maxMinor: null,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoryProvider>();
    final accounts = context.watch<AccountProvider>().active;


    final categories = [
      ...cats.forType(TxType.expense),
      ...cats.forType(TxType.income),
    ];
    final categoryIds = categories.map((c) => c.id).toSet();
    final accountIds = accounts.map((a) => a.id).toSet();


    final categoryValue = categoryIds.contains(_categoryId)
        ? _categoryId
        : null;
    final accountValue = accountIds.contains(_accountId) ? _accountId : null;

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
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: categoryValue,
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
                for (final c in categories)
                  DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(
                      '${c.name} • ${c.type == TxType.expense ? 'Expense' : 'Income'}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: accountValue,
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
                for (final a in accounts)
                  DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
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
            Row(
              children: [
                TextButton(onPressed: _reset, child: const Text('Reset')),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('Apply')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
