import 'dart:async';

import 'package:taskflow/src/utils/extensions.dart';

class TaskLogger {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void log(String message) {
    final timestamp = DateTime.now().formatted;
    if (!_controller.isClosed) {
      _controller.add('[$timestamp] $message');
    }
  }

  void dispose() => _controller.close();
}
