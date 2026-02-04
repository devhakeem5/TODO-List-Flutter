import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/task_model.dart';
import '../../home/widgets/empty_state_widget.dart';
import '../controller/task_list_controller.dart';

class RecurringTasksView extends GetView<TaskListController> {
  const RecurringTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadRecurringTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('recurring_tasks_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadRecurringTasks(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.tasks.isEmpty) {
          return EmptyStateWidget(message: 'no_recurring_today'.tr, icon: Icons.repeat_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: controller.tasks.length,
          itemBuilder: (context, index) {
            final task = controller.tasks[index];
            return _buildRecurringTaskItem(context, task);
          },
        );
      }),
    );
  }

  Widget _buildRecurringTaskItem(BuildContext context, Task task) {
    final timeStr = task.startTime != null ? task.startTime!.format(context) : '--:--';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: task.description != null ? Text(task.description!) : null,
            trailing: Checkbox(
              value: task.status == TaskStatus.completed,
              onChanged: (val) {
                controller.toggleTaskStatus(task).then((_) => controller.loadRecurringTasks());
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ),
          if (controller.subtasksMap[task.id]?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: controller.subtasksMap[task.id]!
                    .map(
                      (sub) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              sub.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                              size: 14,
                              color: sub.isCompleted ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sub.title,
                              style: TextStyle(
                                fontSize: 13,
                                decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                color: sub.isCompleted ? Colors.grey : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
