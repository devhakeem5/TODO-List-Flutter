import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/subtask_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../settings/controller/settings_controller.dart';

class AddTaskController extends GetxController {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final SubTaskRepository _subTaskRepository = Get.find<SubTaskRepository>();

  // Basic Info
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxBool isTitleValid = false.obs;

  // Task Type
  final Rx<TaskType> selectedTaskType = TaskType.open.obs;

  // Task Timing & Deadline (legacy support)
  final RxBool hasDeadline = false.obs;
  final Rx<DateTime> selectedDueDate = DateTime.now().obs;
  final Rx<TimeOfDay> selectedTime = TimeOfDay.now().obs;

  // Time Range (for timeRange type)
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  // Recurring Task
  final RxList<int> recurrenceDays = <int>[].obs; // 0=Sun, 1=Mon, ..., 6=Sat
  final RxList<String> excludedDays = <String>[].obs; // ISO date strings
  final Rxn<TimeOfDay> startTimeOfDay = Rxn<TimeOfDay>();
  final Rxn<TimeOfDay> endTimeOfDay = Rxn<TimeOfDay>();

  // Metadata
  final Rxn<Category> selectedCategory = Rxn<Category>();
  final Rx<TaskPriority> selectedPriority = TaskPriority.medium.obs;
  final Rxn<DateTime> reminderDateTime = Rxn<DateTime>();

  // Reminder Settings
  final RxBool useGlobalReminder = true.obs;
  final Rxn<ReminderLevel> taskReminderLevel = Rxn<ReminderLevel>();
  final RxBool reminderEnabled = true.obs;

  // Subtasks
  final RxList<TextEditingController> subtaskControllers = <TextEditingController>[].obs;

  // Advanced Options
  final RxBool isAdvancedExpanded = false.obs;

  // Data Source for Categories
  final RxList<Category> categories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();

    // Listen to title changes for validation
    titleController.addListener(() {
      isTitleValid.value = titleController.text.trim().isNotEmpty;
    });
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    for (var controller in subtaskControllers) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> _loadCategories() async {
    final result = await _categoryRepository.readAll();
    categories.assignAll(result);
  }

  // --- Task Type Logic ---

  /// Clear all time-related settings
  void clearTimeSettings() {
    hasDeadline.value = false;
    selectedDueDate.value = DateTime.now();
    selectedTime.value = TimeOfDay.now();
    startDate.value = null;
    endDate.value = null;
    recurrenceDays.clear();
    excludedDays.clear();
    startTimeOfDay.value = null;
    endTimeOfDay.value = null;
  }

  /// Toggle a weekday for recurring tasks
  void toggleRecurrenceDay(int dayIndex) {
    if (recurrenceDays.contains(dayIndex)) {
      recurrenceDays.remove(dayIndex);
    } else {
      recurrenceDays.add(dayIndex);
    }
  }

  /// Exclude a specific date from recurring
  void excludeDay(DateTime date) {
    final isoDate = date.toIso8601String().split('T')[0];
    if (!excludedDays.contains(isoDate)) {
      excludedDays.add(isoDate);
    }
  }

  /// Get display text for selected time type
  String get timeTypeDisplayText {
    switch (selectedTaskType.value) {
      case TaskType.open:
        return 'open'.tr;
      case TaskType.defaultDay:
        return '${selectedDueDate.value.day}/${selectedDueDate.value.month}/${selectedDueDate.value.year}';
      case TaskType.recurring:
        return 'n_days'.trParams({'count': recurrenceDays.length.toString()});
      case TaskType.timeRange:
        if (startDate.value != null && endDate.value != null) {
          return '${startDate.value!.day}/${startDate.value!.month} - ${endDate.value!.day}/${endDate.value!.month}';
        }
        return 'time_range'.tr;
    }
  }

  // --- Subtasks Logic ---

  void addSubtask() {
    subtaskControllers.add(TextEditingController());
  }

