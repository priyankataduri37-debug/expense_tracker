import '../data/local/database.dart';


const transactionFields = [
  'amountMinor',
  'type',
  'categoryId',
  'accountId',
  'note',
  'occurredAt',
  'deletedAt',
];


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
