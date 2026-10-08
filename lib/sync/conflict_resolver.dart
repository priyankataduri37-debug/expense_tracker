import 'transaction_mapper.dart';

class MergeResult {
  const MergeResult({
    required this.merged,
    required this.conflictedFields,
    required this.differsFromLocal,
    required this.differsFromRemote,
  });

  final Map<String, dynamic> merged;

  /// Fields that BOTH sides changed to different values (settled by last-write-wins).
  final List<String> conflictedFields;

  /// True -> the merged row must be saved into the local database.
  final bool differsFromLocal;

  /// True -> the merged row must be pushed back to the cloud.
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

    // No base means no common ancestor, so we treat both sides as changed.
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
  // Exact tie: both devices must pick the SAME winner or they would swap
  // values forever. Comparing the values themselves is the same on both sides.
  return '$l'.compareTo('$r') >= 0 ? l : r;
}
