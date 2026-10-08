import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/money.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final budgetProvider = context.read<BudgetProvider>();

    final current = budgetProvider.budgetFor(widget.categoryId);

    if (current != null) {
      _amountController.text = (current / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.categoryId == null) {
      return 'Monthly Budget';
    }

    final category = context.read<CategoryProvider>().byId(widget.categoryId!);

    if (category == null) {
      return 'Category Budget';
    }

    return '${category.name} Budget';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final amountMinor = (amount * 100).round();

    setState(() {
      _saving = true;
    });

    try {
      await context.read<BudgetProvider>().setBudget(
        categoryId: widget.categoryId,
        amountMinor: amountMinor,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.categoryId == null
                ? 'Monthly budget saved.'
                : 'Category budget saved.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save budget: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear budget?'),
        content: Text(
          widget.categoryId == null
              ? 'Your monthly budget will be removed.'
              : 'This category budget will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
    });

    try {
      await context.read<BudgetProvider>().clearBudget(
        categoryId: widget.categoryId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.categoryId == null
                ? 'Monthly budget cleared.'
                : 'Category budget cleared.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to clear budget: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();

    final existingBudget = budgetProvider.budgetFor(widget.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(existingBudget == null ? 'Set $_title' : 'Edit $_title'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(_title, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 8),

            Text(
              widget.categoryId == null
                  ? 'Set the maximum amount you want to spend this month.'
                  : 'Set the maximum amount you want to spend in this category this month.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Budget amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                hintText: '5000.00',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return 'Please enter a budget amount.';
                }

                final amount = double.tryParse(text);

                if (amount == null) {
                  return 'Enter a valid amount.';
                }

                if (!amount.isFinite) {
                  return 'Enter a valid amount.';
                }

                if (amount <= 0) {
                  return 'Budget must be greater than zero.';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            if (existingBudget != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Current budget'),
                  subtitle: Text(formatMinor(existingBudget)),
                ),
              ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Budget'),
            ),

            if (existingBudget != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Budget'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
