import 'task_status.dart';

/// Task list segment matching AriaNg-style tabs.
enum TaskFilter {
  all,
  active,
  waiting,
  stopped,
}

extension TaskFilterX on TaskFilter {
  bool matchesStatus(TaskStatus status) {
    switch (this) {
      case TaskFilter.all:
        return true;
      case TaskFilter.active:
        return status.bucket == TaskBucket.active;
      case TaskFilter.waiting:
        return status.bucket == TaskBucket.waiting;
      case TaskFilter.stopped:
        return status.bucket == TaskBucket.stopped;
    }
  }

  bool matchesWireStatus(String? status) =>
      matchesStatus(parseTaskStatus(status));
}
