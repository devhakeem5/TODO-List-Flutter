import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/task_model.dart';
import '../../category/controller/category_controller.dart';
import '../../home/widgets/empty_state_widget.dart';
import '../../home/widgets/task_item_widget.dart';
import '../controller/task_list_controller.dart';

class TodayTasksView extends GetView<TaskListController> {
  const TodayTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initial load
    controller.loadTodayTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('today_tasks_title'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.loadTodayTasks()),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.tasks.isEmpty && controller.availableTasks.isEmpty) {
                return EmptyStateWidget(message: 'no_tasks_lately'.tr, icon: Icons.sunny);
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  if (controller.tasks.isNotEmpty) ...[
                    _buildSectionHeader(context, 'exclusive_today'.tr),
                    ...controller.tasks.map(
                      (task) => TaskItemWidget(
                        task: task,
                        subtasks: controller.subtasksMap[task.id] ?? [],
                        onSubtaskToggle: controller.toggleSubtaskCompletion,
                        onTap: (id) => Get.toNamed('/task_details', arguments: id),
                      ),
                    ),
                  ],
                  if (controller.availableTasks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'continuous_tasks'.tr),
                    ...controller.availableTasks.map(
                      (task) => _buildAvailableTaskItem(context, task),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterLabel(context, 'categories_label'.tr),
              const SizedBox(width: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children: categoryController.categories.map((cat) {
                    return FilterChip(
                      label: Text(cat.name),
                      selected: controller.filterCategoryIds.contains(cat.id),
                      onSelected: (val) => controller.toggleCategoryFilter(cat.id),
                      selectedColor: Color(cat.color).withOpacity(0.3),
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              _buildFilterLabel(context, 'priority_label'.tr),
              const SizedBox(width: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children: TaskPriority.values.map((priority) {
                    return ChoiceChip(
                      label: Text('priority_${priority.name}'.tr),
                      selected: controller.filterPriority.value == priority,
                      onSelected: (val) => controller.setPriorityFilter(priority),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterLabel(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildAvailableTaskItem(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          TaskItemWidget(
            task: task,
            subtasks: controller.subtasksMap[task.id] ?? [],
            onSubtaskToggle: controller.toggleSubtaskCompletion,
            onTap: (id) => Get.toNamed('/task_details', arguments: id),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      controller.markAsInProgress(task.id).then((_) => controller.loadTodayTasks()),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text('start_task_now'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
