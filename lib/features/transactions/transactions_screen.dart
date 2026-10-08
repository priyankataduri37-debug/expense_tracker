import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/history_provider.dart';
import 'add_transaction_sheet.dart';
import 'history_filter_bar.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HistoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (h.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (h.error != null) {
      body = Center(child: Text('Error: ${h.error}'));
    } else if (h.items.isEmpty) {
      body = _EmptyState(filtersActive: h.filter.isActive);
    } else {
      final extra = h.isLoadingMore ? 1 : 0;

      body = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Within 300 px of the bottom -> load the next page.
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
            context.read<HistoryProvider>().loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: h.items.length + extra,
          itemBuilder: (context, i) {
            if (i >= h.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final t = h.items[i];
            return Dismissible(
              key: ValueKey(t.id),
              // Swipe right -> Edit. Swipe left -> Delete.
              background: Container(
                color: scheme.primaryContainer,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Icon(Icons.edit, color: scheme.onPrimaryContainer),
              ),
              secondaryBackground: Container(
                color: scheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Icon(Icons.delete, color: scheme.onErrorContainer),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await showTransactionSheet(context, existing: t);
                  return false; // keep the row; the DB stream refreshes it
                }
                return true;
              },
              onDismissed: (_) {
                h.delete(t.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text('Transaction deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => h.restore(t.id),
                      ),
                    ),
                  );
              },
              child: TransactionTile(tx: t),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          const HistoryFilterBar(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtersActive});

  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtersActive ? Icons.search_off : Icons.receipt_long_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              filtersActive
                  ? 'No transactions match your filters'
                  : 'No transactions yet. Tap + to add one.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (filtersActive) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.read<HistoryProvider>().clearFilters(),
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
