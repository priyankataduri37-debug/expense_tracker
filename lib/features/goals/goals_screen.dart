import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/icon_map.dart';
import '../../core/utils/money.dart';
import '../../data/local/database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/transfer_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/settings_provider.dart';

/// Icons a goal can use. These keys exist in icon_map.dart.
const _goalIconKeys = [
  'savings',
  'laptop',
  'flight',
  'home',
  'school',
  'card_giftcard',
  'shopping_bag',
  'medical_services',
];

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final goals = provider.goals;
    final theme = Theme.of(context);
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    String money(int minor) => formatMinor(minor, symbol: symbol);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: provider.error != null
          ? Center(child: Text('Could not load goals: ${provider.error}'))
          : goals.isEmpty
          ? const Center(
        child: Text(
          'No savings goals yet.\nCreate your first goal!',
          textAlign: TextAlign.center,
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total saved',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(
                      goals.fold<int>(
                        0,
                            (sum, goal) => sum + goal.currentMinor,
                      ),
                    ),
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text('${goals.length} active goals'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final goal in goals)
            _GoalCard(
              goal: goal,
              money: money,
              onContribute: () =>
                  _showContributionDialog(context, goal),
              onEdit: () => _showSavedAmountDialog(context, goal),
              onDelete: () => _confirmDelete(context, goal),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final goalProvider = context.read<GoalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? targetDate;
    String iconKey = 'savings';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Create savings goal'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Goal name',
                        hintText: 'e.g. New laptop',
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a goal name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Target amount ($symbol)',
                        hintText: '10000',
                      ),
                      validator: _validatePositiveAmount,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: targetDate ??
                              DateTime(now.year, now.month, now.day),
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null && dialogContext.mounted) {
                          setDialogState(() => targetDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        targetDate == null
                            ? 'Optional target date'
                            : MaterialLocalizations.of(dialogContext)
                            .formatMediumDate(targetDate!),
                      ),
                    ),
                    if (targetDate != null)
                      TextButton(
                        onPressed: () =>
                            setDialogState(() => targetDate = null),
                        child: const Text('Remove date'),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Icon',
                        style: Theme.of(dialogContext).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in _goalIconKeys)
                          ChoiceChip(
                            showCheckmark: false,
                            label: Icon(iconFor(key)),
                            selected: iconKey == key,
                            onSelected: (_) =>
                                setDialogState(() => iconKey = key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );

      if (result != true || !context.mounted) return;

      final amount = double.parse(amountController.text.trim());
      await goalProvider.createGoal(
        name: nameController.text.trim(),
        targetMinor: (amount * 100).round(),
        targetDate: targetDate,
        iconKey: iconKey,
      );

      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Savings goal created')),
      );
    } catch (error) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Could not create goal: $error')),
      );
    } finally {
      nameController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _showContributionDialog(
      BuildContext context,
      GoalRow goal,
      ) async {
    // Capture dependencies before any asynchronous operation.
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final accountRepository = context.read<AccountRepository>();
    final transferRepository = context.read<TransferRepository>();
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? fromAccountId;
    String? toAccountId;
    bool saving = false;

    try {
      final accounts = await accountRepository.getAccountsWithBalances(
        userId: authProvider.userId,
      );

      if (!context.mounted) return;

      final usableAccounts = accounts
          .where((item) => item.account.currencyCode == 'INR')
          .toList();

      if (usableAccounts.length < 2) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Create at least two INR accounts to make a savings transfer.',
            ),
          ),
        );
        return;
      }

      fromAccountId = usableAccounts.first.account.id;
      toAccountId = usableAccounts.last.account.id;

      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text('Add to ${goal.name}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Contribution amount ($symbol)',
                      ),
                      validator: _validatePositiveAmount,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: fromAccountId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Transfer from',
                      ),
                      items: usableAccounts.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.account.id,
                          child: Text(
                            item.account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                        setDialogState(() {
                          fromAccountId = value;

                          if (toAccountId == value) {
                            toAccountId = usableAccounts
                                .firstWhere(
                                  (item) => item.account.id != value,
                            )
                                .account
                                .id;
                          }
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Choose a source account' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: toAccountId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Transfer to (savings account)',
                      ),
                      items: usableAccounts
                          .where(
                            (item) => item.account.id != fromAccountId,
                      )
                          .map((item) {
                        return DropdownMenuItem<String>(
                          value: item.account.id,
                          child: Text(
                            item.account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                        setDialogState(() => toAccountId = value);
                      },
                      validator: (value) =>
                      value == null || value == fromAccountId
                          ? 'Choose a different destination account'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This transfer updates account balances without '
                          'counting as income or an expense.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;

                  final sourceId = fromAccountId;
                  final destinationId = toAccountId;

                  if (sourceId == null ||
                      destinationId == null ||
                      sourceId == destinationId) {
                    return;
                  }

                  setDialogState(() => saving = true);

                  try {
                    final amount =
                    double.parse(amountController.text.trim());

                    await transferRepository.createTransfer(
                      userId: authProvider.userId,
                      fromAccountId: sourceId,
                      toAccountId: destinationId,
                      amountMinor: (amount * 100).round(),
                      note: noteController.text.trim(),
                      goalId: goal.id,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  } catch (error) {
                    if (dialogContext.mounted) {
                      setDialogState(() => saving = false);
                    }

                    if (!context.mounted) return;

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not add contribution: $error',
                        ),
                      ),
                    );
                  }
                },
                child: saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Add contribution'),
              ),
            ],
          ),
        ),
      );

      if (result == true && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Contribution added successfully'),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Could not load accounts: $error')),
      );
    } finally {
      amountController.dispose();
      noteController.dispose();
    }
  }

  String? _validatePositiveAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');

    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 90000000000000) {
      return 'Enter a valid positive amount';
    }

    if ((amount * 100).round() <= 0) {
      return 'Amount is too small';
    }

    return null;
  }

  Future<void> _showSavedAmountDialog(
      BuildContext context,
      GoalRow goal,
      ) async {
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final goalProvider = context.read<GoalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final controller = TextEditingController(
      text: (goal.currentMinor / 100).toStringAsFixed(2),
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Update ${goal.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Amount saved ($symbol)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != true || !context.mounted) return;

      final amount = double.tryParse(controller.text.trim());

      if (amount == null ||
          !amount.isFinite ||
          amount < 0 ||
          amount > 90000000000000) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid saved amount')),
        );
        return;
      }

      await goalProvider.updateSavedAmount(
        goalId: goal.id,
        currentMinor: (amount * 100).round(),
      );

      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Saved amount updated')),
      );
    } catch (error) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Could not update goal: $error')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDelete(
      BuildContext context,
      GoalRow goal,
      ) async {
    final goalProvider = context.read<GoalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Remove "${goal.name}" from your active goals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await goalProvider.deleteGoal(goal.id);

      if (!context.mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Goal deleted')),
      );
    } catch (error) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete goal: $error')),
      );
    }
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.money,
    required this.onContribute,
    required this.onEdit,
    required this.onDelete,
  });

  final GoalRow goal;
  final String Function(int) money;
  final VoidCallback onContribute;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
    (goal.currentMinor / goal.targetMinor).clamp(0.0, 1.0).toDouble();

    final remaining =
    (goal.targetMinor - goal.currentMinor).clamp(0, goal.targetMinor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    goal.currentMinor >= goal.targetMinor
                        ? Icons.check_circle_outline
                        : iconFor(goal.iconKey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Add contribution',
                  onPressed: onContribute,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: 'Update saved amount',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete goal',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).round()}% saved'),
                Text('Target ${money(goal.targetMinor)}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text('Saved: ${money(goal.currentMinor)}'),
            Text(
              remaining == 0
                  ? 'Goal achieved!'
                  : '${money(remaining)} left to save',
              style: TextStyle(
                color: remaining == 0
                    ? Colors.green
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Target date: '
                    '${MaterialLocalizations.of(context).formatMediumDate(goal.targetDate!)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}