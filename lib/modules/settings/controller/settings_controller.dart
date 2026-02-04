import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/task_model.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final Rx<ReminderLevel> globalReminderLevel = ReminderLevel.medium.obs;
  final RxList<String> disabledTaskReminders = <String>[].obs;
  final RxString currentLanguage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Load language
    final savedLang = _storage.read<String>(StorageKeys.languageCode);
    currentLanguage.value = savedLang ?? 'ar_SA';

    // Load global reminder level
    final savedLevel = _storage.read<String>(StorageKeys.globalReminderLevel);
    if (savedLevel != null) {
      globalReminderLevel.value = ReminderLevel.fromString(savedLevel);
    }

    // Load disabled task reminders
    final savedDisabled = _storage.read<String>(StorageKeys.disabledTaskReminders);
    if (savedDisabled != null) {
      try {
        final decoded = jsonDecode(savedDisabled) as List;
        disabledTaskReminders.assignAll(decoded.cast<String>());
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  /// Set global reminder level
  Future<void> setReminderLevel(ReminderLevel level) async {
    globalReminderLevel.value = level;
    await _storage.write(StorageKeys.globalReminderLevel, level.toStringValue());
  }

  /// Change app language
  Future<void> changeLanguage(String langCode) async {
    currentLanguage.value = langCode;
    final locale = Locale(langCode.split('_')[0], langCode.split('_')[1]);
    await Get.updateLocale(locale);
    await _storage.write(StorageKeys.languageCode, langCode);
  }

  /// Get effective reminder level for a task
  /// Task-specific level takes priority over global
  ReminderLevel getEffectiveReminderLevel(Task task) {
    return task.reminderLevel ?? globalReminderLevel.value;
  }

  /// Disable reminders for a specific task
  Future<void> disableTaskReminder(String taskId) async {
    if (!disabledTaskReminders.contains(taskId)) {
      disabledTaskReminders.add(taskId);
      await _saveDisabledReminders();
    }
  }

  /// Enable reminders for a specific task
  Future<void> enableTaskReminder(String taskId) async {
    disabledTaskReminders.remove(taskId);
    await _saveDisabledReminders();
  }

  /// Check if reminders are disabled for a task
  bool isReminderDisabled(String taskId) {
    return disabledTaskReminders.contains(taskId);
  }

  Future<void> _saveDisabledReminders() async {
    await _storage.write(
      StorageKeys.disabledTaskReminders,
      jsonEncode(disabledTaskReminders.toList()),
    );
  }
}
