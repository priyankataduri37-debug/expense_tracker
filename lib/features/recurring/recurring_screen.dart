import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/settings_provider.dart';

class RecurringScreen extends StatelessWidget {
const RecurringScreen({super.key});

@override
Widget build(BuildContext context) {
final provider = context.watch<RecurringProvider>();
final currency = context.watch<SettingsProvider>().currencySymbol;

return Scaffold(
appBar: AppBar(title: const Text('Recurring transactions')),
floatingActionButton: FloatingActionButton(
onPressed: () => _showAddDialog(context),
child: const Icon(Icons.add),
),
body: provider.isLoading
? const Center(child: CircularProgressIndicator())
    : provider.items.isEmpty
? const Center(
child: Text('No recurring transactions yet. Tap + to add one.'),
)
    : ListView.builder(
padding: const EdgeInsets.only(bottom: 88),
itemCount: provider.items.length,
itemBuilder: (context, index) {
final rule = provider.items[index];

return Dismissible(
key: ValueKey(rule.id),
direction: DismissDirection.endToStart,
background: Container(
alignment: Alignment.centerRight,
padding: const EdgeInsets.symmetric(horizontal: 20),
color: Theme.of(context).colorScheme.error,
child: const Icon(Icons.delete, color: Colors.white),
),
confirmDismiss: (_) async {
return await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Delete recurring rule?'),
content: Text(
'Delete "${rule.title}"? Existing transactions '
'created from this rule will remain.',
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
child: const Text('Delete'),
),
],
),
) ??
false;
},
onDismissed: (_) async {
try {
await context.read<RecurringProvider>().delete(rule.id);
} catch (e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Delete failed: $e')),
);
}
}
},
child: Card(
margin: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 5,
),
child: ListTile(
leading: CircleAvatar(
child: Icon(
rule.type == TxType.income
? Icons.trending_up
    : Icons.repeat,
),
),
title: Text(rule.title),
subtitle: Text(
'$currency${(rule.amountMinor / 100).toStringAsFixed(2)}'
' • ${_frequencyName(rule.frequency)}'
'\nNext: ${_dateLabel(rule.nextDueAt)}',
),
isThreeLine: true,
trailing: Switch(
value: rule.isActive,
onChanged: (value) async {
try {
await context
    .read<RecurringProvider>()
    .setActive(rule.id, value);
} catch (e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Update failed: $e'),
),
);
}
}
},
),
),
),
);
},
),
);
}

String _frequencyName(RecurrenceFrequency frequency) {
switch (frequency) {
case RecurrenceFrequency.daily:
return 'Daily';
case RecurrenceFrequency.weekly:
return 'Weekly';
case RecurrenceFrequency.monthly:
return 'Monthly';
case RecurrenceFrequency.yearly:
return 'Yearly';
}
}

String _dateLabel(DateTime date) =>
'${date.day.toString().padLeft(2, '0')}/'
'${date.month.toString().padLeft(2, '0')}/${date.year}';

Future<void> _showAddDialog(BuildContext context) async {
await showDialog<void>(
context: context,
builder: (_) => const _AddRecurringDialog(),
);
}
}

class _AddRecurringDialog extends StatefulWidget {
const _AddRecurringDialog();

@override
State<_AddRecurringDialog> createState() => _AddRecurringDialogState();
}

class _AddRecurringDialogState extends State<_AddRecurringDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  TxType _type = TxType.expense;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  String? _categoryId;
  String? _accountId;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().forType(_type);
    final accounts = context
        .watch<AccountProvider>()
        .active;

    if (_categoryId != null &&
        !categories.any((category) => category.id == _categoryId)) {
      _categoryId = null;
    }
    if (_accountId != null &&
        !accounts.any((account) => account.id == _accountId)) {
      _accountId = null;
    }

    return AlertDialog(
      title: const Text('Add recurring transaction'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                  value == null || value
                      .trim()
                      .isEmpty
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText:
                    context
                        .read<SettingsProvider>()
                        .currencySymbol,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TxType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: TxType.expense,
                      child: Text('Expense'),
                    ),
                    DropdownMenuItem(
                      value: TxType.income,
                      child: Text('Income'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                      _categoryId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (category) =>
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                  )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                  value == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map(
                        (account) =>
                        DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                  )
                      .toList(),
                  onChanged: (value) => setState(() => _accountId = value),
                  validator: (value) =>
                  value == null ? 'Select an account' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(
                      value: RecurrenceFrequency.daily,
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.weekly,
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.monthly,
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceFrequency.yearly,
                      child: Text('Yearly'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _frequency = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickStartDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() => _startDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final amountMinor = (amount * 100).round();
    final categoryId = _categoryId;
    final accountId = _accountId;

    if (categoryId == null || accountId == null) return;

    try {
      await context.read<RecurringProvider>().add(
        title: _titleController.text.trim(),
        amountMinor: amountMinor,
        type: _type,
        categoryId: categoryId,
        accountId: accountId,
        frequency: _frequency,
        startDate: _startDate,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring transaction added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add recurring transaction: $e')),
      );
    }
  }
}