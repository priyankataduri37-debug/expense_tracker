import 'transaction_mapper.dart';

class MergeResult {
  const MergeResult({
    required this.merged,
    required this.conflictedFields,
    required this.differsFromLocal,
    required this.differsFromRemote,
  });

  final Map<String, dynamic> merged;

  final List<String> conflictedFields;

  final bool differsFromLocal;

  final bool differsFromRemote;
}

MergeResult mergeTransaction({
  required Map<String, dynamic>? base,
  required Map<String, dynamic> local,
  required Map<String, dynamic> remote,
}) {
  final merged = Map<String, dynamic>.from(local);
  final conflicts = <String>[];

  for (final f in transactionFields) {
    final l = local[f];
    final r = remote[f];
    if (l == r) continue;

    final localChanged = base == null ? true : l != base[f];
    final remoteChanged = base == null ? true : r != base[f];

    if (localChanged && !remoteChanged) {
      merged[f] = l;
    } else if (!localChanged && remoteChanged) {
      merged[f] = r;
    } else {
      conflicts.add(f);
      merged[f] = _lastWriteWins(l, r, local, remote);
    }
  }

  final lu = local['updatedAt'] as int;
  final ru = remote['updatedAt'] as int;
  merged['updatedAt'] = lu > ru ? lu : ru;

  return MergeResult(
    merged: merged,
    conflictedFields: conflicts,
    differsFromLocal: transactionFields.any((f) => merged[f] != local[f]),
    differsFromRemote: transactionFields.any((f) => merged[f] != remote[f]),
  );
}

dynamic _lastWriteWins(
  dynamic l,
  dynamic r,
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final lu = local['updatedAt'] as int;
  final ru = remote['updatedAt'] as int;
  if (lu > ru) return l;
  if (ru > lu) return r;
  return '$l'.compareTo('$r') >= 0 ? l : r;
}
