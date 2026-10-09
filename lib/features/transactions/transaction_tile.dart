import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/icon_map.dart';
import '../../core/utils/money_context.dart';
import '../../data/local/database.dart';
import '../../data/local/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx});

  final TransactionRow tx;

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CategoryProvider>().byId(tx.categoryId);
    final account = context.watch<AccountProvider>().byId(tx.accountId);
    final scheme = Theme.of(context).colorScheme;
    final isIncome = tx.type == TxType.income;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(tx.occurredAt);
    final details = [
      if (tx.note.isNotEmpty) tx.note,
      if (account != null) account.name,
      date,
    ].join(' • ');

    return ListTile(
      leading: CircleAvatar(child: Icon(iconFor(cat?.iconKey ?? 'category'))),
      title: Text(cat?.name ?? 'Unknown category'),
      subtitle: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? '+' : '-'}${context.money(tx.amountMinor)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green : scheme.error,
            ),
          ),
          Text(
            tx.syncStatus.name,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
