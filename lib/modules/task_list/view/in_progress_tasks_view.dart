import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../../category/controller/category_controller.dart';
import '../../home/widgets/empty_state_widget.dart';
import '../../home/widgets/task_item_widget.dart';
import '../controller/task_list_controller.dart';

class InProgressTasksView extends GetView<TaskListController> {
  const InProgressTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadInProgressTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('in_progress_tasks_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInProgressTasks(),
          ),
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

              if (controller.tasks.isEmpty) {
                return EmptyStateWidget(
                  message: 'no_in_progress_match'.tr,
                  icon: Icons.pending_actions_rounded,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: controller.tasks.length,
                itemBuilder: (context, index) {
                  final task = controller.tasks[index];
                  return TaskItemWidget(
                    task: task,
                    subtasks: controller.subtasksMap[task.id] ?? [],
                    onSubtaskToggle: controller.toggleSubtaskCompletion,
                    onTap: (id) => Get.toNamed('/task_details', arguments: id),
                  );
                },
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
}
