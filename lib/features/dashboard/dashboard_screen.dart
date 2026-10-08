import 'package:expense_tracker/features/budget/set_budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../budget/widgets/budget_card.dart';
import '../../core/utils/money.dart';
import '../../providers/dashboard_provider.dart';
import '../transactions/transaction_tile.dart';
import '../shared/sync_status_chip.dart';
import '../budget/budget_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DashboardProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: d.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SyncStatusChip(),
                ),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current balance',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatMinor(d.balanceMinor),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Income',
                        amount: formatMinor(d.incomeMinor),
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Expenses',
                        amount: formatMinor(d.expenseMinor),
                        icon: Icons.arrow_upward,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                BudgetCard(
                  onSetBudget: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    );
                  },
                ),

                const SizedBox(height: 24),
                Text('Recent transactions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (d.recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No transactions yet. Tap + to add one.'),
                    ),
                  )
                else
                  for (final t in d.recent) TransactionTile(tx: t),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label, style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
