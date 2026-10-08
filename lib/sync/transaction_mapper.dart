import '../data/local/database.dart';

/// The fields that can be edited by the user. The conflict resolver compares
/// exactly these, one by one (field-level merge).
const transactionFields = [
  'amountMinor',
  'type',
  'categoryId',
  'accountId',
  'note',
  'occurredAt',
  'deletedAt',
];

/// Row -> plain map. Dates become epoch milliseconds (UTC), enums become text,
/// so the map is safe to store as JSON and to send to Firestore.
Map<String, dynamic> transactionToMap(TransactionRow r) => {
  'id': r.id,
  'userId': r.userId,
  'amountMinor': r.amountMinor,
  'type': r.type.name,
  'categoryId': r.categoryId,
  'accountId': r.accountId,
  'note': r.note,
  'occurredAt': r.occurredAt.toUtc().millisecondsSinceEpoch,
  'createdAt': r.createdAt.toUtc().millisecondsSinceEpoch,
  'updatedAt': r.updatedAt.toUtc().millisecondsSinceEpoch,
  'deletedAt': r.deletedAt?.toUtc().millisecondsSinceEpoch,
};