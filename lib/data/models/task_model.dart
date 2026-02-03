import 'dart:convert';

import 'package:flutter/material.dart';

import '/core/constants/db_constants.dart';
import '/core/constants/enums.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskType taskType;
  final bool isDateBased;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final String? recurrenceRule;
  final List<int>? recurrenceDays; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final List<String>? excludedDays; // ISO date strings
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ReminderLevel? reminderLevel; // Null = use global setting
  final bool reminderEnabled;
  final DateTime? reminderDateTime;
  final int? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.taskType = TaskType.open,
    this.isDateBased = false,
    this.dueDate,
    this.startDate,
    this.endDate,
    this.isRecurring = false,
    this.recurrenceRule,
    this.recurrenceDays,
    this.excludedDays,
    this.startTime,
    this.endTime,
    this.reminderLevel,
    this.reminderEnabled = true,
    this.reminderDateTime,
    this.notificationId,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    TaskPriority? priority,
    TaskStatus? status,
    TaskType? taskType,
    bool? isDateBased,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRecurring,
    String? recurrenceRule,
    List<int>? recurrenceDays,
    List<String>? excludedDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ReminderLevel? reminderLevel,
    bool? reminderEnabled,
    DateTime? reminderDateTime,
    int? notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      taskType: taskType ?? this.taskType,
      isDateBased: isDateBased ?? this.isDateBased,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      excludedDays: excludedDays ?? this.excludedDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reminderLevel: reminderLevel ?? this.reminderLevel,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper to convert TimeOfDay to HH:mm string
  static String? _timeToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Helper to parse HH:mm string to TimeOfDay
  static TimeOfDay? _stringToTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colTitle: title,
      DbConstants.colDescription: description,
      DbConstants.colCategoryId: categoryId,
      DbConstants.colPriority: priority.toStringValue(),
      DbConstants.colStatus: status.toStringValue(),
      DbConstants.colTaskType: taskType.toStringValue(),
      DbConstants.colIsDateBased: isDateBased ? 1 : 0,
      DbConstants.colDueDate: dueDate?.toIso8601String(),
      DbConstants.colStartDate: startDate?.toIso8601String(),
      DbConstants.colEndDate: endDate?.toIso8601String(),
      DbConstants.colIsRecurring: isRecurring ? 1 : 0,
      DbConstants.colRecurrenceRule: recurrenceRule,
      DbConstants.colRecurrenceDays: recurrenceDays != null ? jsonEncode(recurrenceDays) : null,
      DbConstants.colExcludedDays: excludedDays != null ? jsonEncode(excludedDays) : null,
      DbConstants.colStartTime: _timeToString(startTime),
      DbConstants.colEndTime: _timeToString(endTime),
      DbConstants.colReminderLevel: reminderLevel?.toStringValue(),
      DbConstants.colReminderEnabled: reminderEnabled ? 1 : 0,
      DbConstants.colReminderDateTime: reminderDateTime?.toIso8601String(),
      DbConstants.colNotificationId: notificationId,
      DbConstants.colCreatedAt: createdAt.toIso8601String(),
      DbConstants.colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Parse recurrenceDays from JSON
    List<int>? parsedRecurrenceDays;
    if (map[DbConstants.colRecurrenceDays] != null) {
      final decoded = jsonDecode(map[DbConstants.colRecurrenceDays]);
      parsedRecurrenceDays = (decoded as List).cast<int>();
    }

    // Parse excludedDays from JSON
    List<String>? parsedExcludedDays;
    if (map[DbConstants.colExcludedDays] != null) {
      final decoded = jsonDecode(map[DbConstants.colExcludedDays]);
      parsedExcludedDays = (decoded as List).cast<String>();
    }

    return Task(
      id: map[DbConstants.colId],
      title: map[DbConstants.colTitle],
      description: map[DbConstants.colDescription],
      categoryId: map[DbConstants.colCategoryId],
      priority: TaskPriority.fromString(map[DbConstants.colPriority]),
      status: TaskStatus.fromString(map[DbConstants.colStatus]),
      taskType: TaskType.fromString(map[DbConstants.colTaskType]),
      isDateBased: map[DbConstants.colIsDateBased] == 1,
      dueDate: map[DbConstants.colDueDate] != null
          ? DateTime.parse(map[DbConstants.colDueDate])
          : null,
      startDate: map[DbConstants.colStartDate] != null
          ? DateTime.parse(map[DbConstants.colStartDate])
          : null,
      endDate: map[DbConstants.colEndDate] != null
          ? DateTime.parse(map[DbConstants.colEndDate])
          : null,
      isRecurring: map[DbConstants.colIsRecurring] == 1,
      recurrenceRule: map[DbConstants.colRecurrenceRule],
      recurrenceDays: parsedRecurrenceDays,
      excludedDays: parsedExcludedDays,
      startTime: _stringToTime(map[DbConstants.colStartTime]),
      endTime: _stringToTime(map[DbConstants.colEndTime]),
      reminderLevel: map[DbConstants.colReminderLevel] != null
          ? ReminderLevel.fromString(map[DbConstants.colReminderLevel])
          : null,
      reminderEnabled: map[DbConstants.colReminderEnabled] == 1,
      reminderDateTime: map[DbConstants.colReminderDateTime] != null
          ? DateTime.parse(map[DbConstants.colReminderDateTime])
          : null,
      notificationId: map[DbConstants.colNotificationId],
      createdAt: DateTime.parse(map[DbConstants.colCreatedAt]),
      updatedAt: DateTime.parse(map[DbConstants.colUpdatedAt]),
    );
  }
}