  void removeSubtask(int index) {
    subtaskControllers[index].dispose();
    subtaskControllers.removeAt(index);
  }

  // --- Logic ---

  Future<void> saveTask() async {
    if (!isTitleValid.value) return;

    try {
      final String id = const Uuid().v4();
      final DateTime now = DateTime.now();

      // Determine final due date based on task type
      DateTime? finalDueDate;
      DateTime? finalStartDate;
      DateTime? finalEndDate;

      switch (selectedTaskType.value) {
        case TaskType.open:
          // No dates
          break;
        case TaskType.defaultDay:
          finalDueDate = DateTime(
            selectedDueDate.value.year,
            selectedDueDate.value.month,
            selectedDueDate.value.day,
            selectedTime.value.hour,
            selectedTime.value.minute,
          );
          break;
        case TaskType.recurring:
          // For recurring, we don't set dueDate but use startTime/endTime
          finalEndDate = endDate.value;
          break;
        case TaskType.timeRange:
          finalStartDate = startDate.value;
          finalEndDate = endDate.value;
          finalDueDate = endDate.value; // Due on end date
          break;
      }

      final int? notificationId = (hasDeadline.value || selectedTaskType.value != TaskType.open)
          ? DateTime.now().millisecondsSinceEpoch % 2147483647
          : null;

      // Determine reminder level
      ReminderLevel? effectiveReminderLevel;
      if (!useGlobalReminder.value && taskReminderLevel.value != null) {
        effectiveReminderLevel = taskReminderLevel.value;
      }

      final newTask = Task(
        id: id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        categoryId: selectedCategory.value?.id,
        priority: selectedPriority.value,
        status: TaskStatus.pending,
        taskType: selectedTaskType.value,
        isDateBased: hasDeadline.value || selectedTaskType.value != TaskType.open,
        dueDate: finalDueDate,
        startDate: finalStartDate,
        endDate: finalEndDate,
        isRecurring: selectedTaskType.value == TaskType.recurring,
        recurrenceDays: recurrenceDays.isNotEmpty ? recurrenceDays.toList() : null,
        excludedDays: excludedDays.isNotEmpty ? excludedDays.toList() : null,
        startTime: startTimeOfDay.value,
        endTime: endTimeOfDay.value,
        reminderLevel: effectiveReminderLevel,
        reminderEnabled: reminderEnabled.value,
        reminderDateTime: reminderDateTime.value,
        notificationId: notificationId,
        createdAt: now,
        updatedAt: now,
      );

      // Check for time overlap
      if (selectedTaskType.value == TaskType.recurring) {
        final conflict = await _checkTimeOverlap();
        if (conflict != null) {
          bool proceed = await _showOverlapWarning(conflict);
          if (!proceed) return;
        }
      }

      // Schedule Notifications based on task type
      if (notificationId != null && reminderEnabled.value) {
        await _scheduleNotifications(newTask, notificationId);
      }

      // 1. Save Task
      await _taskRepository.create(newTask);

      // 2. Save Subtasks
      for (var controller in subtaskControllers) {
        final subtaskTitle = controller.text.trim();
        if (subtaskTitle.isNotEmpty) {
          final subtask = Subtask(
            id: const Uuid().v4(),
            taskId: id,
            title: subtaskTitle,
            isCompleted: false,
          );
          await _subTaskRepository.create(subtask);
        }
      }

      Get.back();
      Get.snackbar('success'.tr, 'task_added_success'.tr);

      // Refresh Home if registered
      try {
        if (Get.isRegistered<GetxController>(tag: 'HomeController')) {
          final homeController = Get.find<GetxController>(tag: 'HomeController');
          // Assuming loadTasks method exists or similar
          (homeController as dynamic).loadTasks();
        }
      } catch (e) {
        // ignore
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'task_added_error'.trParams({'error': e.toString()}));
    }
  }

