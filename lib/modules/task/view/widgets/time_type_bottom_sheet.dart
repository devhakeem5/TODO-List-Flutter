import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/enums.dart';
import '../../controller/add_task_controller.dart';

/// Bottom sheet for selecting task time type
class TimeTypeBottomSheet extends StatelessWidget {
  const TimeTypeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddTaskController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Get.theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text('تحديد الوقت', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('اختر نوع التوقيت للمهمة', style: TextStyle(color: Get.theme.hintColor)),
          const SizedBox(height: 24),

          // Option: Open (no time)
          _buildOpenOption(controller),
          const SizedBox(height: 12),

          // Option: Default Day
          _buildDefaultOption(controller),
          const SizedBox(height: 12),

          // Option: Recurring
          _buildRecurringOption(controller),
          const SizedBox(height: 12),

          // Option: Time Range
          _buildTimeRangeOption(controller),
        ],
      ),
    );
  }

  Widget _buildOpenOption(AddTaskController controller) {
    return Obx(
      () => _TaskTypeOption(
        icon: Icons.all_inclusive,
        title: 'مفتوحة',
        description: 'بدون تاريخ انتهاء',
        isSelected: controller.selectedTaskType.value == TaskType.open,
        onTap: () {
          controller.selectedTaskType.value = TaskType.open;
          controller.clearTimeSettings();
          Get.back();
        },
      ),
    );
  }

  Widget _buildDefaultOption(AddTaskController controller) {
    return Obx(
      () => _TaskTypeOption(
        icon: Icons.calendar_today,
        title: 'افتراضي',
        description: 'مهمة ليوم واحد محدد',
        isSelected: controller.selectedTaskType.value == TaskType.defaultDay,
        onTap: () async {
          final date = await showDatePicker(
            context: Get.context!,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            controller.selectedTaskType.value = TaskType.defaultDay;
            controller.selectedDueDate.value = date;
            controller.hasDeadline.value = true;
            Get.back();
          }
        },
      ),
    );
  }

  Widget _buildRecurringOption(AddTaskController controller) {
    return Obx(
      () => _TaskTypeOption(
        icon: Icons.repeat,
        title: 'متكررة',
        description: 'تتكرر حسب أيام الأسبوع',
        isSelected: controller.selectedTaskType.value == TaskType.recurring,
        onTap: () {
          controller.selectedTaskType.value = TaskType.recurring;
          Get.back();
          _showRecurringConfigDialog(controller);
        },
      ),
    );
  }

  Widget _buildTimeRangeOption(AddTaskController controller) {
    return Obx(
      () => _TaskTypeOption(
        icon: Icons.date_range,
        title: 'فترة زمنية',
        description: 'من تاريخ إلى تاريخ',
        isSelected: controller.selectedTaskType.value == TaskType.timeRange,
        onTap: () async {
          final dateRange = await showDateRangePicker(
            context: Get.context!,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (dateRange != null) {
            controller.selectedTaskType.value = TaskType.timeRange;
            controller.startDate.value = dateRange.start;
            controller.endDate.value = dateRange.end;
            controller.hasDeadline.value = true;
            Get.back();
          }
        },
      ),
    );
  }

  void _showRecurringConfigDialog(AddTaskController controller) {
    Get.bottomSheet(_RecurringConfigSheet(controller: controller), isScrollControlled: true);
  }
}

class _TaskTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Get.theme.primaryColor.withOpacity(0.1) : Get.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Get.theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Get.theme.primaryColor.withOpacity(0.2)
                    : Get.theme.dividerColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Get.theme.primaryColor : Get.theme.hintColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Get.theme.primaryColor
                          : Get.theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Get.theme.hintColor)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: Get.theme.primaryColor),
          ],
        ),
      ),
    );
  }
}

/// Configuration sheet for recurring tasks
class _RecurringConfigSheet extends StatelessWidget {
  final AddTaskController controller;

  const _RecurringConfigSheet({required this.controller});

  static const _weekDays = [
    (0, 'الأحد'),
    (1, 'الاثنين'),
    (2, 'الثلاثاء'),
    (3, 'الأربعاء'),
    (4, 'الخميس'),
    (5, 'الجمعة'),
    (6, 'السبت'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Get.theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'إعداد المهمة المتكررة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Weekday selector
          const Text('أيام التكرار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekDays.map((day) => _buildDayChip(day.$1, day.$2)).toList(),
          ),
          const SizedBox(height: 24),

          // Time range
          const Text('وقت التنفيذ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimeButton('من', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeButton('إلى', false)),
            ],
          ),
          const SizedBox(height: 24),

          // Optional end date
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تاريخ انتهاء (اختياري)'),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      controller.endDate.value = date;
                    }
                  },
                  child: Text(
                    controller.endDate.value != null
                        ? '${controller.endDate.value!.day}/${controller.endDate.value!.month}/${controller.endDate.value!.year}'
                        : 'تحديد',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (controller.recurrenceDays.isEmpty) {
                  Get.snackbar('خطأ', 'يرجى اختيار يوم واحد على الأقل');
                  return;
                }
                controller.hasDeadline.value = true;
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int dayIndex, String label) {
    return Obx(() {
      final isSelected = controller.recurrenceDays.contains(dayIndex);
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.toggleRecurrenceDay(dayIndex),
        selectedColor: Get.theme.primaryColor.withOpacity(0.2),
        checkmarkColor: Get.theme.primaryColor,
      );
    });
  }

  Widget _buildTimeButton(String label, bool isStart) {
    return Obx(() {
      final time = isStart ? controller.startTimeOfDay.value : controller.endTimeOfDay.value;
      return InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: Get.context!,
            initialTime: time ?? TimeOfDay.now(),
          );
          if (picked != null) {
            if (isStart) {
              controller.startTimeOfDay.value = picked;
            } else {
              controller.endTimeOfDay.value = picked;
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Get.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Get.theme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: Get.theme.hintColor)),
              const SizedBox(width: 8),
              Text(
                time?.format(Get.context!) ?? '--:--',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    });
  }
}
