import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../controller/add_task_controller.dart';
import 'widgets/time_type_bottom_sheet.dart';

class AddTaskView extends GetView<AddTaskController> {
  const AddTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('add_task'.tr),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isTitleValid.value ? () => controller.saveTask() : null,
              child: Text(
                'save'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
            _buildTimingSection(),
            const SizedBox(height: 20),
            _buildMetadataSection(),
            const SizedBox(height: 20),
            _buildSubtasksSection(),
            const SizedBox(height: 20),
            _buildAdvancedSection(),
            const SizedBox(height: 100), // Space for FAB or bottom padding
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomSaveButton(),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Get.theme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Get.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Get.theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'general_info'.tr,
      icon: Icons.info_outline,
      child: Column(
        children: [
          TextField(
            controller: controller.titleController,
            decoration: InputDecoration(
              hintText: 'what_needs_done'.tr,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              filled: false,
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const Divider(),
          TextField(
            controller: controller.descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'description_hint'.tr,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              filled: false,
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    return _buildSection(
      title: 'timing'.tr,
      icon: Icons.access_time,
      child: Column(
        children: [
          // Time Type Selection Button
          InkWell(
            onTap: () => _showTimeTypeBottomSheet(),
            borderRadius: BorderRadius.circular(12),
            child: Obx(() {
              final taskType = controller.selectedTaskType.value;
              final hasTime = taskType != TaskType.open;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasTime
                      ? Get.theme.primaryColor.withOpacity(0.1)
                      : Get.theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasTime ? Get.theme.primaryColor : Get.theme.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTaskTypeIcon(taskType),
                      color: hasTime ? Get.theme.primaryColor : Get.theme.hintColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasTime
                                ? 'recurring'.tr
                                : 'select_time'.tr, // Simplified for now, taskType.name can be used
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasTime
                                  ? Get.theme.primaryColor
                                  : Get.theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (hasTime)
                            Text(
                              controller.timeTypeDisplayText,
                              style: TextStyle(fontSize: 12, color: Get.theme.hintColor),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left, color: Get.theme.hintColor),
                  ],
                ),
              );
            }),
          ),

          // Show additional time config for defaultDay type
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Obx(() {
              if (controller.selectedTaskType.value != TaskType.defaultDay) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: Get.context!,
                              initialDate: controller.selectedDueDate.value,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              controller.selectedDueDate.value = picked;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Get.theme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${controller.selectedDueDate.value.day}/${controller.selectedDueDate.value.month}/${controller.selectedDueDate.value.year}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: Get.context!,
                              initialTime: controller.selectedTime.value,
                            );
                            if (picked != null) {
                              controller.selectedTime.value = picked;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Get.theme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(controller.selectedTime.value.format(Get.context!)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getTaskTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.open:
        return Icons.all_inclusive;
      case TaskType.defaultDay:
        return Icons.calendar_today;
      case TaskType.recurring:
        return Icons.repeat;
      case TaskType.timeRange:
        return Icons.date_range;
    }
  }

  void _showTimeTypeBottomSheet() {
    Get.bottomSheet(const TimeTypeBottomSheet(), isScrollControlled: true);
  }

  Widget _buildMetadataSection() {
    return _buildSection(
      title: 'customization'.tr,
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('category'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.categories.isEmpty) return Text('no_categories'.tr);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.categories.map((cat) {
                  return Obx(() {
                    final isSelected = controller.selectedCategory.value?.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (val) => controller.selectedCategory.value = val ? cat : null,
                        backgroundColor: Get.theme.scaffoldBackgroundColor,
                        selectedColor: Get.theme.primaryColor.withOpacity(0.2),
                      ),
                    );
                  });
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text('priority'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                _buildPriorityButton('priority_low'.tr, TaskPriority.low, Colors.green),
                const SizedBox(width: 8),
                _buildPriorityButton('priority_medium'.tr, TaskPriority.medium, Colors.amber),
                const SizedBox(width: 8),
                _buildPriorityButton('priority_high'.tr, TaskPriority.high, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(String label, TaskPriority priority, Color color) {
    final isSelected = controller.selectedPriority.value == priority;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectedPriority.value = priority,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Get.theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Get.theme.dividerColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Get.theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    return _buildSection(
      title: 'subtasks'.tr,
      icon: Icons.checklist,
      child: Column(
        children: [
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: List.generate(controller.subtaskControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.subtaskControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Subtask ${index + 1}',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => controller.removeSubtask(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => controller.addSubtask(),
            icon: const Icon(Icons.add, size: 18),
            label: Text('add_subtask'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      children: [
        Theme(
          data: Get.theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text('advanced_options'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(Icons.settings_outlined, color: Get.theme.primaryColor),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('reminder'.tr),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: Get.context!,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          controller.reminderDateTime.value = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        }
                      }
                    },
                    child: Obx(
                      () => Text(
                        controller.reminderDateTime.value == null
                            ? 'set_reminder'.tr
                            : controller.reminderDateTime.value!.toString().substring(0, 16),
                      ),
                    ),
                  ),
                ],
              ),
              const Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.repeat, size: 20),
                      SizedBox(width: 12),
                      Text('Recurrence (Coming Soon)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(
          () => ElevatedButton(
            onPressed: controller.isTitleValid.value ? () => controller.saveTask() : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Get.theme.primaryColor,
              elevation: 0,
            ),
            child: Text(
              'create_task'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
