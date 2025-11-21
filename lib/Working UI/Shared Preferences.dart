import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getLocalData(String? key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key!);
}

Future<void> saveLocalData(String key, String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> removeLocalData(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
