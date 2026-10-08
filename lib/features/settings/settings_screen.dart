import 'package:expense_tracker/features/shared/sync_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import 'package:expense_tracker/services/backup_service.dart';
import '../../services/csv_export_service.dart';
import 'csv_export_filter_sheet.dart';
import '../../services/local_data_reset_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Changes that have not synced yet stay safely on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      // No navigation needed: AuthGate sees the status change and shows the login screen.
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final backup = context.read<BackupService>();

      final path = await backup.exportBackup();

      if (!context.mounted) return;

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup export cancelled.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text(
            'Restoring a backup will replace your current local '
            'transactions, accounts, budgets, goals, recurring rules, '
            'and custom categories.\n\n'
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final backup = context.read<BackupService>();

      final result = await backup.pickAndRestore();

      if (!context.mounted) return;

      if (result.wasCancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restore cancelled.')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore complete: ${result.transactions} transactions '
            'restored.',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid backup: ${e.message}')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      // First ask the user which transactions to export.
      final filter = await showCsvExportFilterSheet(context);

      if (!context.mounted) return;

      // User closed the filter sheet without exporting.
      if (filter == null) return;

      final result = await context
          .read<CsvExportService>()
          .exportTransactions(
        filter: filter,
      );

      if (!context.mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export cancelled.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transactions exported successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _resetLocalData(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.userId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset local data?'),
          content: const Text(
            'This will permanently delete your locally stored '
                'transactions, accounts, budgets, goals, recurring rules, '
                'and custom categories from this device.\n\n'
                'Your cloud data will not be deleted. '
                'Cloud data may appear again after the next sync.\n\n'
                'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await context
          .read<LocalDataResetService>()
          .resetForUser(uid);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local data reset successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset failed: $e'),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().email;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Signed in as'),
            subtitle: Text(email ?? 'Unknown'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(
              _themeName(context.watch<SettingsProvider>().themeMode),
            ),
            onTap: () => _showThemePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text(
              '${context.watch<SettingsProvider>().currency} '
              '(${context.watch<SettingsProvider>().currencySymbol})',
            ),
            onTap: () => _showCurrencyPicker(context),
          ),
          Builder(
            builder: (context) {
              final sync = context.watch<SyncProvider>();
              final t = sync.lastSyncAt;
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Cloud sync'),
                    subtitle: Text(
                      t == null
                          ? 'Not synced yet'
                          : 'Last synced ${t.day} ${months[t.month - 1]}, '
                                '${TimeOfDay.fromDateTime(t).format(context)}',
                    ),
                    onTap: () => sync.syncNow(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 56, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SyncStatusChip(),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export backup'),
            subtitle: const Text('Save your expense data as a JSON file'),
            onTap: () => _exportBackup(context),
          ),

          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore backup'),
            subtitle: const Text('Replace local data from a JSON backup'),
            onTap: () => _restoreBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export CSV'),
            subtitle: const Text(
              'Export your transaction history as a CSV file',
            ),
            onTap: () => _exportCsv(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Reset local data'),
            subtitle: const Text(
              'Delete locally stored expense data from this device',
            ),
            onTap: () => _resetLocalData(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final settings = context.read<SettingsProvider>();

    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose theme'),
          content: RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('System default'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('Light'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('Dark'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await settings.setThemeMode(selected);
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final settings = context.read<SettingsProvider>();

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose currency'),
          content: RadioGroup<String>(
            groupValue: settings.currency,
            onChanged: (value) {
              if (value != null) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'INR',
                  title: Text('Indian Rupee'),
                  subtitle: Text('₹'),
                ),
                RadioListTile<String>(
                  value: 'USD',
                  title: Text('US Dollar'),
                  subtitle: Text('\$'),
                ),
                RadioListTile<String>(
                  value: 'EUR',
                  title: Text('Euro'),
                  subtitle: Text('€'),
                ),
                RadioListTile<String>(
                  value: 'GBP',
                  title: Text('British Pound'),
                  subtitle: Text('£'),
                ),
                RadioListTile<String>(
                  value: 'JPY',
                  title: Text('Japanese Yen'),
                  subtitle: Text('¥'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await settings.setCurrency(selected);
    }
  }
}
