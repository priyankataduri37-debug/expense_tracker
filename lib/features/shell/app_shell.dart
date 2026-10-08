import 'package:expense_tracker/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transactions_screen.dart';

/// Bottom navigation: Dashboard | Analytics | (+) | Transactions | Settings
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    _ComingSoon(title: 'Analytics'),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  Widget _navItem(int index, IconData icon, IconData selectedIcon, String label) {
    final selected = _index == index;
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _index = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _navItem(1, Icons.pie_chart_outline, Icons.pie_chart, 'Analytics'),
            const SizedBox(width: 56), // room for the + button
            _navItem(2, Icons.receipt_long_outlined, Icons.receipt_long, 'History'),
            _navItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Coming soon')),
  );
}