import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/transaction_repository.dart';
import '../sync/sync_service.dart';

enum SyncState { idle, syncing, failed }

class SyncProvider extends ChangeNotifier {
  SyncProvider(
    this._sync,
    this._repo, {
    required this.enabled,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    if (enabled) _start();
  }

  final SyncService _sync;
  final TransactionRepository _repo;
  final Connectivity _connectivity;

  /// False before login: there is no account to sync with.
  final bool enabled;

  SyncState _state = SyncState.idle;
  bool _online = true;
  int _pending = 0;
  DateTime? _lastSyncAt;
  bool _runAgain = false;
  bool _disposed = false;

  StreamSubscription<int>? _pendingSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _debounce;
  Timer? _retry;
  Timer? _periodic;

  SyncState get state => _state;
  bool get isOnline => _online;
  int get pendingCount => _pending;
  DateTime? get lastSyncAt => _lastSyncAt;

  bool _isOnline(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  Future<void> _start() async {
    // A new local change (the pending count went up) -> sync soon.
    _pendingSub = _repo.watchPendingCount().listen((n) {
      final increased = n > _pending;
      _pending = n;
      notifyListeners();
      if (increased) _scheduleSync();
    });

    final first = await _connectivity.checkConnectivity();
    if (_disposed) return;
    _online = _isOnline(first);
    notifyListeners();

    // Internet came back -> sync.
    _connSub = _connectivity.onConnectivityChanged.listen((r) {
      final wasOnline = _online;
      _online = _isOnline(r);
      notifyListeners();
      if (_online && !wasOnline) syncNow();
    });

    _periodic = Timer.periodic(const Duration(minutes: 5), (_) => syncNow());

    syncNow(); // app start / right after login
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 30), syncNow);
  }

  Future<void> syncNow() async {
    if (!enabled || _disposed || !_online) return;
    if (_state == SyncState.syncing) {
      _runAgain = true; // something changed during this sync
      return;
    }

    _runAgain = false;
    _state = SyncState.syncing;
    notifyListeners();

    final ok = await _sync.sync();
    if (_disposed) return;

    _state = ok ? SyncState.idle : SyncState.failed;
    if (ok) _lastSyncAt = DateTime.now();
    notifyListeners();

    if (!ok) _scheduleRetry();
    if (_runAgain) syncNow();
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingSub?.cancel();
    _connSub?.cancel();
    _debounce?.cancel();
    _retry?.cancel();
    _periodic?.cancel();
    super.dispose();
  }
}
