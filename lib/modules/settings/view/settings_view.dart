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
      appBar: AppBar(title: const Text('الإعدادات'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'التذكيرات',
            icon: Icons.notifications_outlined,
            children: [_buildReminderFrequencyTile()],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'حول التطبيق',
            icon: Icons.info_outline,
            children: [
              ListTile(
                title: const Text('الإصدار'),
                trailing: Text('1.0.0', style: TextStyle(color: Get.theme.hintColor)),
              ),
            ],
          ),
        ],
      ),
    );
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
        title: const Text('عدد التذكيرات'),
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
            currentLevel.arabicLabel,
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
        return 'تذكير واحد فقط';
      case ReminderLevel.medium:
        return '2-3 تذكيرات خلال اليوم';
      case ReminderLevel.high:
        return 'تذكيرات متعددة للتأكد من الإنجاز';
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
            const Text(
              'اختر مستوى التذكير',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'هذا الإعداد يؤثر على جميع المهام بشكل افتراضي',
              style: TextStyle(color: Get.theme.hintColor),
            ),
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
                        level.arabicLabel,
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
                  '${level.notificationCount} تذكير',
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
