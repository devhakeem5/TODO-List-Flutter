import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../controller/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text('settings'.tr), elevation: 0),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'language'.tr,
              icon: Icons.language,
              children: [_buildLanguageTile()],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'reminders'.tr,
              icon: Icons.notifications_outlined,
              children: [_buildReminderFrequencyTile()],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'about_app'.tr,
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: Text('version'.tr),
                  trailing: Text('1.0.0', style: TextStyle(color: Get.theme.hintColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    final isArabic = controller.currentLanguage.value == 'ar_SA';
    return ListTile(
      title: Text('language'.tr),
      subtitle: Text(
        isArabic ? 'العربية' : 'English',
        style: TextStyle(color: Get.theme.hintColor, fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Get.theme.hintColor),
      onTap: () => _showLanguageBottomSheet(),
    );
  }

  void _showLanguageBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_language'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('choose_language'.tr, style: TextStyle(color: Get.theme.hintColor)),
            const SizedBox(height: 24),
            _buildLanguageOption('ar_SA', 'العربية', '🇸🇦'),
            _buildLanguageOption('en_US', 'English', '🇺🇸'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    return Obx(() {
      final isSelected = controller.currentLanguage.value == code;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            controller.changeLanguage(code);
            Get.back();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Get.theme.primaryColor.withOpacity(0.1)
                  : Get.theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Get.theme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? Get.theme.primaryColor
                          : Get.theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: Get.theme.primaryColor),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Get.theme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Get.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Get.theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildReminderFrequencyTile() {
    return Obx(() {
      final currentLevel = controller.globalReminderLevel.value;
      return ListTile(
        title: Text('reminder_count'.tr),
        subtitle: Text(
          _getReminderDescription(currentLevel),
          style: TextStyle(color: Get.theme.hintColor, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'reminder_${currentLevel.name}'.tr,
            style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => _showReminderLevelDialog(),
      );
    });
  }

  String _getReminderDescription(ReminderLevel level) {
    switch (level) {
      case ReminderLevel.low:
        return 'reminder_desc_low'.tr;
      case ReminderLevel.medium:
        return 'reminder_desc_medium'.tr;
      case ReminderLevel.high:
        return 'reminder_desc_high'.tr;
    }
  }

  void _showReminderLevelDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_reminder_level'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('global_reminder_msg'.tr, style: TextStyle(color: Get.theme.hintColor)),
            const SizedBox(height: 24),
            ...ReminderLevel.values.map((level) => _buildLevelOption(level)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelOption(ReminderLevel level) {
    return Obx(() {
      final isSelected = controller.globalReminderLevel.value == level;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            controller.setReminderLevel(level);
            Get.back();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Get.theme.primaryColor.withOpacity(0.1)
                  : Get.theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Get.theme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Get.theme.primaryColor : Get.theme.hintColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'reminder_${level.name}'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Get.theme.primaryColor
                              : Get.theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getReminderDescription(level),
                        style: TextStyle(fontSize: 12, color: Get.theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  'n_reminders'.trParams({'count': level.notificationCount.toString()}),
                  style: TextStyle(color: Get.theme.hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
