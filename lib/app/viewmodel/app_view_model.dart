import 'package:flutter/material.dart';
import 'package:jsba_app/app/utils/shared_preference_handler.dart';

enum UserRole { coach, parent }

class AppViewModel extends ChangeNotifier {
  String _userRole = '';
  String _userName = '';
  String _userEmail = '';
  String _userId = '';

  String get userRole => _userRole;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userId => _userId;

  bool get isCoach => _userRole == 'coach';
  bool get isParent => _userRole == 'parent';

  AppViewModel() {
    _loadUserData();
  }

  void _loadUserData() {
    _userRole = SharedPreferenceHandler.getUserRole();
    _userId = SharedPreferenceHandler.getUserId();
    notifyListeners();
  }

  Future<void> login(String role, String name, String email, String uid) async {
    _userRole = role;
    _userName = name;
    _userEmail = email;
    _userId = uid;
    await SharedPreferenceHandler.setUserRole(role);
    await SharedPreferenceHandler.setUserId(uid);
    notifyListeners();
  }

  Future<void> logout() async {
    _userRole = '';
    _userName = '';
    _userEmail = '';
    _userId = '';
    await SharedPreferenceHandler.clearAll();
    notifyListeners();
  }

  bool get isLoggedIn => _userId.isNotEmpty;
}
