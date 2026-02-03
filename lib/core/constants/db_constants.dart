class DbConstants {
  static const String databaseName = 'todo_app.db';
  static const int databaseVersion = 3; // Updated to fix missing columns and tables

  // Tables
  static const String tableTasks = 'tasks';
  static const String tableCategories = 'categories';
  static const String tableSubtasks = 'subtasks';

  // Common Columns
  static const String colId = 'id';
  static const String colCreatedAt = 'createdAt';
  static const String colUpdatedAt = 'updatedAt';

  // Task Columns
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colCategoryId = 'categoryId';
  static const String colPriority = 'priority';
  static const String colStatus = 'status';
  static const String colIsDateBased = 'isDateBased';
  static const String colDueDate = 'dueDate';
  static const String colStartDate = 'startDate';
  static const String colEndDate = 'endDate';
  static const String colIsRecurring = 'isRecurring';
  static const String colRecurrenceRule = 'recurrenceRule';
  static const String colReminderDateTime = 'reminderDateTime';
  static const String colNotificationId = 'notificationId';

  // New Task Columns (v2)
  static const String colTaskType = 'taskType';
  static const String colRecurrenceDays = 'recurrenceDays'; // JSON array [0-6]
  static const String colExcludedDays = 'excludedDays'; // JSON array of ISO dates
  static const String colReminderLevel = 'reminderLevel';
  static const String colStartTime = 'startTime'; // HH:mm format
  static const String colEndTime = 'endTime'; // HH:mm format
  static const String colReminderEnabled = 'reminderEnabled';

  // Category Columns
  static const String colName = 'name';
  static const String colColor = 'color';
  static const String colIsActive = 'isActive';

  // Subtask Columns
  static const String colTaskId = 'taskId';
  static const String colIsCompleted = 'isCompleted';
}
