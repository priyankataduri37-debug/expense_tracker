import '../local/enums.dart';

const _unset = Object();

/// Every field is optional, and they combine (Expense + Food + This Month).
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.categoryId,
    this.accountId,
    this.from,
    this.to,
    this.minMinor,
    this.maxMinor,
    this.search,
  });

  final TxType? type;
  final String? categoryId;
  final String? accountId;

  /// Start is inclusive, end is exclusive. For "Oct 1 to Oct 31" pass Nov 1 as [to].
  final DateTime? from;
  final DateTime? to;
  final int? minMinor;
  final int? maxMinor;
  final String? search;

  static const none = TransactionFilter();

  bool get isActive =>
      type != null ||
          categoryId != null ||
          accountId != null ||
          from != null ||
          to != null ||
          minMinor != null ||
          maxMinor != null ||
          (search?.trim().isNotEmpty ?? false);

  /// Leave a field out to keep it. Pass null to clear it.
  TransactionFilter copyWith({
    Object? type = _unset,
    Object? categoryId = _unset,
    Object? accountId = _unset,
    Object? from = _unset,
    Object? to = _unset,
    Object? minMinor = _unset,
    Object? maxMinor = _unset,
    Object? search = _unset,
  }) {
    return TransactionFilter(
      type: identical(type, _unset) ? this.type : type as TxType?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      accountId: identical(accountId, _unset)
          ? this.accountId
          : accountId as String?,
      from: identical(from, _unset) ? this.from : from as DateTime?,
      to: identical(to, _unset) ? this.to : to as DateTime?,
      minMinor: identical(minMinor, _unset) ? this.minMinor : minMinor as int?,
      maxMinor: identical(maxMinor, _unset) ? this.maxMinor : maxMinor as int?,
      search: identical(search, _unset) ? this.search : search as String?,
    );
  }
}