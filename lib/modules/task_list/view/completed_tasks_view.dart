import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/task_model.dart';
import '../../home/widgets/empty_state_widget.dart';
import '../controller/task_list_controller.dart';

class CompletedTasksView extends GetView<TaskListController> {
  const CompletedTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadCompletedTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('completed_archive'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadCompletedTasks(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.tasks.isEmpty) {
          return EmptyStateWidget(
            message: 'no_completed_this_month'.tr,
            icon: Icons.task_alt_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: controller.tasks.length,
          itemBuilder: (context, index) {
            final task = controller.tasks[index];
            return _buildCompletedTaskItem(context, task);
          },
        );
      }),
    );
  }

  Widget _buildCompletedTaskItem(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Simplified version of TaskItemWidget or custom one to prevent toggling accidentally
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              task.title,
              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
            ),
            subtitle: Text(
              'completed_on'.trParams({'date': DateFormat('yyyy-MM-dd').format(task.updatedAt)}),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.restore_page_rounded, color: Colors.blue),
              onPressed: () => _showReactivateDialog(context, task),
              tooltip: 'reactivate_tooltip'.tr,
            ),
          ),
        ],
      ),
    );
  }

  void _showReactivateDialog(BuildContext context, Task task) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'reactivate_task'.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('set_new_deadline'.tr),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      'date_label'.trParams({
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                      }),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text('time_label'.trParams({'time': selectedTime.format(context)})),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final newDueDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        controller.reactivateTask(task.id, newDueDate).then((_) {
                          Get.back();
                          controller.loadCompletedTasks();
                          Get.snackbar('reactivate_success_title'.tr, 'reactivate_success_msg'.tr);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text('confirm_reactivate'.tr),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
