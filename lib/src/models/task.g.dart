// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  completed: json['completed'] as bool? ?? false,
  priority:
      $enumDecodeNullable(_$PriorityEnumMap, json['priority']) ??
      Priority.medium,
  createdAt: DateTime.parse(json['createdAt'] as String),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'completed': instance.completed,
  'priority': _$PriorityEnumMap[instance.priority]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'dueDate': instance.dueDate?.toIso8601String(),
  'tags': instance.tags,
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};
