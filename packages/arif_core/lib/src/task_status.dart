/// aria2 download status values from tellStatus / tell*.
enum TaskStatus {
  active,
  waiting,
  paused,
  error,
  complete,
  removed,
  unknown,
}

TaskStatus parseTaskStatus(String? raw) {
  switch (raw) {
    case 'active':
      return TaskStatus.active;
    case 'waiting':
      return TaskStatus.waiting;
    case 'paused':
      return TaskStatus.paused;
    case 'error':
      return TaskStatus.error;
    case 'complete':
      return TaskStatus.complete;
    case 'removed':
      return TaskStatus.removed;
    default:
      return TaskStatus.unknown;
  }
}

extension TaskStatusX on TaskStatus {
  String get wireName => switch (this) {
        TaskStatus.active => 'active',
        TaskStatus.waiting => 'waiting',
        TaskStatus.paused => 'paused',
        TaskStatus.error => 'error',
        TaskStatus.complete => 'complete',
        TaskStatus.removed => 'removed',
        TaskStatus.unknown => 'unknown',
      };

  bool get isRunning => this == TaskStatus.active;

  bool get canPause =>
      this == TaskStatus.active || this == TaskStatus.waiting;

  bool get canResume => this == TaskStatus.paused;

  bool get isTerminal =>
      this == TaskStatus.complete ||
      this == TaskStatus.error ||
      this == TaskStatus.removed;

  /// AriaNg-style bucket for list tabs.
  TaskBucket get bucket => switch (this) {
        TaskStatus.active => TaskBucket.active,
        TaskStatus.waiting || TaskStatus.paused => TaskBucket.waiting,
        TaskStatus.complete ||
        TaskStatus.error ||
        TaskStatus.removed =>
          TaskBucket.stopped,
        TaskStatus.unknown => TaskBucket.stopped,
      };
}

/// High-level list buckets used by the task shell.
enum TaskBucket {
  active,
  waiting,
  stopped,
}
