import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences createMockSharedPreferences() {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences();
}
