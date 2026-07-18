// aria2 任务状态与列表分桶。
// wire 状态见 TaskStatus；UI 分栏用 TaskBucket（AriaNg：paused→waiting）。

/// aria2 `status` 字段的枚举（tellActive / tellWaiting / tellStopped / tellStatus）。
enum TaskStatus {
  /// 正在传输。
  active,

  /// 队列中等待（未暂停）。
  waiting,

  /// 用户暂停；在 RPC 列表里通常出现在 tellWaiting。
  paused,

  /// 失败结束。
  error,

  /// 成功完成。
  complete,

  /// 已从队列移除。
  removed,

  /// 无法识别的状态字符串。
  unknown,
}

/// 把 RPC 返回的 status 字符串解析为 [TaskStatus]。
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
  /// 写回 aria2 时使用的字符串。
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

  /// 是否允许调用 pause（进行中或排队中）。
  bool get canPause =>
      this == TaskStatus.active || this == TaskStatus.waiting;

  /// 是否允许 unpause（仅 paused）。
  bool get canResume => this == TaskStatus.paused;

  /// 是否已结束（完成/失败/移除），一般走 removeDownloadResult。
  bool get isTerminal =>
      this == TaskStatus.complete ||
      this == TaskStatus.error ||
      this == TaskStatus.removed;

  /// 映射到 UI 三个主 Tab 的分桶（AriaNg 风格）。
  TaskBucket get bucket => switch (this) {
        TaskStatus.active => TaskBucket.active,
        // paused 与 waiting 都在「等待」Tab 展示
        TaskStatus.waiting || TaskStatus.paused => TaskBucket.waiting,
        TaskStatus.complete ||
        TaskStatus.error ||
        TaskStatus.removed =>
          TaskBucket.stopped,
        TaskStatus.unknown => TaskBucket.stopped,
      };
}

/// 任务列表高阶分桶（对应 Home 页 SegmentedButton）。
enum TaskBucket {
  active,
  waiting,
  stopped,
}
