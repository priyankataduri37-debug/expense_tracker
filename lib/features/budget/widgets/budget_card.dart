import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/budget_provider.dart';
import '../../../core/utils/budget_calculator.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.onSetBudget,
    this.monthName,
    this.formatMoney,
  });

  final VoidCallback onSetBudget;

  /// Optional so the dashboard can later provide its own month formatter.
  final String? monthName;

  /// Optional money formatter.
  ///
  /// If omitted, the widget uses a simple INR formatter.
  final String Function(int minor)? formatMoney;

  String _defaultFormatMoney(int minor) {
    return '₹${(minor / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load budget: ${provider.error}',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final budget = provider.overall;

    // No overall budget configured.
    if (budget == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Monthly Budget',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'No overall monthly budget has been set.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSetBudget,
                icon: const Icon(Icons.add),
                label: const Text('Set Budget'),
              ),
            ],
          ),
        ),
      );
    }

    final status = provider.overall!;

    final money = formatMoney ?? _defaultFormatMoney;

    final month = monthName ?? _currentMonthName();

    final warning = status.message(
      monthName: month,
      formatMoney: money,
    );

    final statusColor = _statusColor(context, status.level);

    final isOver = status.overByMinor > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$month Budget',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit budget',
                  onPressed: onSetBudget,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Spent / budget
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    money(status.spentMinor),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(
                  'of ${money(status.budgetMinor)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: status.progress,
                minHeight: 10,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.15),
              ),
            ),

            const SizedBox(height: 8),

            // Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${status.wholePercent}% used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _statusLabel(status.level),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Remaining / exceeded
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isOver
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 20,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOver
                          ? '${money(status.overByMinor)} over budget'
                          : '${money(status.remainingMinor)} remaining',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Warning
            if (warning != null) ...[
              const SizedBox(height: 12),
              Text(
                warning,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, BudgetLevel level) {
    final scheme = Theme.of(context).colorScheme;

    switch (level) {
      case BudgetLevel.ok:
        return scheme.primary;

      case BudgetLevel.reached50:
        return scheme.primary;

      case BudgetLevel.reached75:
        return Colors.orange;

      case BudgetLevel.reached90:
        return Colors.deepOrange;

      case BudgetLevel.reached100:
        return scheme.error;

      case BudgetLevel.over:
        return scheme.error;
    }
  }

  String _statusLabel(BudgetLevel level) {
    switch (level) {
      case BudgetLevel.ok:
        return 'On track';

      case BudgetLevel.reached50:
        return 'Half used';

      case BudgetLevel.reached75:
        return 'Getting close';

      case BudgetLevel.reached90:
        return 'Almost reached';

      case BudgetLevel.reached100:
        return 'Budget reached';

      case BudgetLevel.over:
        return 'Over budget';
    }
  }

  String _currentMonthName() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[DateTime.now().month - 1];
  }
}