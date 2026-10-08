import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/remote/transaction_remote_source.dart';
import '../data/repositories/sync_meta_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'conflict_resolver.dart';
import 'transaction_mapper.dart';

class SyncService {
  SyncService(
    this._repo,
    this._remote,
    this._meta, {
    required String Function() userId,
  }) : _userId = userId;

  final TransactionRepository _repo;
  final TransactionRemoteSource _remote;
  final SyncMetaRepository _meta;
  final String Function() _userId;

  bool _pushing = false;
  bool _pulling = false;

  /// Re-fetch the last 2 seconds again, in case a change was saved by the
  /// server a moment after our last pull. Merging the same change twice is harmless.
  static const _overlapMicros = 2000000;

  /// Pull first (so conflicts are merged), then push. Never throws.
  Future<bool> sync() async {
    final pulled = await pull();
    final pushed = await push();
    return pulled && pushed;
  }

  // ---------------------------------------------------------------- PULL

  Future<bool> pull() async {
    final uid = _userId();
    if (uid == 'local' || _pulling) return true;
    _pulling = true;

    try {
      final last = await _meta.getLastSyncMicros(uid);
      final since = last == null ? null : last - _overlapMicros;

      final docs = await _remote
          .fetchChangedSince(uid, since)
          .timeout(const Duration(seconds: 20));

      var newest = last ?? 0;
      for (final d in docs) {
        await _mergeOne(d.data);
        if (d.serverMicros > newest) newest = d.serverMicros;
      }
      // Move the bookmark only after every document was merged.
      if (docs.isNotEmpty) await _meta.setLastSyncMicros(uid, newest);
      return true;
    } on TimeoutException {
      debugPrint('SYNC: pull timeout');
      return false;
    } on FirebaseException catch (e) {
      debugPrint('SYNC: pull firebase error ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('SYNC: pull error $e');
      return false;
    } finally {
      _pulling = false;
    }
  }

  Future<void> _mergeOne(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final baseOfCloud = jsonEncode(remote);
    final local = await _repo.findById(id);

    // New to this phone: just save it.
    if (local == null) {
      await _repo.insertFromCloud(remote, baseJson: baseOfCloud);
      return;
    }

    final base = local.baseJson == null
        ? null
        : jsonDecode(local.baseJson!) as Map<String, dynamic>;

    final result = mergeTransaction(
      base: base,
      local: transactionToMap(local),
      remote: remote,
    );

    await _repo.applyMerged(
      result.merged,
      expectedLocalUpdatedAt: local.updatedAt,
      needsPush: result.differsFromRemote,
      baseJson: baseOfCloud,
    );
  }

  // ---------------------------------------------------------------- PUSH

  Future<bool> push() async {
    final uid = _userId();
    if (uid == 'local' || _pushing) return true;
    _pushing = true;
    var allOk = true;

    try {
      final rows = await _repo.pendingRows();

      for (final row in rows) {
        // Deleted before it ever reached the cloud: nothing to tell the cloud.
        if (row.deletedAt != null && row.baseJson == null) {
          await _repo.purge(row.id);
          continue;
        }

        try {
          final map = transactionToMap(row);
          await _remote.upsert(uid, map).timeout(const Duration(seconds: 15));
          await _repo.markSynced(
            row.id,
            expectedUpdatedAt: row.updatedAt,
            baseJson: jsonEncode(map),
          );
        } on TimeoutException {
          debugPrint('SYNC: push timeout on ${row.id}');
          await _repo.markFailed(row.id);
          allOk = false;
          break;
        } on FirebaseException catch (e) {
          debugPrint('SYNC: push firebase error ${e.code}: ${e.message}');
          await _repo.markFailed(row.id);
          allOk = false;
          if (e.code == 'unavailable') break;
        } catch (e) {
          debugPrint('SYNC: push error $e');
          await _repo.markFailed(row.id);
          allOk = false;
        }
      }
    } finally {
      _pushing = false;
    }
    return allOk;
  }
}
