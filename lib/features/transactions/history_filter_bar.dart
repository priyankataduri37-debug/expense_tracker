import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_filter_sheet.dart';

import '../../data/local/enums.dart';
import '../../providers/history_provider.dart';

class HistoryFilterBar extends StatefulWidget {
  const HistoryFilterBar({super.key});

  @override
  State<HistoryFilterBar> createState() => _HistoryFilterBarState();
}

class _HistoryFilterBarState extends State<HistoryFilterBar> {
  final _searchCtrl = TextEditingController();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    // Keep the text if the screen is rebuilt while a search is active.
    _searchCtrl.text = context.read<HistoryProvider>().filter.search ?? '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  Future<void> _pickRange(HistoryProvider h) async {
    final f = h.filter;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: (f.from != null && f.to != null)
          ? DateTimeRange(
        start: f.from!,
        end: f.to!.subtract(const Duration(days: 1)),
      )
          : null,
    );
    if (picked == null) return;

    // The filter's end date is exclusive, so add one day to the picked end.
    h.setFilter(f.copyWith(
      from: DateTime(picked.start.year, picked.start.month, picked.start.day),
      to: DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HistoryProvider>();
    final f = h.filter;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final isThisMonth = f.from == monthStart && f.to == nextMonth;
    final hasRange = f.from != null && f.to != null;

    final moreCount = (f.categoryId != null ? 1 : 0) +
        (f.accountId != null ? 1 : 0) +
        ((f.minMinor != null || f.maxMinor != null) ? 1 : 0);

    final rangeLabel = hasRange
        ? '${_fmt(f.from!)} - ${_fmt(f.to!.subtract(const Duration(days: 1)))}'
        : 'Date range';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search note, category or amount',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchCtrl.clear();
                  h.setSearch('');
                  setState(() {});
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) {
              setState(() {}); // refreshes the clear (x) button
              h.setSearch(v);
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: f.type == null,
                onSelected: (_) => h.setFilter(f.copyWith(type: null)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Income'),
                selected: f.type == TxType.income,
                onSelected: (_) =>
                    h.setFilter(f.copyWith(type: TxType.income)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Expense'),
                selected: f.type == TxType.expense,
                onSelected: (_) =>
                    h.setFilter(f.copyWith(type: TxType.expense)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('This month'),
                selected: isThisMonth,
                onSelected: (on) => h.setFilter(
                  on
                      ? f.copyWith(from: monthStart, to: nextMonth)
                      : f.copyWith(from: null, to: null),
                ),
              ),
              const SizedBox(width: 8),
              InputChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(rangeLabel),
                selected: hasRange && !isThisMonth,
                onPressed: () => _pickRange(h),
                onDeleted: hasRange
                    ? () => h.setFilter(f.copyWith(from: null, to: null))
                    : null,
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: Text(moreCount == 0 ? 'More' : 'More ($moreCount)'),
                selected: moreCount > 0,
                onSelected: (_) => showHistoryFilterSheet(context),
              ),
              if (f.isActive) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    h.clearFilters();
                    setState(() {});
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}