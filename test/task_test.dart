import 'package:test/test.dart';
import 'package:taskflow/src/models/task.dart';

void main() {
  group('Task', () {
    late Task task;

    setUp(() {
      task = Task(
        id: 1,
        title: 'Test task',
        priority: Priority.high,
        createdAt: DateTime(2026, 5, 21, 12, 0),
        dueDate: DateTime(2026, 6, 1),
        tags: ['dart', 'cli'],
      );
    });

    test('should serialize to JSON and back', () {
      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, equals(1));
      expect(restored.title, equals('Test task'));
      expect(restored.completed, isFalse);
      expect(restored.priority, equals(Priority.high));
      expect(restored.dueDate, equals(DateTime(2026, 6, 1)));
      expect(restored.tags, equals(['dart', 'cli']));
    });

    test('copyWith should create modified copy', () {
      final completed = task.copyWith(completed: true);
      expect(completed.completed, isTrue);
      expect(completed.id, equals(task.id));
      expect(completed.title, equals(task.title));
    });

    test('copyWith should not modify original', () {
      final modified = task.copyWith(title: 'New title');
      expect(task.title, equals('Test task'));
      expect(modified.title, equals('New title'));
    });

    test('== should compare id and title', () {
      final same = Task(id: 1, title: 'Test task', createdAt: DateTime.now());
      final different = Task(
        id: 2,
        title: 'Test task',
        createdAt: DateTime.now(),
      );

      expect(task, equals(same));
      expect(task, isNot(equals(different)));
    });

    group('Priority enum', () {
      test('fromString should parse correctly', () {
        expect(Priority.fromString('high'), Priority.high);
        expect(Priority.fromString('medium'), Priority.medium);
        expect(Priority.fromString('low'), Priority.low);
        expect(Priority.fromString('invalid'), Priority.medium);
      });

      test('values should have correct labels', () {
        expect(Priority.high.label, 'High');
        expect(Priority.medium.label, 'Medium');
        expect(Priority.low.label, 'Low');
      });
    });
  });
}
