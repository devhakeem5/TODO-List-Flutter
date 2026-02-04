import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/enums.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/category_model.dart';
import '../../data/models/subtask_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/subtask_repository.dart';
import '../../data/repositories/task_repository.dart';

class HomeController extends GetxController {
  final TaskRepository _taskRepository = Get.find<TaskRepository>();
  final SubTaskRepository _subTaskRepository = Get.find<SubTaskRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxString userName = ''.obs;
  final RxBool isLoading = true.obs;

  // Task Lists
  final RxList<Task> todayTasks = <Task>[].obs;
  final RxList<Task> ongoingTasks = <Task>[].obs;
  final RxList<Task> upcomingTasks = <Task>[].obs;
  final RxList<Task> recurringTasksToday = <Task>[].obs;

  // Subtasks Map: taskId -> list of subtasks
  final RxMap<String, List<Subtask>> subtasksMap = <String, List<Subtask>>{}.obs;

  // Slider Stats
  final RxInt todayTasksCount = 0.obs;
  final RxInt availableTasksCount = 0.obs;
  final RxInt inProgressCount = 0.obs;
  final RxInt completedThisMonthCount = 0.obs;
  final RxInt completedSubtasksThisMonth = 0.obs;

  // Recurring Stats
  final RxInt recurringCompletedCount = 0.obs;
  final RxInt recurringMissedCount = 0.obs;
  final RxBool showRecurringCard = false.obs;
  final Rxn<Task> activeRecurringTask = Rxn<Task>();

  // Filter State
  final RxString searchText = ''.obs;
  final RxBool isSearching = false.obs;
  final Rx<TaskStatus?> filterStatus = Rx<TaskStatus?>(null);
  final Rx<TaskPriority?> filterPriority = Rx<TaskPriority?>(null);
  final RxList<String> filterCategoryIds = <String>[].obs;
  final RxList<Category> availableCategories = <Category>[].obs;

  // Original Data (Cache for filtering)
  final List<Task> _originalTodayTasks = [];
  final List<Task> _originalOngoingTasks = [];
  final List<Task> _originalUpcomingTasks = [];

  // Repositories
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();

  @override
  void onInit() {
    super.onInit();
    _loadUserName();
    loadCategories();
    loadTasks();
  }

