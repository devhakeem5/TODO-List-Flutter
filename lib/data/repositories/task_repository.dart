import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/database/db_helper.dart';
import '../../core/services/notification_service.dart';
import '../models/task_model.dart';

class TaskRepository extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> create(Task task) async {
    final db = await _dbHelper.database;
    await db.insert(DbConstants.tableTasks, task.toMap());
    return task.id;
  }

  Future<Task?> read(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DbConstants.tableTasks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Task>> readAll() async {
    final db = await _dbHelper.database;
    final orderBy = '${DbConstants.colCreatedAt} DESC';
    final result = await db.query(DbConstants.tableTasks, orderBy: orderBy);

    return result.map((json) => Task.fromMap(json)).toList();
  }

  // 1. Get Tasks Linked to Specific Date (for Today)
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    // Query: Where (isDateBased = 1 AND dueDate BETWEEN start AND end)
    final result = await db.query(
      DbConstants.tableTasks,
      where: '${DbConstants.colIsDateBased} = 1 AND ${DbConstants.colDueDate} BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy:
          '${DbConstants.colPriority} ASC', // High priority (low index?) No, enum is low/med/high
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  // 2. Get Ongoing Tasks (Time Range)
  Future<List<Task>> getOngoingTasks(DateTime date) async {
    final db = await _dbHelper.database;
    final nowStr = date.toIso8601String();

    // Query: Where (startDate <= now) AND (now <= endDate)
    // Note: This assumes simplified logic. Real app might need more complex recurring logic.
    final result = await db.query(
      DbConstants.tableTasks,
      where: '${DbConstants.colStartDate} <= ? AND ${DbConstants.colEndDate} >= ?',
      whereArgs: [nowStr, nowStr],
      orderBy: '${DbConstants.colEndDate} ASC',
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  // 3. Get Upcoming Tasks (Next few days)
  Future<List<Task>> getUpcomingTasks(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final result = await db.query(
      DbConstants.tableTasks,
      where:
          '${DbConstants.colIsDateBased} = 1 AND ${DbConstants.colDueDate} > ? AND ${DbConstants.colDueDate} <= ?',
      whereArgs: [startStr, endStr],
      orderBy: '${DbConstants.colDueDate} ASC',
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbConstants.tableTasks,
      task.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _dbHelper.database;

    // Read task to check for notification
    final taskMap = await db.query(
      DbConstants.tableTasks,
      columns: [DbConstants.colNotificationId],
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );

    if (taskMap.isNotEmpty && taskMap.first[DbConstants.colNotificationId] != null) {
      try {
        final notifId = taskMap.first[DbConstants.colNotificationId] as int;
        // Ideally pass NotificationService here or Get.find
        // For simplicity reusing Get.find
        Get.find<NotificationService>().cancelNotification(notifId);
      } catch (e) {
        // Log error
      }
    }

    return await db.delete(
      DbConstants.tableTasks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
  // Stats Helpers

  Future<int> countCompleted(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    // Count tasks where isCompleted = 1 (completed status) AND date matches
    // Note: status is string 'completed'.
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${DbConstants.tableTasks} 
      WHERE ${DbConstants.colStatus} = 'completed' 
      AND (
        (${DbConstants.colIsDateBased} = 1 AND ${DbConstants.colDueDate} BETWEEN ? AND ?)
        OR
        (${DbConstants.colIsDateBased} = 0 AND ${DbConstants.colStartDate} <= ? AND ${DbConstants.colEndDate} >= ?)
      )
    ''',
      [startOfDay, endOfDay, date.toIso8601String(), date.toIso8601String()],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countCompletedRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${DbConstants.tableTasks} 
      WHERE ${DbConstants.colStatus} = 'completed' 
      AND ${DbConstants.colUpdatedAt} BETWEEN ? AND ?
    ''',
      [startStr, endStr],
    );
    // Note using UpdatedAt implies "completed within this window".
    // Using DueDate would mean "tasks due this week that are completed".
    // Let's stick to simple "Due in this range and are completed".
    /*
      AND ${DbConstants.colDueDate} BETWEEN ? AND ?
    */

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countOverdue() async {
    final db = await _dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${DbConstants.tableTasks} 
      WHERE ${DbConstants.colStatus} != 'completed' 
      AND ${DbConstants.colIsDateBased} = 1 
      AND ${DbConstants.colDueDate} < ?
    ''',
      [nowStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getTopCategory() async {
    final db = await _dbHelper.database;
    // Group by categoryId, count, order by count desc
    final result = await db.rawQuery('''
      SELECT ${DbConstants.colCategoryId}, COUNT(*) as count
      FROM ${DbConstants.tableTasks}
      WHERE ${DbConstants.colStatus} = 'completed' AND ${DbConstants.colCategoryId} IS NOT NULL
      GROUP BY ${DbConstants.colCategoryId}
      ORDER BY count DESC
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return {row[DbConstants.colCategoryId] as String: row['count'] as int};
    }
    return {};
  }

  Future<int> countInProgress() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableTasks} WHERE ${DbConstants.colStatus} = ?',
      [TaskStatus.inProgress.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countCompletedSubtasksRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${DbConstants.tableSubtasks} s
      INNER JOIN ${DbConstants.tableTasks} t ON s.${DbConstants.colTaskId} = t.${DbConstants.colId}
      WHERE t.${DbConstants.colStatus} = 'completed' 
      AND t.${DbConstants.colUpdatedAt} BETWEEN ? AND ?
    ''',
      [startStr, endStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAvailableTasks(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDayStr = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM ${DbConstants.tableTasks} 
      WHERE ${DbConstants.colTaskType} = 'timeRange' 
      AND ${DbConstants.colStatus} != 'completed'
      AND ${DbConstants.colStartDate} <= ? 
      AND ${DbConstants.colEndDate} >= ?
    ''',
      [endOfDayStr, dateStr],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> countRecurringStats(DateTime date) async {
    final tasks = await getRecurringTasksForDay(date);
    final now = DateTime.now();
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int completed = 0;
    int missed = 0;

    for (var task in tasks) {
      if (task.status == TaskStatus.completed) {
        completed++;
      } else {
        // Missed today: start time passed and NOT completed
        final startTimeStr = _timeToString(task.startTime);
        if (startTimeStr != null && startTimeStr.compareTo(currentTimeStr) < 0) {
          missed++;
        }
      }
    }

    return {'completed': completed, 'missed': missed, 'totalToday': tasks.length};
  }

  Future<int> countRecurringTasksForDay(DateTime date) async {
    final tasks = await getRecurringTasksForDay(date);
    return tasks.length;
  }

  Future<List<Task>> getRecurringTasksForDay(DateTime date) async {
    final db = await _dbHelper.database;
    final weekday = date.weekday % 7;

    // Fetch all recurring tasks and filter in Dart for JSON accuracy
    final result = await db.query(
      DbConstants.tableTasks,
      where: '${DbConstants.colTaskType} = ?',
      whereArgs: [TaskType.recurring.name],
    );

    return result.map((json) => Task.fromMap(json)).where((task) {
      if (task.recurrenceDays == null) return false;

      // Check recurrence days
      if (!task.recurrenceDays!.contains(weekday)) return false;

      // Check excluded days
      if (task.excludedDays != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        if (task.excludedDays!.contains(dateStr)) return false;
      }

      return true;
    }).toList();
  }

  static String? _timeToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
