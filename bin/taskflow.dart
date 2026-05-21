import 'dart:io';

import 'package:taskflow/src/commands/command_handler.dart';
import 'package:taskflow/src/services/task_repository.dart';
import 'package:taskflow/src/services/task_logger.dart';

void main(List<String> arguments) async {
  // Setup services
  final repo = TaskRepository('tasks.json');
  final logger = TaskLogger();

  // Listen to log stream (prints real-time events)
  logger.stream.listen((message) {
    // ignore: avoid_print
    print(message);
  });

  // Load existing tasks from file
  try {
    await repo.load();
  } catch (e) {
    print('Error loading tasks: $e');
    exit(1);
  }

  // Handle the command
  final handler = CommandHandler(repo, logger);
  final result = await handler.handle(arguments);
  print(result);

  // Cleanup
  logger.dispose();
}
