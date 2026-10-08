import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/icon_map.dart';
import '../../data/local/database.dart';
import '../../data/local/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';

Future<void> showAddTransactionSheet(BuildContext context) =>
    showTransactionSheet(context);

/// Opens the form. Pass [existing] to edit a transaction instead of adding.
Future<void> showTransactionSheet(
  BuildContext context, {
  TransactionRow? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AddTransactionSheet(existing: existing),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, this.existing});

  final TransactionRow? existing;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TxType _type = TxType.expense;
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now(); // defaults to today
  TimeOfDay _time = TimeOfDay.now();
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _categoryId = e.categoryId;
      _accountId = e.accountId;
      _date = e.occurredAt;
      _time = TimeOfDay.fromDateTime(e.occurredAt);
      _amountCtrl.text = (e.amountMinor / 100).toStringAsFixed(2);
      _noteCtrl.text = e.note;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// "25.50" -> 2550. Returns null if empty, invalid or not positive.
  int? _parseMinor(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final minor = _parseMinor(_amountCtrl.text);
    if (minor == null) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Pick a category');
      return;
    }
    if (_accountId == null) {
      setState(() => _error = 'Pick an account');
      return;
    }

    final provider = context.read<TransactionProvider>();
    final navigator = Navigator.of(context);
    final occurredAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await provider.update(
          widget.existing!.id,
          amountMinor: minor,
          type: _type,
          categoryId: _categoryId,
          accountId: _accountId,
          occurredAt: occurredAt,
          note: _noteCtrl.text.trim(),
        );
      } else {
        await provider.add(
          amountMinor: minor,
          type: _type,
          categoryId: _categoryId!,
          accountId: _accountId!,
          occurredAt: occurredAt,
          note: _noteCtrl.text.trim(),
        );
      }
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().forType(_type);
    final accounts = context.watch<AccountProvider>().active;
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit transaction' : 'Add transaction',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(
                  value: TxType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TxType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null; // categories differ per type
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    avatar: Icon(iconFor(c.iconKey), size: 18),
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Account', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final a in accounts)
                  ChoiceChip(
                    label: Text(a.name),
                    selected: _accountId == a.id,
                    onSelected: (_) => setState(() => _accountId = a.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      MaterialLocalizations.of(context).formatMediumDate(_date),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
