import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> createMockSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
  return await SharedPreferences.getInstance();
}
