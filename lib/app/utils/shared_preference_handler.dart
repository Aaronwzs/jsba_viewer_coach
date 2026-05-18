import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHandler {
  SharedPreferences? _prefs;

  SharedPreferenceHandler({SharedPreferences? prefs}) : _prefs = prefs;

  static SharedPreferenceHandler? _instance;
  static SharedPreferenceHandler get instance {
    _instance ??= SharedPreferenceHandler();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String getAuthToken() {
    return _prefs?.getString('authToken') ?? '';
  }

  Future<void> setAuthToken(String token) async {
    await _prefs?.setString('authToken', token);
  }

  String getUserRole() {
    return _prefs?.getString('userRole') ?? '';
  }

  Future<void> setUserRole(String role) async {
    await _prefs?.setString('userRole', role);
  }

  String getUserId() {
    return _prefs?.getString('userId') ?? '';
  }

  Future<void> setUserId(String id) async {
    await _prefs?.setString('userId', id);
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
