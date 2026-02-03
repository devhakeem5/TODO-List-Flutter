enum TaskPriority {
  low,
  medium,
  high;

  String toStringValue() => name; // e.g., "low"

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.medium, // Default fallback
    );
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  overdue;

  String toStringValue() => name;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere((e) => e.name == value, orElse: () => TaskStatus.pending);
  }
}

/// نوع المهمة من حيث التوقيت
enum TaskType {
  open, // مهمة مفتوحة بدون تاريخ انتهاء
  defaultDay, // مهمة ليوم واحد محدد
  recurring, // مهمة متكررة حسب أيام الأسبوع
  timeRange; // مهمة بفترة زمنية (من - إلى)

  String toStringValue() => name;

  static TaskType fromString(String? value) {
    if (value == null) return TaskType.open;
    return TaskType.values.firstWhere((e) => e.name == value, orElse: () => TaskType.open);
  }

  String get arabicLabel {
    switch (this) {
      case TaskType.open:
        return 'مفتوحة';
      case TaskType.defaultDay:
        return 'افتراضي';
      case TaskType.recurring:
        return 'متكررة';
      case TaskType.timeRange:
        return 'فترة زمنية';
    }
  }
}

/// مستوى التذكير
enum ReminderLevel {
  low, // قليل - تذكير واحد
  medium, // متوسط - 2-3 تذكيرات
  high; // كثير - 4+ تذكيرات

  String toStringValue() => name;

  static ReminderLevel fromString(String? value) {
    if (value == null) return ReminderLevel.medium;
    return ReminderLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderLevel.medium,
    );
  }

  String get arabicLabel {
    switch (this) {
      case ReminderLevel.low:
        return 'قليل';
      case ReminderLevel.medium:
        return 'متوسط';
      case ReminderLevel.high:
        return 'كثير';
    }
  }

  /// عدد التذكيرات بناءً على المستوى
  int get notificationCount {
    switch (this) {
      case ReminderLevel.low:
        return 1;
      case ReminderLevel.medium:
        return 3;
      case ReminderLevel.high:
        return 5;
    }
  }
}
