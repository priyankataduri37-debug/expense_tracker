import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/repositories/account_repository.dart';

class AccountProvider extends ChangeNotifier {
  AccountProvider(this._repo) {
    _sub = _repo.watchAll().listen((rows) {
      _all = rows;
      _byId = {for (final a in rows) a.id: a};
      notifyListeners();
    });
  }

  final AccountRepository _repo;
  StreamSubscription<List<AccountRow>>? _sub;

  List<AccountRow> _all = [];
  Map<String, AccountRow> _byId = {};

  List<AccountRow> get active => _all.where((a) => !a.isArchived).toList();

  AccountRow? byId(String id) => _byId[id];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}