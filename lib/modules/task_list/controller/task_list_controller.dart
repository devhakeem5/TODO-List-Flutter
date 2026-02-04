import 'package:get/get.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/subtask_repository.dart';
import '../../../data/repositories/task_repository.dart';

class TaskListController extends GetxController {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();
  final SubTaskRepository _subTaskRepository = Get.find<SubTaskRepository>();

  final RxBool isLoading = false.obs;
  final RxList<Task> tasks = <Task>[].obs;
  final RxList<Task> availableTasks = <Task>[].obs;
  final RxMap<String, List<Subtask>> subtasksMap = <String, List<Subtask>>{}.obs;

  // Filters
  final Rx<TaskPriority?> filterPriority = Rx<TaskPriority?>(null);
  final RxList<String> filterCategoryIds = <String>[].obs;

  // Cache
  List<Task> _allTasksCache = [];
  List<Task> _availableTasksCache = [];

  Future<void> loadTodayTasks() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final todayTasks = await _taskRepository.getTasksByDate(now);
      _allTasksCache = todayTasks.where((t) => t.taskType != TaskType.recurring).toList();

      final allFromDb = await _taskRepository.readAll();
      _availableTasksCache = allFromDb.where((t) {
        if (t.startDate == null || t.endDate == null) return false;
        if (t.status == TaskStatus.completed) return false;
        if (t.status == TaskStatus.inProgress) return false;

        final start = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
        final end = DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day, 23, 59, 59);
        final today = DateTime(now.year, now.month, now.day);

        return today.isAtSameMomentAs(start) ||
            (today.isAfter(start) && today.isBefore(end)) ||
            today.isAtSameMomentAs(end);
      }).toList();

      _applyFilters();
      await _loadSubtasksForTasks([...tasks, ...availableTasks]);
    } catch (e) {
      print('Error loading today tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInProgressTasks() async {
    isLoading.value = true;
    try {
      final allTasks = await _taskRepository.readAll();
      final inProgress = allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
      _allTasksCache = inProgress;
      _availableTasksCache = [];

      _applyFilters();
      await _loadSubtasksForTasks(tasks);
    } catch (e) {
      print('Error loading in-progress tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecurringTasks() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final weekday = now.weekday % 7;
      final allTasks = await _taskRepository.readAll();

      final todayRecurring = allTasks.where((t) {
        if (t.taskType != TaskType.recurring) return false;
        if (t.recurrenceDays == null) return false;

        // Exclude if today is an excluded day
        if (t.excludedDays != null) {
          final todayIso = now.toIso8601String().split('T')[0];
          if (t.excludedDays!.contains(todayIso)) return false;
        }

        return t.recurrenceDays!.contains(weekday);
      }).toList();

      _allTasksCache = todayRecurring;
      _availableTasksCache = [];

      _applyFilters();

      // Sort recurring specifically by time
      tasks.sort((a, b) {
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        if (a.startTime!.hour != b.startTime!.hour) {
          return a.startTime!.hour.compareTo(b.startTime!.hour);
        }
        return a.startTime!.minute.compareTo(b.startTime!.minute);
      });

      await _loadSubtasksForTasks(tasks);
    } catch (e) {
      print('Error loading recurring tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCompletedTasks() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final allTasks = await _taskRepository.readAll();
      final thisMonth = allTasks.where((t) {
        if (t.status != TaskStatus.completed) return false;
        return t.updatedAt.isAfter(startOfMonth);
      }).toList();

      _allTasksCache = thisMonth;
      _availableTasksCache = [];

      _applyFilters();
      await _loadSubtasksForTasks(tasks);
    } catch (e) {
      print('Error loading completed tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    tasks.assignAll(_sortTasks(_filterList(_allTasksCache)));
    availableTasks.assignAll(_filterList(_availableTasksCache));
  }

  List<Task> _filterList(List<Task> input) {
    return input.where((task) {
      if (filterPriority.value != null && task.priority != filterPriority.value) return false;
      if (filterCategoryIds.isNotEmpty) {
        if (task.categoryId == null || !filterCategoryIds.contains(task.categoryId)) return false;
      }
      return true;
    }).toList();
  }

  void setPriorityFilter(TaskPriority? priority) {
    if (filterPriority.value == priority) {
      filterPriority.value = null;
    } else {
      filterPriority.value = priority;
    }
    _applyFilters();
  }

  void toggleCategoryFilter(String categoryId) {
    if (filterCategoryIds.contains(categoryId)) {
      filterCategoryIds.remove(categoryId);
    } else {
      filterCategoryIds.add(categoryId);
    }
    _applyFilters();
  }

  List<Task> _sortTasks(List<Task> input) {
    return input..sort((a, b) {
      if (a.status == TaskStatus.inProgress && b.status != TaskStatus.inProgress) return -1;
      if (a.status != TaskStatus.inProgress && b.status == TaskStatus.inProgress) return 1;
      return a.priority.index.compareTo(b.priority.index);
    });
  }

  Future<void> _loadSubtasksForTasks(List<Task> taskList) async {
    for (var task in taskList) {
      final subs = await _subTaskRepository.readByTaskId(task.id);
      subtasksMap[task.id] = subs;
    }
  }

  Future<void> markAsInProgress(String taskId) async {
    try {
      final task = await _taskRepository.read(taskId);
      if (task != null) {
        final updated = task.copyWith(status: TaskStatus.inProgress, updatedAt: DateTime.now());
        await _taskRepository.update(updated);
      }
    } catch (e) {
      print('Error marking as in progress: $e');
    }
  }

  Future<void> reactivateTask(String taskId, DateTime newDueDate) async {
    try {
      final task = await _taskRepository.read(taskId);
      if (task != null) {
        final updated = task.copyWith(
          status: TaskStatus.pending,
          dueDate: newDueDate,
          updatedAt: DateTime.now(),
        );
        await _taskRepository.update(updated);
      }
    } catch (e) {
      print('Error reactivating task: $e');
    }
  }

  Future<void> toggleSubtaskCompletion(Subtask subtask) async {
    try {
      final updated = subtask.copyWith(isCompleted: !subtask.isCompleted);
      await _subTaskRepository.update(updated);

      final list = subtasksMap[subtask.taskId];
      if (list != null) {
        final index = list.indexWhere((s) => s.id == subtask.id);
        if (index != -1) {
          list[index] = updated;
          subtasksMap[subtask.taskId] = List.from(list);
        }
      }
    } catch (e) {
      print('Error toggling subtask: $e');
    }
  }

  Future<void> toggleTaskStatus(Task task) async {
    try {
      final newStatus = task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed;
      final updated = task.copyWith(status: newStatus, updatedAt: DateTime.now());
      await _taskRepository.update(updated);
      // Reload based on current view
    } catch (e) {
      print('Error toggling task status: $e');
    }
  }
}
