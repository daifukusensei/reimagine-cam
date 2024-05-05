import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  late SharedPreferences _prefs;

  static final SettingsManager _instance = SettingsManager._internal();

  factory SettingsManager() {
    return _instance;
  }

  SettingsManager._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }
}
