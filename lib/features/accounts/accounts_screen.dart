import 'package:expense_tracker/data/local/enums.dart';
import 'package:expense_tracker/data/repositories/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<List<AccountBalance>> _accountsFuture;

  String get _userId => context.read<AuthProvider>().userId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final userId = _userId;

    _accountsFuture = context.read<AccountRepository>().getAccountsWithBalances(
      userId: userId,
    );
  }

  String _money(int minor, String currency) {
    return '$currency ${(minor.abs() / 100).toStringAsFixed(2)}'.replaceFirst(
      ' ',
      minor < 0 ? ' -' : ' ',
    );
  }

  String _typeName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank account';
      case AccountType.creditCard:
        return 'Credit card';
      case AccountType.wallet:
        return 'Digital wallet';
      case AccountType.savings:
        return 'Savings';
    }
  }

  IconData _typeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.wallet:
        return Icons.account_balance_wallet_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
    }
  }

  Future<void> _addAccount() async {
    final userId = _userId;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.00');

    AccountType selectedType = AccountType.bank;
    String currency = 'INR';
    final currencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY'];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add account'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Account name',
                      hintText: 'e.g. Main bank account',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an account name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AccountType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_typeName(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: currencies
                        .map(
                          (code) =>
                              DropdownMenuItem(value: code, child: Text(code)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => currency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Opening balance',
                      hintText: '0.00',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || !amount.isFinite) {
                        return 'Enter a valid amount';
                      }
                      if (amount < 0) return 'Use a positive amount';
                      return null;
                    },
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
              child: const Text('Save account'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) {
      nameController.dispose();
      balanceController.dispose();
      return;
    }

    try {
      final amount = double.parse(balanceController.text.trim());
      await context.read<AccountRepository>().createAccount(
        userId: userId,
        name: nameController.text,
        type: selectedType,
        currencyCode: currency,
        openingBalanceMinor: (amount * 100).round(),
      );

      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create account: $error')),
      );
    } finally {
      nameController.dispose();
      balanceController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            onPressed: () => setState(_reload),
            tooltip: 'Refresh balances',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: FutureBuilder<List<AccountBalance>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load accounts: ${snapshot.error}'),
              ),
            );
          }

          final accounts = snapshot.data ?? [];
          final totals = <String, int>{};

          for (final item in accounts) {
            totals.update(
              item.account.currencyCode,
              (value) => value + item.balanceMinor,
              ifAbsent: () => item.balanceMinor,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _accountsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Combined balances',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (totals.isEmpty)
                          const Text('Add an account to see your balance.')
                        else
                          for (final entry in totals.entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text(
                                    _money(entry.value, entry.key),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your accounts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (accounts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No accounts yet.\nTap “Add account” to get started.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  for (final item in accounts)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_typeIcon(item.account.type)),
                        ),
                        title: Text(item.account.name),
                        subtitle: Text(
                          '${_typeName(item.account.type)} • '
                          '${item.account.currencyCode}',
                        ),
                        trailing: Text(
                          _money(item.balanceMinor, item.account.currencyCode),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