  void _loadUserName() {
    userName.value = _storageService.read<String>(StorageKeys.userName) ?? 'Friend';
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _categoryRepository.readAll();
      availableCategories.assignAll(categories);
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> loadTasks() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();

      // Recurring Task Reset Logic
      await _resetRecurringTasks();

      // 1. Today's Date-Based Tasks
      final todayResult = await _taskRepository.getTasksByDate(now);
      _originalTodayTasks.assignAll(todayResult);

      // 2. Ongoing Tasks (Time-Based)
      final ongoingResult = await _taskRepository.getOngoingTasks(now);
      _originalOngoingTasks.assignAll(ongoingResult);

      // 3. Upcoming Tasks (Next 2 days)
      final tomorrow = now.add(const Duration(days: 1));
      final afterTomorrow = now.add(const Duration(days: 3));
      final upcomingResult = await _taskRepository.getUpcomingTasks(tomorrow, afterTomorrow);
      _originalUpcomingTasks.assignAll(upcomingResult);

      // 4. Recurring Tasks Today
      final todayRecurring = await _taskRepository.getRecurringTasksForDay(now);
      recurringTasksToday.assignAll(todayRecurring);

      // Apply cached filters
      filterTasks();

      // Load subtasks for all visible tasks
      await _loadAllSubtasks();

      // Update Slider Stats
      await _updateSliderStats();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateSliderStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Card 1 logic: Today's tasks (excluding recurring)
      final todayTasksResult = await _taskRepository.getTasksByDate(now);
      todayTasksCount.value = todayTasksResult
          .where((t) => t.taskType != TaskType.recurring)
          .length;

      // Available Tasks (timeRange overlapping today)
      availableTasksCount.value = await _taskRepository.countAvailableTasks(now);

      inProgressCount.value = await _taskRepository.countInProgress();
      completedThisMonthCount.value = await _taskRepository.countCompletedRange(
        startOfMonth,
        endOfMonth,
      );
      completedSubtasksThisMonth.value = await _taskRepository.countCompletedSubtasksRange(
        startOfMonth,
        endOfMonth,
      );

      // Recurring Stats
      final recurringStats = await _taskRepository.countRecurringStats(now);
      recurringCompletedCount.value = recurringStats['completed'] ?? 0;
      recurringMissedCount.value = recurringStats['missed'] ?? 0;

      final totalRecurringToday = await _taskRepository.countRecurringTasksForDay(now);
      showRecurringCard.value = totalRecurringToday > 0;

      // Find Active Recurring Task
      _findActiveRecurringTask(now);
    } catch (e) {
      print('Error updating slider stats: $e');
    }
  }

  void _findActiveRecurringTask(DateTime now) {
    activeRecurringTask.value = null;
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (var task in recurringTasksToday) {
      if (task.startTime == null || task.endTime == null) continue;

      final startStr = _timeToString(task.startTime);
      final endStr = _timeToString(task.endTime);

      if (startStr != null && endStr != null) {
        if (currentTimeStr.compareTo(startStr) >= 0 && currentTimeStr.compareTo(endStr) <= 0) {
          activeRecurringTask.value = task;
          break;
        }
      }
    }
  }

  String? _timeToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resetRecurringTasks() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final allTasks = await _taskRepository.readAll();
    for (var task in allTasks) {
      if (task.taskType == TaskType.recurring && task.status == TaskStatus.completed) {
        if (task.updatedAt.isBefore(startOfToday)) {
          final resetTask = task.copyWith(status: TaskStatus.pending, updatedAt: now);
          await _taskRepository.update(resetTask);
        }
      }
    }
  }

  Future<void> _loadAllSubtasks() async {
    final allTaskIds = <dynamic>{
      ..._originalTodayTasks.map((t) => t.id),
      ..._originalOngoingTasks.map((t) => t.id),
      ..._originalUpcomingTasks.map((t) => t.id),
      ...recurringTasksToday.map((t) => t.id),
    };

    for (var taskId in allTaskIds) {
      final subs = await _subTaskRepository.readByTaskId(taskId);
      subtasksMap[taskId] = subs;
    }
  }

  Future<void> toggleSubtaskCompletion(Subtask subtask) async {
    try {
      final updated = subtask.copyWith(isCompleted: !subtask.isCompleted);
      await _subTaskRepository.update(updated);

      // Update local state
      final list = subtasksMap[subtask.taskId];
      if (list != null) {
        final index = list.indexWhere((s) => s.id == subtask.id);
        if (index != -1) {
          list[index] = updated;
          subtasksMap[subtask.taskId] = List.from(list); // Trigger update
        }
      }
    } catch (e) {
      print('Error toggling subtask: $e');
    }
  }

  void filterTasks() {
    todayTasks.assignAll(_applyFilters(_originalTodayTasks));
    ongoingTasks.assignAll(_applyFilters(_originalOngoingTasks));
    upcomingTasks.assignAll(_applyFilters(_originalUpcomingTasks));
  }

  List<Task> _applyFilters(List<Task> tasks) {
    return tasks.where((task) {
      // 1. Search Text
      if (searchText.value.isNotEmpty) {
        final query = searchText.value.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDesc) return false;
      }

      // 2. Status
      if (filterStatus.value != null && task.status != filterStatus.value) {
        return false;
      }

      // 3. Priority
      if (filterPriority.value != null && task.priority != filterPriority.value) {
        return false;
      }

      // 4. Categories
      if (filterCategoryIds.isNotEmpty) {
        // If task has no category but we are filtering by category, exclude it?
        // Or strictly match. Assuming cached categories.
        if (task.categoryId == null || !filterCategoryIds.contains(task.categoryId)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setSearchText(String text) {
    searchText.value = text;
    filterTasks();
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchText.value = '';
      filterTasks();
    }
  }

  bool get hasActiveFilters =>
      filterStatus.value != null || filterPriority.value != null || filterCategoryIds.isNotEmpty;

  void setFilterStatus(TaskStatus? status) {
    filterStatus.value = status;
    filterTasks();
  }

  void setFilterPriority(TaskPriority? priority) {
    filterPriority.value = priority;
    filterTasks();
  }

  void toggleFilterCategory(String categoryId) {
    if (filterCategoryIds.contains(categoryId)) {
      filterCategoryIds.remove(categoryId);
    } else {
      filterCategoryIds.add(categoryId);
    }
    filterTasks();
  }

  void clearFilters() {
    searchText.value = '';
    filterStatus.value = null;
    filterPriority.value = null;
    filterCategoryIds.clear();
    filterTasks();
  }
}
