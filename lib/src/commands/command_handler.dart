import 'dart:io';

import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/task_logger.dart';
import '../utils/extensions.dart';

class CommandHandler {
  final TaskRepository repo;
  final TaskLogger logger;
  Task? _lastDeleted;

  CommandHandler(this.repo, this.logger);

  Future<String> handle(List<String> args) async {
    final command = args.isNotEmpty ? args[0] : 'help';

    return switch (command) {
      'add' => _handleAdd(args),
      'list' => _handleList(args),
      'done' => _handleDone(args),
      'undone' => _handleUndone(args),
      'delete' => _handleDelete(args),
      'undo' => _handleUndo(),
      'search' => _handleSearch(args),
      'stats' => _handleStats(),
      'export' => _handleExport(args),
      'config' => _handleConfig(args),
      'shell' => _handleShell(),
      'help' || '--help' => _showHelp(),
      _ => 'Unknown command. Run `taskflow help` for usage.',
    };
  }

  Future<String> _handleAdd(List<String> args) async {
    if (args.length < 2) {
      return 'Usage: add <title> [--priority low|medium|high] [--due YYYY-MM-DD] [--tags tag1,tag2]';
    }

    final title = args[1];
    Priority priority = Priority.medium;
    DateTime? dueDate;
    List<String> tags = [];

    for (int i = 2; i < args.length; i++) {
      if (args[i] == '--priority' && i + 1 < args.length) {
        priority = Priority.fromString(args[i + 1]);
      } else if (args[i] == '--due' && i + 1 < args.length) {
        dueDate = DateTime.tryParse(args[i + 1]);
      } else if (args[i] == '--tags' && i + 1 < args.length) {
        tags = args[i + 1].split(',').map((t) => t.trim()).toList();
      }
    }

    final task = repo.add(title, priority, dueDate: dueDate, tags: tags);
    logger.log('Task added: ${task.title}');

    String result = 'Added task #${task.id}: "$title" (${priority.label})';
    if (dueDate != null) result += ' due ${dueDate.formatted}';
    if (tags.isNotEmpty) result += ' tags: ${tags.join(", ")}';
    return result;
  }

  String _handleList(List<String> args) {
    final showDone = args.contains('--done');
    final showPending = args.contains('--pending');
    final showOverdue = args.contains('--overdue');
    Priority? filterPriority;
    String? filterTag;
    String? sortBy;

    for (int i = 1; i < args.length; i++) {
      if (args[i] == '--priority' && i + 1 < args.length) {
        filterPriority = Priority.fromString(args[i + 1]);
      } else if (args[i] == '--tag' && i + 1 < args.length) {
        filterTag = args[i + 1].toLowerCase();
      } else if (args[i] == '--sort' && i + 1 < args.length) {
        sortBy = args[i + 1].toLowerCase();
      }
    }

    bool? completed;
    if (showDone && !showPending) completed = true;
    if (showPending && !showDone) completed = false;

    var tasks = repo.filter(completed: completed, priority: filterPriority);

    // Tag filter
    if (filterTag != null) {
      tasks = tasks
          .where((t) => t.tags.any((tag) => tag.toLowerCase() == filterTag))
          .toList();
    }

    // Overdue filter
    if (showOverdue) {
      final now = DateTime.now();
      tasks = tasks
          .where(
            (t) =>
                t.dueDate != null && t.dueDate!.isBefore(now) && !t.completed,
          )
          .toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'priority':
        tasks.sort((a, b) => a.priority.value.compareTo(b.priority.value));
        break;
      case 'date':
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'title':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'id':
        tasks.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'due':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
    }

    if (tasks.isEmpty) return 'No tasks found.';

    return tasks
        .map((t) {
          String line =
              '#${t.id} [${t.completed ? "✓" : " "}] '
              '${_coloredPriority(t.priority)}${t.title}$_reset'
              ' (${t.priority.label})';
          if (t.dueDate != null) {
            line += ' due: ${t.dueDate!.formatted}';
            if (t.dueDate!.isBefore(DateTime.now()) && !t.completed) {
              line += ' ${_red}OVERDUE$_reset';
            }
          }
          if (t.tags.isNotEmpty) {
            line += ' tags: ${t.tags.join(", ")}';
          }
          line += ' — ${t.createdAt.formatted}';
          return line;
        })
        .join('\n');
  }

  Future<String> _handleDone(List<String> args) async {
    if (args.length < 2) return 'Usage: done <task-id>';
    final id = int.tryParse(args[1]);
    if (id == null) return 'Invalid task ID.';

    final task = repo.completeTask(id);
    if (task == null) return 'Task #$id not found.';

    logger.log('Task completed: ${task.title}');
    return 'Marked task #$id as done: "${task.title}"';
  }

  Future<String> _handleUndone(List<String> args) async {
    if (args.length < 2) return 'Usage: undone <task-id>';
    final id = int.tryParse(args[1]);
    if (id == null) return 'Invalid task ID.';

    final task = repo.uncompleteTask(id);
    if (task == null) return 'Task #$id not found.';

    logger.log('Task marked as pending: ${task.title}');
    return 'Marked task #$id as pending: "${task.title}"';
  }

