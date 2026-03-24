import 'package:flutter/material.dart';
import 'package:jsba_app/app/service/auth_service.dart';
import 'package:jsba_app/app/service/database_service.dart';
import 'package:jsba_app/app/model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isCoach => _currentUser?.role == 'Coach';
  bool get isViewer => _currentUser?.role == 'Viewer';

  dynamic getCurrentUser() {
    return _authService.currentUser;
  }

  Future<void> loadUser(String uid) async {
    _currentUser = await _databaseService.getUser(uid);
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _databaseService.getUser(user.uid);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(email, password);
      _currentUser = await _databaseService.ensureUserDocumentExists(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.createUserWithEmailAndPassword(email, password);
      await _authService.updateDisplayName(name);
      await _databaseService.createUserForRegistration(
        uid: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        status: 'pending',
      );
      _currentUser = await _databaseService.getUser(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
