import 'package:shared_preferences/shared_preferences.dart';

class Preference {
  static late SharedPreferences pref;

  /// Initailizing the sharedpreference
  static Future<void> init() async {
    pref = await SharedPreferences.getInstance();
  }

  /// Setter
  Future<void> setBool(String key, bool value) async {
    await pref.setBool(key, value);
  }

  Future<void> setString(String key, String value) async {
    await pref.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    await pref.setInt(key, value);
  }

  Future<void> setDouble(String key, double value) async {
    await pref.setDouble(key, value);
  }

  /// Gettter
  bool? getBool(String key) {
    return pref.getBool(key);
  }

  String? getString(String key) {
    return pref.getString(key);
  }

  int? getInt(String key) {
    return pref.getInt(key);
  }

  double? getDouble(String key) {
    return pref.getDouble(key);
  }
}
