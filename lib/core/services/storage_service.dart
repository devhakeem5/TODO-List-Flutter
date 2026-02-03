import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> write(String key, dynamic value) async {
    if (value is String) {
      return await _prefs.setString(key, value);
    } else if (value is int) {
      return await _prefs.setInt(key, value);
    } else if (value is bool) {
      return await _prefs.setBool(key, value);
    } else if (value is double) {
      return await _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      return await _prefs.setStringList(key, value);
    } else {
      return false; // Unsupported type
    }
  }

  T? read<T>(String key) {
    return _prefs.get(key) as T?;
  }

  bool has(String key) {
    return _prefs.containsKey(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
}

class StorageKeys {
  static const String userName = 'user_name';
  static const String isFirstLaunch = 'is_first_launch';
  static const String globalReminderLevel = 'global_reminder_level';
  static const String disabledTaskReminders = 'disabled_task_reminders'; // JSON list of task IDs
}
