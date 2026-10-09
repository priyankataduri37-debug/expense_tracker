import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'analytics_provider.dart';
import '../../core/utils/money.dart';
import '../../providers/settings_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().load();
      }
    });
  }

  String _money(int minor) => formatMinor(
    minor,
    symbol: context.watch<SettingsProvider>().currencySymbol,
  );

  String _periodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return '7 days';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.threeMonths:
        return '3 months';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: () {
              context.read<AnalyticsProvider>().load();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          final summary = provider.summary;

          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Understand your money',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review your income, expenses and spending habits.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Reporting period selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AnalyticsPeriod.values.map((period) {
                    return ChoiceChip(
                      label: Text(_periodLabel(period)),
                      selected: provider.period == period,
                      onSelected: (_) => provider.setPeriod(period),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                if (provider.loading && summary == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null && summary == null)
                  _MessageCard(
                    icon: Icons.error_outline,
                    message: 'Could not load analytics.',
                    detail: provider.error,
                    actionLabel: 'Try again',
                    onAction: provider.load,
                  )
                else if (summary == null)
                  const _MessageCard(
                    icon: Icons.analytics_outlined,
                    message: 'No analytics available yet.',
                    detail: 'Add a transaction to get started.',
                  )
                else ...[
                  // Income and expense summary
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: _money(summary.incomeMinor),
                          icon: Icons.arrow_downward_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expenses',
                          amount: _money(summary.expenseMinor),
                          icon: Icons.arrow_upward_rounded,
                          color: colors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Net savings and savings rate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.savings_outlined,
                              color: colors.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Net savings',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _money(summary.netSavings),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Savings rate',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(summary.savingsRate * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transaction count
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Transactions'),
                      subtitle: Text(
                        'During ${_periodLabel(provider.period).toLowerCase()}',
                      ),
                      trailing: Text(
                        '${summary.transactionCount}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Spending by category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (summary.categoryExpenses.isEmpty)
                    const _MessageCard(
                      icon: Icons.pie_chart_outline,
                      message: 'No expenses in this period',
                      detail: 'Your category breakdown will appear here.',
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 42,
                                  sections: _buildSections(
                                    summary.categoryExpenses,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._buildLegend(
                              context,
                              summary.categoryExpenses,
                              provider,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (provider.loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, int> expenses) {
    final entries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const chartColors = <Color>[
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    return List.generate(entries.length, (index) {
      return PieChartSectionData(
        value: entries[index].value.toDouble(),
        color: chartColors[index % chartColors.length],
        radius: 55,
        showTitle: false,
      );
    });
  }

  List<Widget> _buildLegend(
    BuildContext context,
    Map<String, int> expenses,
    AnalyticsProvider provider,
  ) {
    final entries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const chartColors = <Color>[
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];

    final total = expenses.values.fold<int>(0, (sum, value) => sum + value);

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percentage = total == 0 ? 0.0 : entry.value / total * 100;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: chartColors[index % chartColors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                provider.categoryName(entry.key),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 12),
            Text(
              _money(entry.value),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
