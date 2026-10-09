import 'package:flutter/material.dart';

import '../../core/utils/insights_calculator.dart';
import '../../data/local/enums.dart';
import '../../data/repositories/analytics_repository.dart';

enum AnalyticsPeriod { week, month, threeMonths, year }

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._repository);

  final AnalyticsRepository _repository;

  AnalyticsPeriod _period = AnalyticsPeriod.month;

  AnalyticsSummary? _summary;
  Map<String, String> _categoryNames = {};
  List<SpendEntry> _spendEntries = [];

  bool _loading = false;
  String? _error;

  AnalyticsPeriod get period => _period;
  AnalyticsSummary? get summary => _summary;
  Map<String, String> get categoryNames => _categoryNames;
  List<SpendEntry> get spendEntries => _spendEntries;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _getDateRange();

      _summary = await _repository.getSummary(
        start: range.start,
        end: range.end,
      );

      _categoryNames = await _repository.getCategoryNames();
      _spendEntries = await _loadSpendEntries();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }


  Future<List<SpendEntry>> _loadSpendEntries() async {
    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month - 1);
    final twoWeeksAgo = DateTime(now.year, now.month, now.day - 13);
    final start =
    lastMonthStart.isBefore(twoWeeksAgo) ? lastMonthStart : twoWeeksAgo;

    final rows = await _repository.getTransactions(
      start: start,
      end: DateTime(now.year, now.month, now.day + 1),
    );

    return [
      for (final t in rows)
        if (t.type == TxType.expense)
          SpendEntry(
            categoryId: t.categoryId,
            amountMinor: t.amountMinor,
            occurredAt: t.occurredAt,
          ),
    ];
  }

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (_period == period) return;

    _period = period;
    await load();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();

    switch (_period) {
      case AnalyticsPeriod.week:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));

        return DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, now.day + 1),
        );

      case AnalyticsPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1),
        );

      case AnalyticsPeriod.threeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2),
          end: DateTime(now.year, now.month + 1),
        );

      case AnalyticsPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year),
          end: DateTime(now.year + 1),
        );
    }
  }

  String categoryName(String categoryId) {
    return _categoryNames[categoryId] ?? 'Other';
  }
}