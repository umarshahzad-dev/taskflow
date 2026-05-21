import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../models/task.dart';

class TaskRepository {
  final String filePath;
  final String configPath;
  List<Task> _tasks = [];
  Map<String, String> _config = {};

  TaskRepository(this.filePath, {this.configPath = 'config.json'});

  List<Task> get tasks => List.unmodifiable(_tasks);

  int get nextId => _tasks.isEmpty
      ? 1
      : _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;

  // ──────────────────────────────────────────────
  // CONFIG
  // ──────────────────────────────────────────────
  Future<Map<String, String>> loadConfig() async {
    final configFile = File(configPath);
    if (!await configFile.exists()) {
      _config = {};
      return {};
    }
    try {
      final contents = await configFile.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      _config = json.map((k, v) => MapEntry(k, v.toString()));
      return _config;
    } catch (e) {
      _config = {};
      return {};
    }
  }

  Future<void> setConfig(String key, String value) async {
    _config[key] = value;
    final configFile = File(configPath);
    await configFile.writeAsString(jsonEncode(_config));
  }

  String getConfig(String key, String fallback) {
    return _config[key] ?? fallback;
  }

  // ──────────────────────────────────────────────
  // PERSISTENCE
  // ──────────────────────────────────────────────
  Future<void> load() async {
    // Load config first
    await loadConfig();
    final file = File(filePath);
    if (!await file.exists()) {
      _tasks = [];
      return;
    }
    try {
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      _tasks = jsonList
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<void> save() async {
    final file = File(filePath);
    final jsonList = _tasks.map((task) => task.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  // ──────────────────────────────────────────────
  // CRUD
  // ──────────────────────────────────────────────
  Task add(
    String title,
    Priority priority, {
    DateTime? dueDate,
    List<String> tags = const [],
  }) {
    final task = Task(
      id: nextId,
      title: title,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      tags: tags,
    );
    _tasks.add(task);
    save();
    return task;
  }

  Task? completeTask(int id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    _tasks[index] = _tasks[index].copyWith(completed: true);
    save();
    return _tasks[index];
  }

  Task? uncompleteTask(int id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    _tasks[index] = _tasks[index].copyWith(completed: false);
    save();
    return _tasks[index];
  }

  bool deleteTask(int id) {
    final removed = _tasks.where((t) => t.id != id).toList();
    if (removed.length == _tasks.length) return false;
    _tasks = removed;
    save();
    return true;
  }

  void restoreTask(Task task) {
    _tasks.add(task);
    save();
  }

  // ──────────────────────────────────────────────
  // FILTERS & EXPORT
  // ──────────────────────────────────────────────
  List<Task> filter({bool? completed, Priority? priority}) {
    var result = _tasks;
    if (completed != null) {
      result = result.where((t) => t.completed == completed).toList();
    }
    if (priority != null) {
      result = result.where((t) => t.priority == priority).toList();
    }
    return result;
  }

  Future<String> exportToCsv() async {
    final data = _tasks.map((t) => t.toJson()).toList();
    return Isolate.run(() {
      final buffer = StringBuffer(
        'ID,Title,Completed,Priority,CreatedAt,DueDate,Tags\n',
      );
      for (final json in data) {
        final task = Task.fromJson(json);
        buffer.writeln(
          '${task.id},"${task.title}",${task.completed},${task.priority.name},'
          '${task.createdAt.toIso8601String()},'
          '${task.dueDate?.toIso8601String() ?? ""},'
          '"${task.tags.join("; ")}"',
        );
      }
      return buffer.toString();
    });
  }
}
