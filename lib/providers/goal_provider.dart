import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/database.dart';
import '../data/repositories/goal_repository.dart';

class GoalProvider extends ChangeNotifier {
  GoalProvider(this._repository) {
    _subscription = _repository.watchGoals().listen(
      (goals) {
        _goals = goals;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  final GoalRepository _repository;
  StreamSubscription<List<GoalRow>>? _subscription;

  List<GoalRow> _goals = [];
  String? _error;

  List<GoalRow> get goals => List.unmodifiable(_goals);
  String? get error => _error;

  Future<void> createGoal({
    required String name,
    required int targetMinor,
    DateTime? targetDate,
    String iconKey = 'savings',
  }) {
    return _repository.createGoal(
      name: name,
      targetMinor: targetMinor,
      targetDate: targetDate,
      iconKey: iconKey,
    );
  }

  Future<void> updateSavedAmount({
    required String goalId,
    required int currentMinor,
  }) {
    return _repository.updateSavedAmount(
      goalId: goalId,
      currentMinor: currentMinor,
    );
  }

  Future<void> deleteGoal(String goalId) {
    return _repository.deleteGoal(goalId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
