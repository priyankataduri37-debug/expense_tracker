import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/remote/auth_service.dart';

enum AuthStatus { signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _user = _service.currentUser;
    _sub = _service.authChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthService _service;
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status =>
      _user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
  bool get isBusy => _busy;
  String? get error => _error;
  String? get email => _user?.email;

  String get userId => _user?.uid ?? 'local';

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email, password));

  Future<bool> signUp(String email, String password) =>
      _run(() => _service.signUp(email, password));

  Future<void> signOut() => _service.signOut();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = AuthService.messageFor(e);
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
