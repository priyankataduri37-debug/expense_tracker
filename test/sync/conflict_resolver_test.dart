import 'package:expense_tracker/sync/conflict_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> tx({
  int amount = 2000,
  String note = 'Lunch',
  int? deletedAt,
  int updatedAt = 1000,
}) => {
  'id': 't1',
  'userId': 'u1',
  'amountMinor': amount,
  'type': 'expense',
  'categoryId': 'exp_food',
  'accountId': 'acc_cash',
  'note': note,
  'occurredAt': 5000,
  'createdAt': 100,
  'updatedAt': updatedAt,
  'deletedAt': deletedAt,
};

void main() {
  test('different fields changed on each device: both changes survive', () {
    final base = tx();
    final local = tx(note: 'Dinner', updatedAt: 2000);
    final remote = tx(amount: 3000, updatedAt: 3000);

    final r = mergeTransaction(base: base, local: local, remote: remote);

    expect(r.merged['note'], 'Dinner');
    expect(r.merged['amountMinor'], 3000);
    expect(r.conflictedFields, isEmpty);
    expect(r.differsFromLocal, isTrue);
    expect(r.differsFromRemote, isTrue);
  });

  test('same field changed on both: newer updatedAt wins (remote newer)', () {
    final r = mergeTransaction(
      base: tx(),
      local: tx(amount: 2500, updatedAt: 2000),
      remote: tx(amount: 3000, updatedAt: 3000),
    );
    expect(r.merged['amountMinor'], 3000);
    expect(r.conflictedFields, ['amountMinor']);
    expect(r.differsFromRemote, isFalse);
  });

  test('same field changed on both: newer updatedAt wins (local newer)', () {
    final r = mergeTransaction(
      base: tx(),
      local: tx(amount: 2500, updatedAt: 4000),
      remote: tx(amount: 3000, updatedAt: 3000),
    );
    expect(r.merged['amountMinor'], 2500);
    expect(r.differsFromRemote, isTrue);
  });

  test('only the cloud changed: take the cloud version, nothing to push', () {
    final r = mergeTransaction(
      base: tx(),
      local: tx(),
      remote: tx(note: 'From other phone', updatedAt: 2000),
    );
    expect(r.merged['note'], 'From other phone');
    expect(r.differsFromLocal, isTrue);
    expect(r.differsFromRemote, isFalse);
  });

  test('nothing changed: nothing to do', () {
    final r = mergeTransaction(base: tx(), local: tx(), remote: tx());
    expect(r.differsFromLocal, isFalse);
    expect(r.differsFromRemote, isFalse);
  });

  test('delete on one device and a note edit on the other: both apply', () {
    final r = mergeTransaction(
      base: tx(),
      local: tx(deletedAt: 4000, updatedAt: 4000),
      remote: tx(note: 'Edited', updatedAt: 3000),
    );
    expect(r.merged['deletedAt'], 4000);
    expect(r.merged['note'], 'Edited');
  });

  test('exact tie gives the same winner from both devices', () {
    final a = tx(amount: 2500, updatedAt: 2000);
    final b = tx(amount: 3000, updatedAt: 2000);

    final onA = mergeTransaction(base: tx(), local: a, remote: b);
    final onB = mergeTransaction(base: tx(), local: b, remote: a);

    expect(onA.merged['amountMinor'], onB.merged['amountMinor']);
  });

  test('no base: differing fields are treated as conflicts', () {
    final r = mergeTransaction(
      base: null,
      local: tx(amount: 2500, updatedAt: 2000),
      remote: tx(amount: 3000, updatedAt: 3000),
    );
    expect(r.merged['amountMinor'], 3000);
    expect(r.conflictedFields, ['amountMinor']);
  });
}
