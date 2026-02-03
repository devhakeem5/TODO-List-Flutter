import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/db_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DbConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Categories Table
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        ${DbConstants.colId} TEXT PRIMARY KEY,
        ${DbConstants.colName} TEXT NOT NULL,
        ${DbConstants.colColor} INTEGER NOT NULL,
        ${DbConstants.colIsActive} INTEGER NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create Tasks Table (v2 schema)
    await db.execute('''
      CREATE TABLE ${DbConstants.tableTasks} (
        ${DbConstants.colId} TEXT PRIMARY KEY,
        ${DbConstants.colTitle} TEXT NOT NULL,
        ${DbConstants.colDescription} TEXT,
        ${DbConstants.colCategoryId} TEXT,
        ${DbConstants.colPriority} TEXT NOT NULL,
        ${DbConstants.colStatus} TEXT NOT NULL,
        ${DbConstants.colTaskType} TEXT NOT NULL DEFAULT 'open',
        ${DbConstants.colIsDateBased} INTEGER NOT NULL,
        ${DbConstants.colDueDate} TEXT,
        ${DbConstants.colStartDate} TEXT,
        ${DbConstants.colEndDate} TEXT,
        ${DbConstants.colIsRecurring} INTEGER NOT NULL,
        ${DbConstants.colRecurrenceRule} TEXT,
        ${DbConstants.colRecurrenceDays} TEXT,
        ${DbConstants.colExcludedDays} TEXT,
        ${DbConstants.colStartTime} TEXT,
        ${DbConstants.colEndTime} TEXT,
        ${DbConstants.colReminderLevel} TEXT,
        ${DbConstants.colReminderEnabled} INTEGER NOT NULL DEFAULT 1,
        ${DbConstants.colReminderDateTime} TEXT,
        ${DbConstants.colNotificationId} INTEGER,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colCategoryId}) REFERENCES ${DbConstants.tableCategories} (${DbConstants.colId}) ON DELETE SET NULL
      )
    ''');

    // Create Subtasks Table
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSubtasks} (
        ${DbConstants.colId} TEXT PRIMARY KEY,
        ${DbConstants.colTaskId} TEXT NOT NULL,
        ${DbConstants.colTitle} TEXT NOT NULL,
        ${DbConstants.colIsCompleted} INTEGER NOT NULL,
        FOREIGN KEY (${DbConstants.colTaskId}) REFERENCES ${DbConstants.tableTasks} (${DbConstants.colId}) ON DELETE CASCADE
      )
    ''');
  }

  /// Migration handling
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // List of columns that might be missing from v1 or incomplete v2 upgrade
      final List<String> columnsToFix = [
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colTaskType} TEXT NOT NULL DEFAULT 'open'",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colRecurrenceDays} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colExcludedDays} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colStartTime} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colEndTime} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colReminderLevel} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colReminderEnabled} INTEGER NOT NULL DEFAULT 1",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colReminderDateTime} TEXT",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colNotificationId} INTEGER",
        "ALTER TABLE ${DbConstants.tableTasks} ADD COLUMN ${DbConstants.colRecurrenceRule} TEXT",
      ];

      for (var sql in columnsToFix) {
        try {
          await db.execute(sql);
        } catch (e) {
          // Ignore error if column already exists
          print('Database Migration Note: ${e.toString()}');
        }
      }

      // Ensure Subtasks Table exists (might be missing if upgraded from v1)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DbConstants.tableSubtasks} (
          ${DbConstants.colId} TEXT PRIMARY KEY,
          ${DbConstants.colTaskId} TEXT NOT NULL,
          ${DbConstants.colTitle} TEXT NOT NULL,
          ${DbConstants.colIsCompleted} INTEGER NOT NULL,
          FOREIGN KEY (${DbConstants.colTaskId}) REFERENCES ${DbConstants.tableTasks} (${DbConstants.colId}) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