  Future<void> _scheduleNotifications(Task task, int baseNotificationId) async {
    try {
      final NotificationService notificationService = Get.find<NotificationService>();

      // Get effective reminder level
      ReminderLevel reminderLevel = task.reminderLevel ?? ReminderLevel.medium;
      try {
        if (Get.isRegistered<SettingsController>()) {
          final settingsController = Get.find<SettingsController>();
          reminderLevel = settingsController.getEffectiveReminderLevel(task);
        }
      } catch (e) {
        // Use default if settings not available
      }

      switch (task.taskType) {
        case TaskType.open:
          // No notifications for open tasks
          break;

        case TaskType.defaultDay:
          // Schedule multiple reminders throughout the day
          if (task.dueDate != null) {
            await _scheduleDefaultDayNotifications(
              notificationService,
              task,
              baseNotificationId,
              reminderLevel,
            );
          }
          break;

        case TaskType.recurring:
          // Schedule reminder before start time
          if (task.startTime != null && task.recurrenceDays != null) {
            await _scheduleRecurringNotification(notificationService, task, baseNotificationId);
          }
          break;

        case TaskType.timeRange:
          // Schedule notifications for day before and on end date
          if (task.endDate != null) {
            await _scheduleTimeRangeNotifications(notificationService, task, baseNotificationId);
          }
          break;
      }
    } catch (e) {
      Get.log('Failed to schedule notifications: $e');
    }
  }

  Future<void> _scheduleDefaultDayNotifications(
    NotificationService service,
    Task task,
    int baseId,
    ReminderLevel level,
  ) async {
    final motivationalMessages = [
      'حان وقت إنجاز "${task.title}"! 💪',
      'لا تنسَ مهمتك: ${task.title} ⏰',
      'هل أنهيت "${task.title}"؟ أنت قادر! 🌟',
      'تذكير: ${task.title} - ابدأ الآن! 🚀',
      'المهمة "${task.title}" بانتظارك! ✨',
    ];

    final dueDate = task.dueDate!;
    final count = level.notificationCount;

    // Schedule notifications at different times during the day
    final times = <DateTime>[];

    if (count >= 1) {
      times.add(DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0)); // 9 AM
    }
    if (count >= 2) {
      times.add(DateTime(dueDate.year, dueDate.month, dueDate.day, 13, 0)); // 1 PM
    }
    if (count >= 3) {
      times.add(DateTime(dueDate.year, dueDate.month, dueDate.day, 17, 0)); // 5 PM
    }
    if (count >= 4) {
      times.add(DateTime(dueDate.year, dueDate.month, dueDate.day, 20, 0)); // 8 PM
    }
    if (count >= 5) {
      times.add(DateTime(dueDate.year, dueDate.month, dueDate.day, 22, 0)); // 10 PM
    }

