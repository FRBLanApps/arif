import 'task_status.dart';

/// 任务列表 Tab 筛选（与 [TaskBucket] 对应，多一个「全部」）。
enum TaskFilter {
  all,
  active,
  waiting,
  stopped,
}

extension TaskFilterX on TaskFilter {
  /// 判断某个 [TaskStatus] 是否属于当前 Tab。
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

  /// 直接对 RPC 的 status 字符串做筛选。
  bool matchesWireStatus(String? status) =>
      matchesStatus(parseTaskStatus(status));
}
