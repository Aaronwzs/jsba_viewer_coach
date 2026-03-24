import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHandler {
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getAuthToken() {
    return _prefs?.getString('authToken') ?? '';
  }

  static Future<void> setAuthToken(String token) async {
    await _prefs?.setString('authToken', token);
  }

  static String getUserRole() {
    return _prefs?.getString('userRole') ?? '';
  }

  static Future<void> setUserRole(String role) async {
    await _prefs?.setString('userRole', role);
  }

  static String getUserId() {
    return _prefs?.getString('userId') ?? '';
  }

  static Future<void> setUserId(String id) async {
    await _prefs?.setString('userId', id);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