    for (int i = 0; i < times.length; i++) {
      final message = motivationalMessages[i % motivationalMessages.length];
      await service.scheduleNotification(
        id: baseId + i,
        title: 'تذكير بمهمتك',
        body: message,
        scheduledTime: times[i],
        payload: task.id,
      );
    }
  }

  Future<void> _scheduleRecurringNotification(
    NotificationService service,
    Task task,
    int baseId,
  ) async {
    if (task.startTime == null || task.recurrenceDays == null) return;

    final now = DateTime.now();
    for (int i = 0; i < task.recurrenceDays!.length; i++) {
      final day = task.recurrenceDays![i];

      // Find the next occurrence of this specific weekday
      DateTime scheduledDate = _getNextWeekday(day, now);

      final startTimeFull = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        task.startTime!.hour,
        task.startTime!.minute,
      );

      final fiveMinsBefore = startTimeFull.subtract(const Duration(minutes: 5));

      DateTime actualAlertTime = fiveMinsBefore;
      String bodyText = 'المهمة "${task.title}" ستبدأ بعد 5 دقائق';

      // Fallback: If 5 mins before is past but start time is future, use start time
      if (actualAlertTime.isBefore(now)) {
        if (startTimeFull.isAfter(now)) {
          actualAlertTime = startTimeFull;
          bodyText = 'حان الآن موعد المهمة: "${task.title}"';
        } else {
          // Both are past for today's occurrence, move to next week
          final nextWeekDate = scheduledDate.add(const Duration(days: 7));
          actualAlertTime = DateTime(
            nextWeekDate.year,
            nextWeekDate.month,
            nextWeekDate.day,
            task.startTime!.hour,
            task.startTime!.minute,
          ).subtract(const Duration(minutes: 5));
        }
      }

      // Use a unique ID for each day's notification
      await service.scheduleNotification(
        id: baseId + i,
        title: 'تذكير المهمة المتكررة',
        body: bodyText,
        scheduledTime: actualAlertTime,
        payload: task.id,
      );
    }
  }

  Future<Task?> _checkTimeOverlap() async {
    if (startTimeOfDay.value == null || endTimeOfDay.value == null || recurrenceDays.isEmpty) {
      return null;
    }

    final allTasks = await _taskRepository.readAll();
    final newStart = startTimeOfDay.value!;
    final newEnd = endTimeOfDay.value!;

    for (var task in allTasks) {
      if (task.taskType == TaskType.recurring && task.startTime != null && task.endTime != null) {
        // Check if same days
        final hasCommonDay = recurrenceDays.any(
          (day) => task.recurrenceDays?.contains(day) ?? false,
        );
        if (!hasCommonDay) continue;

        // Check if time overlaps
        if (_isTimeOverlap(newStart, newEnd, task.startTime!, task.endTime!)) {
          return task;
        }
      }
    }
    return null;
  }

  bool _isTimeOverlap(TimeOfDay startA, TimeOfDay endA, TimeOfDay startB, TimeOfDay endB) {
    final aStart = startA.hour * 60 + startA.minute;
    final aEnd = endA.hour * 60 + endA.minute;
    final bStart = startB.hour * 60 + startB.minute;
    final bEnd = endB.hour * 60 + endB.minute;

    return aStart < bEnd && bStart < aEnd;
  }

  Future<bool> _showOverlapWarning(Task conflictingTask) async {
    final startStr = conflictingTask.startTime!.format(Get.context!);
    final endStr = conflictingTask.endTime!.format(Get.context!);

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('time_overlap_title'.tr),
        content: Text(
          'time_overlap_msg'.trParams({
            'title': conflictingTask.title,
            'start': startStr,
            'end': endStr,
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('change_time'.tr)),
          ElevatedButton(onPressed: () => Get.back(result: true), child: Text('continue_save'.tr)),
        ],
      ),
    );
    return result ?? false;
  }

  DateTime _getNextWeekday(int day, DateTime from) {
    for (int i = 0; i < 7; i++) {
      final checkDate = from.add(Duration(days: i));
      if (checkDate.weekday % 7 == day) {
        return checkDate;
      }
    }
    return from;
  }

  Future<void> _scheduleTimeRangeNotifications(
    NotificationService service,
    Task task,
    int baseId,
  ) async {
    final endDate = task.endDate!;

    // Day before notification
    final dayBefore = endDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      await service.scheduleNotification(
        id: baseId,
        title: 'تذكير بموعد الإنجاز',
        body: 'غداً موعد إنجاز المهمة "${task.title}"',
        scheduledTime: DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 9, 0),
        payload: task.id,
      );
    }

    // Same day notification
    await service.scheduleNotification(
      id: baseId + 1,
      title: 'اليوم موعد الإنجاز!',
      body: 'المهمة "${task.title}" يجب إنهاؤها اليوم',
      scheduledTime: DateTime(endDate.year, endDate.month, endDate.day, 9, 0),
      payload: task.id,
    );
  }
}
