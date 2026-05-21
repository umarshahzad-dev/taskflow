import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

enum Priority {
  low(0, 'Low'),
  medium(1, 'Medium'),
  high(2, 'High');

  final int value;
  final String label;

  const Priority(this.value, this.label);

  static final Map<String, Priority> _lookup = Priority.values.asNameMap();

  static Priority fromString(String s) {
    return _lookup[s.toLowerCase()] ?? Priority.medium;
  }
}

@JsonSerializable()
class Task {
  final int id;
  final String title;
  final bool completed;
  final Priority priority;
  final DateTime createdAt;
  final DateTime? dueDate; // NEW
  final List<String> tags; // NEW

  const Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = Priority.medium,
    required this.createdAt,
    this.dueDate,
    this.tags = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  Task copyWith({
    int? id,
    String? title,
    bool? completed,
    Priority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && id == other.id && title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() => 'Task($id: "$title", ${completed ? "done" : "pending"})';
}