    Future<String> _handleDelete(List<String> args) async {
    if (args.length < 2) return 'Usage: delete <task-id>';
    final id = int.tryParse(args[1]);
    if (id == null) return 'Invalid task ID.';

    // Find task before deleting
    final taskToDelete = repo.tasks.cast<Task?>().firstWhere(
      (t) => t!.id == id,
      orElse: () => null,
    );
    if (taskToDelete == null) return 'Task #$id not found.';

    _lastDeleted = taskToDelete;
    final deleted = repo.deleteTask(id);
    if (!deleted) return 'Task #$id not found.';

    logger.log('Task deleted: #$id');
    return 'Deleted task #$id. Use "undo" to restore.';
  }

  Future<String> _handleUndo() async {
    if (_lastDeleted == null) {
      return 'Nothing to undo.';
    }
    final task = _lastDeleted!;
    repo.restoreTask(task);
    _lastDeleted = null;
    logger.log('Task restored: ${task.title}');
    return 'Restored task #${task.id}: "${task.title}"';
  }

      String _handleSearch(List<String> args) {
    if (args.length < 2) return 'Usage: search <query>';

    var query = args.sublist(1).join(' ').toLowerCase().trim();

    if ((query.startsWith('"') && query.endsWith('"')) ||
        (query.startsWith("'") && query.endsWith("'"))) {
      query = query.substring(1, query.length - 1);
    }

    final results = repo.tasks
        .where((t) => t.title.toLowerCase().contains(query))
        .toList();

    if (results.isEmpty) return 'No tasks matching "$query".';

    return results
        .map(
          (t) =>
              '#${t.id} [${t.completed ? "✓" : " "}] ${t.title} '
              '(${t.priority.label}) — ${t.createdAt.formatted}',
        )
        .join('\n');
  }

  String _handleStats() {
    final total = repo.tasks.length;
    final completed = repo.tasks.where((t) => t.completed).length;
    final pending = total - completed;
    final overdue = repo.tasks
        .where(
          (t) =>
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()) &&
              !t.completed,
        )
        .length;
    final high = repo.tasks.where((t) => t.priority == Priority.high).length;
    final medium = repo.tasks
        .where((t) => t.priority == Priority.medium)
        .length;
    final low = repo.tasks.where((t) => t.priority == Priority.low).length;

    return '''
Task Statistics
===============
Total: $total
Completed: $completed
Pending: $pending
Overdue: $overdue

By Priority:
  High: $high
  Medium: $medium
  Low: $low
''';
  }

  Future<String> _handleExport(List<String> args) async {
    final csv = await repo.exportToCsv();
    final file = await _saveExportedFile(csv);
    return 'Exported tasks to ${file.path}';
  }

  Future<File> _saveExportedFile(String csv) async {
    final dir = Directory('exports');
    if (!await dir.exists()) await dir.create();
    final file = File(
      'exports/tasks_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);
    return file;
  }

  Future<String> _handleConfig(List<String> args) async {
    if (args.length < 2) {
      return 'Usage: config <key> [value]\nKeys: filepath, default_priority';
    }

    final key = args[1];
    if (args.length == 2) {
      // Get config value
      final config = await repo.loadConfig();
      return switch (key) {
        'filepath' =>
          'Current data file: ${config['filepath'] ?? 'tasks.json'}',
        'default_priority' =>
          'Default priority: ${config['default_priority'] ?? 'medium'}',
        _ => 'Unknown config key. Use: filepath, default_priority',
      };
    } else {
      // Set config value
      final value = args[2];
      await repo.setConfig(key, value);
      return 'Config $key set to $value';
    }
  }

  Future<String> _handleShell() async {
    // ignore: avoid_print
    print('Entering interactive mode. Type "quit" to exit.');
    while (true) {
      stdout.write('taskflow> ');
      final input = stdin.readLineSync();
      if (input == null || input.trim().toLowerCase() == 'quit') {
        return 'Goodbye!';
      }
      final args = input.trim().split(' ');
      final result = await handle(args);
      // ignore: avoid_print
      print(result);
    }
  }

  String _showHelp() {
    return '''
TaskFlow CLI - Task Manager

Usage: dart run bin/taskflow.dart <command> [options]

Commands:
  add <title> [--priority low|medium|high] [--due YYYY-MM-DD] [--tags tag1,tag2]  Add a new task
  list [--done] [--pending] [--overdue] [--priority <p>] [--tag <t>] [--sort id|title|priority|date|due]  List tasks
  done <task-id>                               Mark a task as completed
  undone <task-id>                             Mark a task as pending
  delete <task-id>                             Delete a task
  undo                                         Restore last deleted task
  search <query>                               Search tasks by title
  stats                                        Show task statistics
  export                                       Export tasks to CSV
  config <key> [value]                         View or set config (filepath, default_priority)
  shell                                        Enter interactive mode
  help                                         Show this help
''';
  }

  // ANSI color helpers
  String _coloredPriority(Priority p) => switch (p) {
    Priority.high => '\x1B[31m', // red
    Priority.medium => '\x1B[33m', // yellow
    Priority.low => '\x1B[32m', // green
  };

  String get _reset => '\x1B[0m';
  String get _red => '\x1B[31m';
}
