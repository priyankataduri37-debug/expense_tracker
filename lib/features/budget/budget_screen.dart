import 'package:expense_tracker/core/utils/budget_calculator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/money.dart';
import '../../data/local/enums.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import 'set_budget_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final categories = context.watch<CategoryProvider>();

    final expenseCategories = categories.forType(TxType.expense);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: budget.isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _OverallBudgetCard(
            budgetProvider: budget,
          ),

          const SizedBox(height: 24),

          Text(
            'Category budgets',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          if (expenseCategories.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No expense categories available.',
                ),
              ),
            )
          else
            for (final category in expenseCategories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryBudgetCard(
                  categoryId: category.id,
                  categoryName: category.name,
                  budgetProvider: budget,
                ),
              ),
        ],
      ),
    );
  }
}

class _OverallBudgetCard extends StatelessWidget {
  const _OverallBudgetCard({
    required this.budgetProvider,
  });

  final BudgetProvider budgetProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = budgetProvider.overall;
    final budgetAmount = budgetProvider.budgetFor(null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: budgetAmount == null
                      ? 'Set budget'
                      : 'Edit budget',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SetBudgetScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    budgetAmount == null
                        ? Icons.add
                        : Icons.edit_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (status == null)
              const Text(
                'No monthly budget set.',
              )
            else ...[
              Text(
                '${formatMinor(status.spentMinor)} / '
                    '${formatMinor(status.budgetMinor)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              LinearProgressIndicator(
                value: status.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),

              const SizedBox(height: 12),

              Text(
                status.spentMinor > status.budgetMinor
                    ? 'Over by ${formatMinor(status.overByMinor)}'
                    : '${formatMinor(status.remainingMinor)} remaining',
              ),

              finalMessage(context, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget finalMessage(
      BuildContext context,
      BudgetStatus status,
      ) {
    final message = status.message(
      monthName: _currentMonthName(),
      formatMoney: formatMinor,
    );

    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
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

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.categoryId,
    required this.categoryName,
    required this.budgetProvider,
  });

  final String categoryId;
  final String categoryName;
  final BudgetProvider budgetProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = budgetProvider.byCategory[categoryId];
    final budgetAmount = budgetProvider.budgetFor(categoryId);

    final statusColor = status == null
        ? Theme.of(context).colorScheme.outline
        : _statusColor(context, status.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (status == null)
                    const Text(
                      'No budget set',
                    )
                  else ...[
                    Text(
                      '${formatMinor(status.spentMinor)} / '
                          '${formatMinor(status.budgetMinor)}',
                    ),

                    const SizedBox(height: 8),

                    LinearProgressIndicator(
                      value: status.progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            status.spentMinor > status.budgetMinor
                                ? 'Over by ${formatMinor(status.overByMinor)}'
                                : '${formatMinor(status.remainingMinor)} remaining',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusLabel(status.level),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            IconButton(
              tooltip: budgetAmount == null
                  ? 'Set budget'
                  : 'Edit budget',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SetBudgetScreen(
                      categoryId: categoryId,
                    ),
                  ),
                );
              },
              icon: Icon(
                budgetAmount == null
                    ? Icons.add
                    : Icons.edit_outlined,
              ),
            ),
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

}