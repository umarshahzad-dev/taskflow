import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:taskflow/src/models/task.dart';
import 'package:taskflow/src/services/task_repository.dart';

void main() {
  group('TaskRepository', () {
    late TaskRepository repo;
    late String testFile;

      setUp(() async {
      final random = Random().nextInt(999999);
      testFile = 'test_tasks_$random.json';
      repo = TaskRepository(testFile);
      await repo.load();
    });

    tearDown(() async {
      // Wait a tiny bit to ensure any pending writes finish
      await Future.delayed(Duration(milliseconds: 50));
      final file = File(testFile);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // File might be locked by another process; ignore
        }
      }
    });

    // Helper to wait for disk writes to settle (because save() is fire-and-forget)
    Future<void> settle() async {
      await Future.delayed(Duration(milliseconds: 100));
    }

    test('should start with empty tasks', () {
      expect(repo.tasks, isEmpty);
    });

    test('nextId should be 1 when empty', () {
      expect(repo.nextId, equals(1));
    });

    test('add should create task and persist', () async {
      final task = repo.add('Buy milk', Priority.medium);
      expect(task.id, equals(1));
      expect(task.title, 'Buy milk');
      expect(task.completed, isFalse);
      expect(task.priority, Priority.medium);

      await settle(); // wait for save

      final newRepo = TaskRepository(testFile);
      await newRepo.load();
      expect(newRepo.tasks.length, 1);
      expect(newRepo.tasks.first.title, 'Buy milk');
    });

    test('add with due date and tags', () async {
      final dueDate = DateTime(2026, 12, 31);
      final task = repo.add(
        'Project',
        Priority.high,
        dueDate: dueDate,
        tags: ['work', 'urgent'],
      );

      expect(task.dueDate, equals(dueDate));
      expect(task.tags, equals(['work', 'urgent']));
    });

    test('completeTask should mark as done', () async {
      repo.add('Task 1', Priority.low);
      final task = repo.add('Task 2', Priority.high);

      await settle();

      final completed = repo.completeTask(task.id);
      expect(completed, isNotNull);
      expect(completed!.completed, isTrue);

      await settle();

      final newRepo = TaskRepository(testFile);
      await newRepo.load();
      final found = newRepo.tasks.firstWhere((t) => t.id == task.id);
      expect(found.completed, isTrue);
    });

    test('completeTask should return null for missing id', () {
      final result = repo.completeTask(999);
      expect(result, isNull);
    });

    test('uncompleteTask should mark as pending', () async {
      final task = repo.add('Done task', Priority.medium);
      await settle();
      repo.completeTask(task.id);
      await settle();

      final undone = repo.uncompleteTask(task.id);
      expect(undone, isNotNull);
      expect(undone!.completed, isFalse);
    });

    test('deleteTask should remove task', () async {
      repo.add('Task A', Priority.low);
      final task = repo.add('Task B', Priority.high);

      await settle();

      final deleted = repo.deleteTask(task.id);
      expect(deleted, isTrue);

      await settle();

      final newRepo = TaskRepository(testFile);
      await newRepo.load();
      expect(newRepo.tasks.length, 1);
      expect(newRepo.tasks.first.title, 'Task A');
    });

    test('deleteTask should return false for missing id', () {
      final result = repo.deleteTask(999);
      expect(result, isFalse);
    });

    test('restoreTask should add back deleted task', () async {
      final task = repo.add('To Delete', Priority.medium);
      await settle();
      repo.deleteTask(task.id);
      await settle();

      repo.restoreTask(task);
      await settle();

      expect(repo.tasks.length, 1);
      expect(repo.tasks.first.id, equals(task.id));
    });

    test('filter should filter by completion status', () async {
      repo.add('Pending 1', Priority.low);
      final done = repo.add('Done 1', Priority.high);
      repo.completeTask(done.id);

      await settle();

      final pending = repo.filter(completed: false);
      expect(pending.length, 1);
      expect(pending.first.title, 'Pending 1');

      final completed = repo.filter(completed: true);
      expect(completed.length, 1);
      expect(completed.first.title, 'Done 1');
    });

    test('filter should filter by priority', () async {
      repo.add('Low task', Priority.low);
      repo.add('High task', Priority.high);

      await settle();

      final highTasks = repo.filter(priority: Priority.high);
      expect(highTasks.length, 1);
      expect(highTasks.first.title, 'High task');
    });

    test('filter should combine both filters', () async {
      final highDone = repo.add('High Done', Priority.high);
      repo.completeTask(highDone.id);
      repo.add('High Pending', Priority.high);
      repo.add('Low Pending', Priority.low);

      await settle();

      final result = repo.filter(completed: true, priority: Priority.high);
      expect(result.length, 1);
      expect(result.first.title, 'High Done');
    });

    test('exportToCsv should produce CSV string', () async {
      repo.add('CSV Task', Priority.medium);
      await settle();

      final csv = await repo.exportToCsv();
      expect(csv, contains('ID,Title,Completed,Priority,CreatedAt'));
      expect(csv, contains('CSV Task'));
      expect(csv, contains('medium'));
    });

        group('Config', () {
      late String configFile;

      setUp(() async {
        configFile = 'test_config_${Random().nextInt(999999)}.json';
        repo = TaskRepository(testFile, configPath: configFile);
        await repo.load();
        await repo.loadConfig();
      });

      tearDown(() async {
        await Future.delayed(Duration(milliseconds: 50));
        final file = File(configFile);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      });

      test('loadConfig should return empty map if no file', () async {
        // Fresh repo with no config file yet
        final config = await repo.loadConfig();
        expect(config, isEmpty);
      });

      test('setConfig and getConfig should work', () async {
        await repo.setConfig('test_key', 'test_value');
        final value = repo.getConfig('test_key', 'fallback');
        expect(value, 'test_value');
      });

      test('getConfig should return fallback for missing key', () {
        final value = repo.getConfig('nonexistent', 'fallback');
        expect(value, 'fallback');
      });
    });
  });
}
